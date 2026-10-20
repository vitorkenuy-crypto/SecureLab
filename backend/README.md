# SecureLab: Backend

API do **SecureLab** (pasta `backend/` do monorepo). Um ESP32 com sensor de digital R307 lê a digital, envia para esta API, e a API decide se libera ou nega o acesso, registrando toda tentativa. O README geral do projeto está na raiz do repositório.

**Stack:** Python, FastAPI, SQLAlchemy, PostgreSQL, JWT (login do admin), chave de API (dispositivos).

**Responsável pelo backend e banco de dados:** Matheus.

**Onde está o resto:** banco em [`../database/`](../database), documentação completa da API em [`../docs/api/api-securelab.md`](../docs/api/api-securelab.md), firmware em [`../firmware/`](../firmware).

---

## Como funciona

- O **ESP32 nunca decide** se o acesso é liberado. Ele só envia o `template_id` lido pelo sensor e o seu `dispositivo_id`. A decisão é sempre da API.
- Regra atual: **usuário ativo + digital cadastrada + dispositivo ativo = AUTORIZADO**. Qualquer outro caso = NEGADO.
- Toda tentativa, autorizada ou negada, fica registrada em `acesso`.
- Remover um usuário é um *soft delete* (`ativo = false`): ele deixa de ser autorizado, mas o histórico dele é preservado.

## Segurança em duas camadas

| Quem | Como se identifica | Onde é usado |
|---|---|---|
| **Administrador** (app, Swagger) | Login em `POST /auth/login` → token JWT no header `Authorization: Bearer <token>` (expira em 60 min por padrão) | Todas as rotas, **exceto** `GET /`, `POST /auth/login` e `POST /acessos` |
| **Dispositivo** (ESP32) | Chave de API no header `X-API-Key` | Somente `POST /acessos` |

Segredos (senha do banco, hash do admin, chave do JWT) ficam no `.env`, que **nunca** vai para o Git. No banco só ficam hashes: da senha do admin (bcrypt, no `.env`) e das chaves dos dispositivos (SHA-256).

---

## Instalação (Windows / PowerShell)

### 1. Pré-requisitos
- Python 3.11 ou superior (desenvolvido com 3.14)
- PostgreSQL (com pgAdmin 4, opcional mas recomendado)
- Git

### 2. Clonar e criar o ambiente virtual
```powershell
git clone https://github.com/vitorkenuy-crypto/SecureLab.git
cd SecureLab\backend
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
```
Se o PowerShell bloquear o `Activate.ps1`, rode antes: `Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned`.

### 3. Criar o banco
No pgAdmin: botão direito em *Databases* > *Create* > *Database*, nome `securelab`.
Depois abra o *Query Tool* nesse banco, carregue o arquivo `database/schema.sql` (na raiz do repositório) e execute (F5).

Opcional, para ter dados de exemplo: rode também o `database/seeds/seed.sql`.

### 4. Configurar o `.env`
Dentro da pasta `backend`:
```powershell
copy .env.example .env
```
Edite o `.env` e preencha:

- `DB_PASSWORD`: a senha do seu PostgreSQL (use uma senha sem acentos).
- `ADMIN_PASSWORD_HASH`: gere com
  ```powershell
  python -c "from passlib.context import CryptContext; print(CryptContext(schemes=['bcrypt']).hash('SUA_SENHA_DE_ADMIN'))"
  ```
- `SECRET_KEY`: gere com
  ```powershell
  python -c "import secrets; print(secrets.token_hex(32))"
  ```

Cada variável em uma linha própria, sem aspas.

### 5. Subir a API
Dentro da pasta `backend`, com o ambiente virtual ativo:
```powershell
uvicorn main:app --reload
```
Documentação interativa (Swagger): http://127.0.0.1:8000/docs

Para o ESP32 conseguir alcançar a API pela rede local, suba assim e use o IP do computador (libere a porta 8000 no firewall do Windows):
```powershell
uvicorn main:app --host 0.0.0.0 --port 8000
```

---

## Primeiros passos depois de subir

1. No `/docs`, clique em **Authorize** e entre com `ADMIN_USERNAME` e a senha do admin.
2. Crie um dispositivo com `POST /dispositivos`. A resposta traz o campo **`api_key`**. Ela aparece **uma única vez**: guarde-a e passe ao responsável pelo ESP32. Se perder, gere outra com `POST /dispositivos/{id}/chave` (a antiga deixa de valer na hora). Dispositivos criados pelo `seed.sql` também precisam desse passo.
3. Cadastre um usuário (`POST /usuarios`) e vincule a digital dele (`POST /digitais`, com o `template_id` do sensor).
4. Teste o acesso, simulando o ESP32:
   ```powershell
   Invoke-RestMethod -Method Post -Uri http://127.0.0.1:8000/acessos `
     -Headers @{"X-API-Key"="CHAVE_DO_DISPOSITIVO"} `
     -ContentType "application/json" `
     -Body '{"dispositivo_id": 1, "template_id_lido": 10}'
   ```

---

## Contrato com o ESP32

**Requisição:** `POST /acessos`

Header: `X-API-Key: <chave do dispositivo>`

```json
{ "dispositivo_id": 1, "template_id_lido": 10 }
```

**Resposta 200:**
```json
{ "id": 15, "usuario_id": 1, "dispositivo_id": 1, "template_id_lido": 10, "resultado": "AUTORIZADO" }
```

- `resultado = "AUTORIZADO"`: acionar a fechadura e o LED verde.
- `resultado = "NEGADO"`: manter trancado, LED vermelho e buzzer. Acontece com digital desconhecida, usuário inativo ou dispositivo desativado.
- **401**: dispositivo inexistente ou chave inválida (mesma resposta nos dois casos, de propósito).

A chave de API deve ficar apenas no código local do ESP32, **sem ir para o GitHub**.

---

## Rotas

| Método | Rota | Acesso | O que faz |
|---|---|---|---|
| GET | `/` | público | Verifica se a API está no ar |
| POST | `/auth/login` | público | Login do admin (formulário `username` e `password`); devolve o token |
| POST | `/acessos` | chave do dispositivo | Registra uma leitura do ESP32 e devolve AUTORIZADO ou NEGADO |
| GET | `/acessos` | admin | Histórico, com filtros `usuario_id`, `dispositivo_id`, `resultado`, `data_inicio`, `data_fim` (AAAA-MM-DD) e paginação `limit` (padrão 50, máx. 500) e `offset`. O total vem no header `X-Total-Count` |
| GET | `/usuarios` | admin | Lista usuários |
| GET | `/usuarios/{id}` | admin | Busca um usuário |
| POST | `/usuarios` | admin | Cadastra usuário (409 se o e-mail já existe) |
| PATCH | `/usuarios/{id}` | admin | Edita nome, e-mail ou `ativo` (serve para reativar) |
| DELETE | `/usuarios/{id}` | admin | Soft delete: marca `ativo = false` |
| GET | `/dispositivos` | admin | Lista dispositivos |
| POST | `/dispositivos` | admin | Cadastra dispositivo e devolve a `api_key` (uma única vez) |
| POST | `/dispositivos/{id}/chave` | admin | Gera uma nova chave de API; a antiga para de valer |
| GET | `/digitais` | admin | Lista digitais (filtro opcional `?usuario_id=`) |
| POST | `/digitais` | admin | Vincula um `template_id` a um usuário (409 se o template já existe) |
| DELETE | `/digitais/{id}` | admin | Remove uma digital |

Detalhes completos de corpo e respostas em `/docs` (Swagger) e em [`../docs/api/api-securelab.md`](../docs/api/api-securelab.md).

---

## Estrutura desta pasta

```
backend/
├── main.py            # rotas da API
├── models.py          # tabelas (SQLAlchemy)
├── schemas.py         # formatos de entrada e saída (Pydantic)
├── security.py        # JWT, hash de senha, chave de API dos dispositivos
├── database.py        # conexão com o PostgreSQL
├── requirements.txt   # dependências
├── .env.example       # modelo das variáveis de ambiente
└── README.md
```

Os scripts do banco ficam em `database/` (`schema.sql` e `seeds/seed.sql`), na raiz do repositório.

## Problemas comuns

- **`module 'bcrypt' has no attribute '__about__'`**: o `bcrypt` está numa versão nova demais. Rode `pip install bcrypt==4.0.1`.
- **`UnicodeDecodeError` ao conectar no banco**: senha do PostgreSQL com acento, ou arquivos do projeto criados *dentro* da pasta `venv`. Use senha sem acentos e mantenha `main.py`, `.env` etc. ao lado da pasta `venv`.
- **Variáveis do `.env` "coladas"** (ex.: `could not translate host name "localhost DB_PORT=5432"`): cada variável precisa estar em uma linha própria.
- **Conexão recusada ao testar a API**: o uvicorn não está rodando. Deixe-o em um terminal e use outro para os comandos.
- **401 em tudo no Swagger**: o token expirou (60 min). Clique em *Authorize* de novo.
