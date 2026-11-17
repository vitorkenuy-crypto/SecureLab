#!/usr/bin/env bash
# Roda uma vez, quando o Codespace é criado. Pode ser executado de novo sem medo.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
DB_DIR="database"
APP_DIR="mobile"
export PGPASSWORD=securelab
export PATH="$HOME/flutter/bin:$HOME/.local/bin:$PATH"

echo "==> [1/6] Pacotes do sistema"
# A imagem traz o repositório do Yarn com chave expirada; não usamos Yarn.
sudo rm -f /etc/apt/sources.list.d/yarn.list
sudo apt-get update -y || true
sudo apt-get install -y --no-install-recommends postgresql-client unzip xz-utils

echo "==> [2/6] Backend (venv + dependências)"
cd "$ROOT/backend"
# Se o venv veio do Windows (pasta Scripts/), não serve no Linux: recria.
if [ -d venv ] && [ ! -x venv/bin/python ]; then
  echo "    venv do Windows detectado, recriando..."
  rm -rf venv
fi
[ -x venv/bin/python ] || python3 -m venv venv
./venv/bin/pip install --quiet --upgrade pip
./venv/bin/pip install --quiet -r requirements.txt

echo "==> [3/6] backend/.env"
if [ ! -f .env ]; then
  ADMIN_PASSWORD="${ADMIN_PASSWORD:-admin123}"
  ./venv/bin/python - "$ADMIN_PASSWORD" <<'PY'
import secrets, sys
from passlib.context import CryptContext

senha_hash = CryptContext(schemes=["bcrypt"]).hash(sys.argv[1])
linhas = [
    "DB_USER=postgres",
    "DB_PASSWORD=securelab",
    "DB_HOST=localhost",
    "DB_PORT=5432",
    "DB_NAME=securelab",
    "ADMIN_USERNAME=admin",
    f"ADMIN_PASSWORD_HASH={senha_hash}",
    f"SECRET_KEY={secrets.token_hex(32)}",
    "ALGORITHM=HS256",
    "ACCESS_TOKEN_EXPIRE_MINUTES=60",
    # Libera localhost e qualquer *.app.github.dev (Codespaces) no CORS.
    r"CORS_ORIGIN_REGEX=^(https?://(localhost|127\.0\.0\.1)(:\d+)?|https://[a-z0-9-]+\.app\.github\.dev)$",
]
open(".env", "w", encoding="utf-8").write("\n".join(linhas) + "\n")
PY
  echo "    .env criado (login: admin / ${ADMIN_PASSWORD})"
else
  echo "    .env já existe, mantido."
fi

echo "==> [4/6] Banco de dados (schema)"
cd "$ROOT"
for i in $(seq 1 30); do
  pg_isready -h localhost -U postgres -q && break
  echo "    aguardando o PostgreSQL... ($i)"
  sleep 2
done
psql -h localhost -U postgres -d securelab -v ON_ERROR_STOP=1 -q -f "$DB_DIR/schema.sql"
echo "    schema aplicado. Para dados de exemplo: bash .devcontainer/dev.sh seed"

echo "==> [5/6] Flutter"
if [ ! -d "$HOME/flutter" ]; then
  git clone --depth 1 -b stable https://github.com/flutter/flutter.git "$HOME/flutter"
fi
grep -q 'flutter/bin' "$HOME/.bashrc" || \
  echo 'export PATH="$HOME/flutter/bin:$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
flutter config --no-analytics --enable-web >/dev/null
flutter precache --web
(cd "$ROOT/$APP_DIR" && flutter pub get)

echo "==> [6/6] Firmware (PlatformIO)"
pip install --quiet --user platformio
[ -f firmware/include/config.h ] || cp firmware/include/config.example.h firmware/include/config.h

echo
echo "Pronto! Veja os comandos com:  bash .devcontainer/dev.sh"