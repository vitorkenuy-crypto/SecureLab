#!/usr/bin/env bash
# Atalhos do dia a dia. Uso: bash .devcontainer/dev.sh <comando>
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DB_DIR="database"
APP_DIR="mobile"
export PATH="$HOME/flutter/bin:$HOME/.local/bin:$PATH"
export PGPASSWORD=securelab

case "${1:-help}" in
  api)       # terminal 1
    cd "$ROOT/backend"
    exec ./venv/bin/python -m uvicorn main:app --host 0.0.0.0 --port 8000 \
      --reload --reload-exclude 'venv/*'
    ;;
  app)       # terminal 2
    cd "$ROOT/$APP_DIR"
    exec flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8081
    ;;
  public)    # torna as portas públicas (necessário p/ o app web e p/ o ESP32)
    gh codespace ports visibility 8000:public 8081:public -c "$CODESPACE_NAME"
    ;;
  urls)
    D="${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN:-app.github.dev}"
    echo "API (Swagger): https://${CODESPACE_NAME}-8000.${D}/docs"
    echo "App Flutter:   https://${CODESPACE_NAME}-8081.${D}"
    echo "Use a URL da API (sem /docs) no 'servidor' da tela de login do app."
    ;;
  seed)      # dados de exemplo (só em banco vazio)
    psql -h localhost -U postgres -d securelab -f "$ROOT/$DB_DIR/seeds/seed.sql"
    ;;
  psql)
    exec psql -h localhost -U postgres -d securelab
    ;;
  firmware)  # só compila; gravar no ESP32 precisa ser no seu PC
    cd "$ROOT/firmware" && exec pio run
    ;;
  *)
    cat <<'TXT'
Comandos:
  api       sobe a API na porta 8000 (deixe num terminal)
  app       sobe o app Flutter web na porta 8081 (outro terminal)
  public    deixa as portas 8000 e 8081 públicas
  urls      mostra as URLs do Codespace
  seed      carrega dados de exemplo no banco
  psql      abre o console do PostgreSQL
  firmware  compila o firmware do ESP32
TXT
    ;;
esac