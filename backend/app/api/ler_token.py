from fastapi import Depends, HTTPException, status, APIRouter
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from app.models.user import User
from app.utils import token
from app.database import SessionLocal

router = APIRouter()

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="login")

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def get_current_user(token_str: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    email = token.validar_token_acesso(token_str)
    if email is None:
        raise HTTPException(status_code=401, detail="Token inválido ou expirado")

    user = db.query(User).filter_by(email=email).first()
    if user is None:
        raise HTTPException(status_code=404, detail="Usuário não encontrado")

    return user

# Endpoint protegido
@router.get("/me")
def get_user_data(current_user = Depends(get_current_user)):
    return {
        "id": current_user.id,
        "email": current_user.email,
        "nome": current_user.nome
    }