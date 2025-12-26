# 💰 **MyFinance**
**SUA PLATAFORMA DE GESTÃO FINANCEIRA PESSOAL**

## 🚀 Como rodar o projeto

### ✅ Pré-requisitos
- **Backend**: Python 3.8+ instalado.
- **Frontend**: Flutter SDK instalado e configurado (verifique com `flutter doctor`).
- **Banco de dados**: PostgreSQL (ou outro compatível com SQLAlchemy).

### 🧭 Passo a passo

#### 1. **Configurar e rodar o Backend (FastAPI)**
   - Navegue para a pasta do backend:
     ```
     cd .\backend
     ```
   - Instale as dependências:
     ```
     pip install -r requirements.txt
     ```
   - Configure o banco de dados (ex.: PostgreSQL) e atualize `app/database.py` com suas credenciais.
   - Execute o servidor:
     ```
     python -m uvicorn app.main:app --reload
     ```
     - O backend estará rodando em `http://127.0.0.1:8000`.
     - Teste acessando `http://127.0.0.1:8000/hello` no navegador.

#### 2. **Configurar e rodar o Frontend (Flutter)**
   - Navegue para a pasta do frontend:
     ```
     cd .\frontend
     ```
   - Instale as dependências do Flutter (se necessário):
     ```
     flutter pub get
     ```
   - Execute o app Flutter. Escolha o dispositivo alvo:
     - **Emulador Android/iOS** (certifique-se de que um emulador está rodando):
       ```
       flutter run
       ```
     - **Desktop (Windows)**:
       ```
       flutter run -d windows
       ```
     - **Web (Chrome)**:
       ```
       flutter run -d chrome
       ```
     - O app detectará automaticamente se está em emulador (usa `http://10.0.2.2:8000` para backend) ou dispositivo físico/desktop (usa `http://localhost:8000`).

#### 3. **Testes Locais**
   - **Fluxo básico**: Abra o app, registre um usuário, faça login, adicione receitas/despesas e visualize os totais no dashboard.
   - **APIs**: Monitore os logs no terminal do backend para ver as requests (ex.: `POST /auth/login`).
   - **Erros comuns**:
     - "Connection refused": Verifique se o backend está rodando na porta 8000.
     - Firewall: Permita a porta 8000 ou desative temporariamente.
     - Emulador: Certifique-se de que o backend é acessível via `10.0.2.2`.
   - **Debug**: Use `print()` no Flutter ou DevTools para logs. No backend, veja os logs no terminal.

#### 4. **Parar os testes**
   - Backend: Pressione `Ctrl+C` no terminal.
   - Frontend: Pressione `q` no terminal ou feche a janela.

## 📋 Funcionalidades
- Cadastro e login de usuários.
- Adição de receitas e despesas (com recorrência opcional).
- Dashboard com totais mensais.
- Detalhes de receitas/despesas por mês/ano.

## 🛠️ Tecnologias
- **Backend**: FastAPI, SQLAlchemy, PostgreSQL, JWT (python-jose).
- **Frontend**: Flutter (Dart), HTTP para APIs.

## 📝 Notas
- Para produção, considere Docker ou deploy em nuvem (ex.: Heroku, Vercel).
- Banco de dados: Execute os scripts em `sql/` para criar tabelas.