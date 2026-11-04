"""
SecureLab: MODO LOCAL para testes (sem PostgreSQL, sem .env).

Sobe a mesma API do main.py, mas:
  - usa um banco em arquivo (SQLite) chamado securelab_local.db, criado sozinho
    na primeira vez, já com os dados de exemplo de database/seeds/seed.sql;
  - login fixo: usuário "admin", senha "admin123";
  - chaves de API fixas para os dispositivos de exemplo (para o simulador do ESP32):
      Porta Lab 1 (id 1)              -> chave-lab1
      Porta Sala de Servidores (id 2) -> chave-servidores
  - libera o acesso do app rodando no navegador (CORS).

Uso (na pasta backend, com o venv ativo):  uvicorn main_local:app --port 8000
Para recomeçar do zero, pare a API e apague o arquivo securelab_local.db.

Não altera main.py nem database.py: em produção continua valendo o PostgreSQL.
"""
import hashlib
import os
import sqlite3
from pathlib import Path

PASTA = Path(__file__).resolve().parent
DB_FILE = PASTA / "securelab_local.db"
SEED_FILE = PASTA.parent / "database" / "seeds" / "seed.sql"

# 1) Configuração fixa de teste. Definida ANTES de importar a API, então o .env
#    (se existir) não sobrescreve estes valores.
from passlib.context import CryptContext  # noqa: E402

os.environ["ADMIN_USERNAME"] = "admin"
os.environ["ADMIN_PASSWORD_HASH"] = CryptContext(schemes=["bcrypt"]).hash("admin123")
os.environ["SECRET_KEY"] = "modo-local-somente-para-testes-nao-use-em-producao"
os.environ.setdefault("ACCESS_TOKEN_EXPIRE_MINUTES", "60")

# Mesmas tabelas do database/schema.sql, adaptadas ao SQLite.
# Datas gravadas no horário local do PC (o app mostra a hora certa e o filtro "hoje" funciona).
SCHEMA_SQLITE = """
CREATE TABLE IF NOT EXISTS usuario (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    nome       VARCHAR(100) NOT NULL,
    email      VARCHAR(150) UNIQUE,
    ativo      BOOLEAN NOT NULL DEFAULT 1,
    criado_em  TIMESTAMP DEFAULT (datetime('now', 'localtime'))
);
CREATE TABLE IF NOT EXISTS dispositivo (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    nome          VARCHAR(100) NOT NULL,
    local         VARCHAR(100),
    ativo         BOOLEAN NOT NULL DEFAULT 1,
    api_key_hash  VARCHAR(64)
);
CREATE TABLE IF NOT EXISTS digital (
    id             INTEGER PRIMARY KEY AUTOINCREMENT,
    usuario_id     INTEGER NOT NULL REFERENCES usuario (id),
    template_id    INTEGER NOT NULL UNIQUE,
    cadastrada_em  TIMESTAMP DEFAULT (datetime('now', 'localtime'))
);
CREATE TABLE IF NOT EXISTS acesso (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    usuario_id        INTEGER REFERENCES usuario (id),
    dispositivo_id    INTEGER NOT NULL REFERENCES dispositivo (id),
    template_id_lido  INTEGER,
    data_hora         TIMESTAMP DEFAULT (datetime('now', 'localtime')),
    resultado         VARCHAR(20) NOT NULL CHECK (resultado IN ('AUTORIZADO', 'NEGADO'))
);
"""

CHAVES_FIXAS = {1: "chave-lab1", 2: "chave-servidores"}


def _criar_banco_se_preciso() -> None:
    if DB_FILE.exists():
        return
    con = sqlite3.connect(DB_FILE)
    try:
        con.executescript(SCHEMA_SQLITE)
        if SEED_FILE.exists():
            con.executescript(SEED_FILE.read_text(encoding="utf-8"))
        for dispositivo_id, chave in CHAVES_FIXAS.items():
            con.execute(
                "UPDATE dispositivo SET api_key_hash = ? WHERE id = ?",
                (hashlib.sha256(chave.encode("utf-8")).hexdigest(), dispositivo_id),
            )
        con.commit()
        print(f"[modo local] Banco criado em {DB_FILE.name} com os dados de exemplo.")
    finally:
        con.close()


_criar_banco_se_preciso()

# 2) Substitui o database.py (conexão PostgreSQL) por uma conexão com o arquivo SQLite,
#    antes de importar as rotas. models.py e main.py usam este módulo sem perceber a troca.
import sys  # noqa: E402
import types  # noqa: E402

from sqlalchemy import create_engine  # noqa: E402
from sqlalchemy.orm import declarative_base, sessionmaker  # noqa: E402

database = types.ModuleType("database")
database.engine = create_engine(f"sqlite:///{DB_FILE}", connect_args={"check_same_thread": False})
database.SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=database.engine)
database.Base = declarative_base()


def _get_db():
    db = database.SessionLocal()
    try:
        yield db
    finally:
        db.close()


database.get_db = _get_db
sys.modules["database"] = database

# 3) A API de verdade (main.py), sem nenhuma alteração.
from fastapi.middleware.cors import CORSMiddleware  # noqa: E402

from main import app  # noqa: E402

# 4) Libera o app rodando no navegador (Flutter web) a chamar a API.
#    expose_headers deixa o app ler o total de registros do histórico.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["X-Total-Count"],
)
app.title = "SecureLab API (modo local)"

# 5) Se existir o app já compilado (backend/app_web, gerado pelo GERAR_PACOTE.bat),
#    ele é servido em http://localhost:8000/app — quem testa não precisa de Flutter.
#    Pela rede Wi-Fi, celulares abrem http://IP-DO-PC:8000/app.
from fastapi.responses import RedirectResponse  # noqa: E402
from fastapi.staticfiles import StaticFiles  # noqa: E402

APP_WEB = PASTA / "app_web"
if (APP_WEB / "index.html").exists():
    @app.get("/app", include_in_schema=False)
    def _app_sem_barra():
        return RedirectResponse("/app/")

    app.mount("/app/", StaticFiles(directory=APP_WEB, html=True), name="app_web")
