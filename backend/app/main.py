from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from app.database import SessionLocal
# from app.api import esqueceu_senha, ler_token, dashboard
import os

from app.api import auth, expenses, incomes, register
from app.api.ler_token import router as ler_token_router

app = FastAPI()

app.include_router(register.router)
app.include_router(auth.router)
# app.include_router(esqueceu_senha.router)
app.include_router(ler_token_router)
app.include_router(incomes.router)
app.include_router(expenses.router)
# app.include_router(dashboard.router)

@app.get("/hello")
def read_hello():
    db = SessionLocal()
    try:
        return {"message": "Hello! Banco conectado!"}
    finally:
        db.close()