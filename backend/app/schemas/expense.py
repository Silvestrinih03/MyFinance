from pydantic import BaseModel
from datetime import date, datetime
from decimal import Decimal


class ExpenseBase(BaseModel):
    description: str
    amount: Decimal
    due_date: date
    is_recurring: bool = False
    recurrence_end_date: date | None = None


class ExpenseCreate(ExpenseBase):
    pass


class ExpenseResponse(ExpenseBase):
    id: int
    user_id: int
    created_at: datetime

    class Config:
        from_attributes = True
