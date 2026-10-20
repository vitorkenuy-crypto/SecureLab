import os
import hashlib
import hmac
import secrets
from datetime import datetime, timedelta, timezone
from jose import jwt, JWTError
from passlib.context import CryptContext
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer

SECRET_KEY = os.getenv("SECRET_KEY")
ALGORITHM = os.getenv("ALGORITHM", "HS256")
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "60"))

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")

def verificar_senha(senha_digitada: str, senha_hash: str) -> bool:
    return pwd_context.verify(senha_digitada, senha_hash)

def criar_token(dados: dict) -> str:
    dados_para_codificar = dados.copy()
    expira_em = datetime.now(timezone.utc) + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    dados_para_codificar.update({"exp": expira_em})
    return jwt.encode(dados_para_codificar, SECRET_KEY, algorithm=ALGORITHM)

def get_current_admin(token: str = Depends(oauth2_scheme)):
    credenciais_invalidas = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Não foi possível validar as credenciais",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise credenciais_invalidas
    except JWTError:
        raise credenciais_invalidas
    return username


# ---------- Chave de API dos dispositivos (ESP32) ----------
# A chave é aleatória e longa, então basta um hash rápido (SHA-256) para guardá-la.
# No banco fica só o hash: se o banco vazar, as chaves reais não vazam junto.

def _hash_api_key(chave: str) -> str:
    return hashlib.sha256(chave.encode("utf-8")).hexdigest()

def gerar_api_key() -> tuple[str, str]:
    """Devolve (chave_em_texto, hash). A chave em texto só existe neste momento: mostre-a uma vez e descarte."""
    chave = secrets.token_urlsafe(32)
    return chave, _hash_api_key(chave)

def verificar_api_key(chave_enviada: str, hash_guardado: str | None) -> bool:
    if not chave_enviada or not hash_guardado:
        return False
    return hmac.compare_digest(_hash_api_key(chave_enviada), hash_guardado)