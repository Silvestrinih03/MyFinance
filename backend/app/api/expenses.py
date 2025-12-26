from datetime import date
from fastapi import APIRouter, HTTPException, Depends, Query
from sqlalchemy.orm import Session

from app.database import SessionLocal
from app.models.expense import Expense
from app.schemas.expense import ExpenseCreate, ExpenseResponse
from app.api.ler_token import get_current_user

router = APIRouter(prefix="/expenses", tags=["Expenses"])


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.post("/", response_model=ExpenseResponse)
def create_expense(
    data: ExpenseCreate,
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    expense = Expense(
        user_id=current_user.id,
        description=data.description,
        amount=data.amount,
        due_date=data.due_date,
        is_recurring=data.is_recurring,
        recurrence_end_date=data.recurrence_end_date
    )

    db.add(expense)
    db.commit()
    db.refresh(expense)

    return expense

@router.get("/total")
def get_total_expenses(
    month: int = Query(..., ge=1, le=12),
    year: int = Query(..., ge=1900),
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    target_date = date(year, month, 1)

    expenses = db.query(Expense).filter(
        Expense.user_id == current_user.id
    ).all()

    total = 0

    for e in expenses:
        base_date = e.due_date.replace(day=1)
        end_date = (
            e.recurrence_end_date.replace(day=1)
            if e.recurrence_end_date
            else None
        )

        if not e.is_recurring:
            if base_date == target_date:
                total += e.amount
        else:
            if target_date >= base_date and (
                end_date is None or target_date <= end_date
            ):
                total += e.amount

    return {
        "user_id": current_user.id,
        "month": month,
        "year": year,
        "total": total
    }

@router.get("/", response_model=list[ExpenseResponse])
def list_expenses(
    month: int,
    year: int,
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    target_date = date(year, month, 1)
    expenses = db.query(Expense).filter(
        Expense.user_id == current_user.id
    ).all()

    result = []

    for e in expenses:
        base_date = e.due_date.replace(day=1)
        end_date = (
            e.recurrence_end_date.replace(day=1)
            if e.recurrence_end_date
            else None
        )

        if not e.is_recurring and base_date == target_date:
            result.append(e)
        elif e.is_recurring and (
            target_date >= base_date and (
                end_date is None or target_date <= end_date
            )
        ):
            result.append(e)

    return result

@router.delete("/{expense_id}")
def delete_expense(
    expense_id: int,
    user_id: int,
    db: Session = Depends(get_db)
):
    expense = db.query(Expense).filter(
        Expense.id == expense_id,
        Expense.user_id == user_id
    ).first()

    if not expense:
        raise HTTPException(status_code=404, detail="Expense not found")

    db.delete(expense)
    db.commit()

    return {"message": "Expense deleted successfully"}

@router.put("/{expense_id}", response_model=ExpenseResponse)
def update_expense(
    expense_id: int,
    data: ExpenseCreate,
    user_id: int,
    db: Session = Depends(get_db)
):
    expense = db.query(Expense).filter(
        Expense.id == expense_id,
        Expense.user_id == user_id
    ).first()

    if not expense:
        raise HTTPException(status_code=404, detail="Expense not found")

    expense.description = data.description
    expense.amount = data.amount
    expense.due_date = data.due_date
    expense.is_recurring = data.is_recurring
    expense.recurrence_end_date = data.recurrence_end_date

    db.commit()
    db.refresh(expense)

    return expense
