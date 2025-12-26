from datetime import date
from fastapi import APIRouter, HTTPException, Depends, Query
from sqlalchemy.orm import Session

from app.database import SessionLocal
from app.models.income import Income
from app.schemas.income import IncomeCreate, IncomeResponse
from app.api.ler_token import get_current_user

router = APIRouter(prefix="/incomes", tags=["Incomes"])


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.post("/", response_model=IncomeResponse)
def create_income(
    data: IncomeCreate,
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    income = Income(
        user_id=current_user.id,
        description=data.description,
        amount=data.amount,
        received_date=data.received_date,
        is_recurring=data.is_recurring,
        recurrence_end_date=data.recurrence_end_date
    )

    db.add(income)
    db.commit()
    db.refresh(income)

    return income

@router.get("/total")
def get_total_incomes(
    month: int = Query(..., ge=1, le=12),
    year: int = Query(..., ge=1900),
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    target_date = date(year, month, 1)

    incomes = db.query(Income).filter(
        Income.user_id == current_user.id
    ).all()

    total = 0

    for i in incomes:
        base_date = i.received_date.replace(day=1)
        end_date = (
            i.recurrence_end_date.replace(day=1)
            if i.recurrence_end_date
            else None
        )

        if not i.is_recurring:
            if base_date == target_date:
                total += i.amount
        else:
            if target_date >= base_date and (
                end_date is None or target_date <= end_date
            ):
                total += i.amount

    return {
        "user_id": current_user.id,
        "month": month,
        "year": year,
        "total": total
    }

@router.get("/", response_model=list[IncomeResponse])
def list_incomes(
    month: int,
    year: int,
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    target_date = date(year, month, 1)
    incomes = db.query(Income).filter(
        Income.user_id == current_user.id
    ).all()

    result = []

    for i in incomes:
        base_date = i.received_date.replace(day=1)
        end_date = (
            i.recurrence_end_date.replace(day=1)
            if i.recurrence_end_date
            else None
        )

        if not i.is_recurring and base_date == target_date:
            result.append(i)
        elif i.is_recurring and (
            target_date >= base_date and (
                end_date is None or target_date <= end_date
            )
        ):
            result.append(i)

    return result

@router.delete("/{income_id}")
def delete_income(
    income_id: int,
    user_id: int,
    db: Session = Depends(get_db)
):
    income = db.query(Income).filter(
        Income.id == income_id,
        Income.user_id == user_id
    ).first()

    if not income:
        raise HTTPException(status_code=404, detail="Income not found")

    db.delete(income)
    db.commit()

    return {"message": "Income deleted successfully"}

@router.put("/{income_id}", response_model=IncomeResponse)
def update_income(
    income_id: int,
    data: IncomeCreate,
    user_id: int,
    db: Session = Depends(get_db)
):
    income = db.query(Income).filter(
        Income.id == income_id,
        Income.user_id == user_id
    ).first()

    if not income:
        raise HTTPException(status_code=404, detail="Income not found")

    income.description = data.description
    income.amount = data.amount
    income.received_date = data.received_date
    income.is_recurring = data.is_recurring
    income.recurrence_end_date = data.recurrence_end_date

    db.commit()
    db.refresh(income)

    return income