from sqlalchemy import Column, BigInteger, String, Date, Boolean, Numeric, DateTime, ForeignKey
from sqlalchemy.sql import func
from app.database import Base


class Income(Base):
    __tablename__ = "incomes"

    id = Column(BigInteger, primary_key=True, index=True)
    user_id = Column(
        BigInteger,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )
    description = Column(String(255), nullable=False)
    amount = Column(Numeric(10, 2), nullable=False)
    received_date = Column(Date, nullable=False)
    is_recurring = Column(Boolean, nullable=False, default=False)
    recurrence_end_date = Column(Date, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())