# from fastapi import APIRouter, Query, Depends
# from sqlalchemy.orm import Session
# from datetime import date
# from app.database import SessionLocal
# from backend.app.models.expense import Despesas
# from backend.app.models.income import Receitas
# from backend.app.models.expense import Despesas
# from app.schemas import categoria
# from collections import defaultdict
# from dateutil.relativedelta import relativedelta

# router = APIRouter()

# def get_db():
#     db = SessionLocal()
#     try:
#         yield db
#     finally:
#         db.close()

# @router.get("/contagem-despesas-por-dia-vencimento")
# def contagem_despesas_por_dia(
#     id_login: str = Query(...),
#     mes: int = Query(..., ge=1, le=12),
#     ano: int = Query(..., ge=1900),
#     db: Session = Depends(get_db)
# ):
#     data_consulta = date(ano, mes, 1)
#     despesas = db.query(Despesas).filter(Despesas.id_login == id_login).all()

#     contagem_por_dia = {}

#     for r in despesas:
#         data_base = r.data_vencimento.replace(day=1)
#         fim = r.fim_recorrencia.replace(day=1) if r.fim_recorrencia else None

#         if not r.recorrencia and data_base == data_consulta:
#             dia = r.data_vencimento.day
#             contagem_por_dia[dia] = contagem_por_dia.get(dia, 0) + 1
#         elif r.recorrencia and (data_consulta >= data_base and (fim is None or data_consulta <= fim)):
#             dia = r.data_vencimento.day
#             contagem_por_dia[dia] = contagem_por_dia.get(dia, 0) + 1

#     resultado = [{"dia": dia, "quantidade": quantidade} for dia, quantidade in sorted(contagem_por_dia.items())]
#     return resultado

# @router.get("/contagem-despesas-por-categoria")
# def contagem_despesas_por_categoria(id_login: str, mes: int, ano: int, db: Session = Depends(get_db)):
#     data_consulta = date(ano, mes, 1)
#     despesas = db.query(Despesas).filter(Despesas.id_login == id_login).all()

#     despesas_filtradas = []
#     for r in despesas:
#         data_base = r.data_vencimento.replace(day=1)
#         fim = r.fim_recorrencia.replace(day=1) if r.fim_recorrencia else None

#         if not r.recorrencia and data_base == data_consulta:
#             despesas_filtradas.append(r)
#         elif r.recorrencia and (data_consulta >= data_base and (fim is None or data_consulta <= fim)):
#             despesas_filtradas.append(r)

#     categorias = db.query(Categoria).all()
#     categorias_dict = {c.id: c.nome for c in categorias}

#     contagem = defaultdict(int)
#     for despesa in despesas_filtradas:
#         nome_categoria = categorias_dict.get(despesa.id_categoria, "Outros")
#         contagem[nome_categoria] += 1

#     return [{"categoria": nome, "quantidade": qtd} for nome, qtd in contagem.items()]

# @router.get("/total-receitas-periodo")
# def total_receitas_periodo(
#     id_login: str = Query(...),
#     mes: int = Query(..., ge=1, le=12),
#     ano: int = Query(..., ge=1900),
#     db: Session = Depends(get_db)
# ):
#     data_referencia = date(ano, mes, 1)
#     receitas = db.query(Receitas).filter(Receitas.id_login == id_login).all()

#     resultados = []

#     for i in range(-3, 3):
#         data_mes = data_referencia + relativedelta(months=i)
#         total_mes = 0.0

#         for r in receitas:
#             data_base = r.data_recebimento.replace(day=1)
#             fim = r.fim_recorrencia.replace(day=1) if r.fim_recorrencia else None

#             if not r.recorrencia and data_base == data_mes:
#                 total_mes += r.valor
#             elif r.recorrencia and (data_mes >= data_base and (fim is None or data_mes <= fim)):
#                 total_mes += r.valor

#         resultados.append({
#             "mes": data_mes.month,
#             "ano": data_mes.year,
#             "valor": total_mes
#         })

#     resultados.sort(key=lambda x: (x["ano"], x["mes"]))
#     return resultados

# @router.get("/total-despesas-periodo")
# def total_despesas_periodo(
#     id_login: str = Query(...),
#     mes: int = Query(..., ge=1, le=12),
#     ano: int = Query(..., ge=1900),
#     db: Session = Depends(get_db)
# ):
#     data_referencia = date(ano, mes, 1)
#     despesas = db.query(Despesas).filter(Despesas.id_login == id_login).all()

#     resultados = []

#     for i in range(-3, 3):
#         data_mes = data_referencia + relativedelta(months=i)
#         total_mes = 0.0

#         for r in despesas:
#             data_base = r.data_vencimento.replace(day=1)
#             fim = r.fim_recorrencia.replace(day=1) if r.fim_recorrencia else None

#             if not r.recorrencia and data_base == data_mes:
#                 total_mes += r.valor
#             elif r.recorrencia and (data_mes >= data_base and (fim is None or data_mes <= fim)):
#                 total_mes += r.valor

#         resultados.append({
#             "mes": data_mes.month,
#             "ano": data_mes.year,
#             "valor": total_mes
#         })

#     resultados.sort(key=lambda x: (x["ano"], x["mes"]))
#     return resultados

# @router.get("/total-receitas-recorrencia")
# def total_receitas_recorrencia(
#     id_login: str = Query(...),
#     mes: int = Query(..., ge=1, le=12),
#     ano: int = Query(..., ge=1900),
#     db: Session = Depends(get_db)
# ):
#     data_referencia = date(ano, mes, 1)
#     receitas = db.query(Receitas).filter(Receitas.id_login == id_login).all()

#     recorrentes = 0
#     nao_recorrentes = 0

#     for r in receitas:
#         data_base = r.data_recebimento.replace(day=1)
#         fim = r.fim_recorrencia.replace(day=1) if r.fim_recorrencia else None

#         if not r.recorrencia and data_base == data_referencia:
#             nao_recorrentes += 1
#         elif r.recorrencia and (data_referencia >= data_base and (fim is None or data_referencia <= fim)):
#             recorrentes += 1

#     return {
#         "mes": data_referencia.month,
#         "ano": data_referencia.year,
#         "recorrentes": recorrentes,
#         "nao_recorrentes": nao_recorrentes
#     }

# @router.get("/total-despesas-recorrencia")
# def total_despesas_recorrencia(
#     id_login: str = Query(...),
#     mes: int = Query(..., ge=1, le=12),
#     ano: int = Query(..., ge=1900),
#     db: Session = Depends(get_db)
# ):
#     data_referencia = date(ano, mes, 1)
#     despesas = db.query(Despesas).filter(Despesas.id_login == id_login).all()

#     recorrentes = 0
#     nao_recorrentes = 0

#     for r in despesas:
#         data_base = r.data_vencimento.replace(day=1)
#         fim = r.fim_recorrencia.replace(day=1) if r.fim_recorrencia else None

#         if not r.recorrencia and data_base == data_referencia:
#             nao_recorrentes += 1
#         elif r.recorrencia and (data_referencia >= data_base and (fim is None or data_referencia <= fim)):
#             recorrentes += 1

#     return {
#         "mes": data_referencia.month,
#         "ano": data_referencia.year,
#         "recorrentes": recorrentes,
#         "nao_recorrentes": nao_recorrentes
#     }