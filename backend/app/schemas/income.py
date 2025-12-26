from pydantic import BaseModel
from datetime import date, datetime
from decimal import Decimal


class IncomeBase(BaseModel):
    description: str
    amount: Decimal
    received_date: date
    is_recurring: bool = False
    recurrence_end_date: date | None = None


class IncomeCreate(IncomeBase):
    pass


class IncomeResponse(IncomeBase):
    id: int
    user_id: int
    created_at: datetime

    class Config:
        from_attributes = True
