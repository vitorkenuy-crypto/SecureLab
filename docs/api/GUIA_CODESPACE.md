# SecureLab: guia do Codespace

Comandos para fechar e reabrir o ambiente no dia a dia. Rode tudo a partir da
raiz do projeto: `cd /workspaces/SecureLab`.

## O que fica salvo e o que não fica

| Item | Depois de fechar o Codespace |
|---|---|
| Código, `backend/.env`, `backend/venv`, Flutter instalado | Continuam lá |
| Dados do PostgreSQL | Continuam (ficam num volume do Docker) |
| API e app Flutter rodando | **Param**: precisa subir de novo |
| Visibilidade das portas (Públicas) | **Podem voltar para Privadas**: confira |
| Alterações não commitadas | Continuam, mas faça commit para não perder |

---

## Parar o Codespace

1. Pare a API e o app nos terminais com `Ctrl+C`.
2. Faça commit e push do que mudou (veja abaixo).
3. Feche a aba do navegador. O Codespace hiberna sozinho depois de cerca de 30 minutos parado.
   Para parar na hora: `F1` → **Codespaces: Stop Current Codespace**, ou em
   https://github.com/codespaces use os três pontinhos → **Stop codespace**.

Salvar o trabalho:

```bash
git status
git add <arquivos>
git commit -m "Descreva a mudança"
git push
```

Nunca adicione ao commit: `backend/.env`, `backend/venv/`, `firmware/include/config.h`.

---

## Reabrir o Codespace

1. Entre em https://github.com/codespaces e clique no Codespace do SecureLab.
2. Espere carregar. Os containers do app e do banco sobem sozinhos.
3. Abra um terminal e confirme que o banco está de pé:

```bash
cd /workspaces/SecureLab
pg_isready -h localhost -U postgres
```

O esperado é `accepting connections`. Se der outra resposta, espere meio minuto e tente de novo.

### Terminal 1: API

```bash
cd /workspaces/SecureLab
bash .devcontainer/dev.sh api
```

Deixe aberto. Quando aparecer `Uvicorn running on http://0.0.0.0:8000`, está no ar.

Opção mais leve em memória (sem reinício automático ao editar o código):

```bash
cd /workspaces/SecureLab/backend
./venv/bin/python -m uvicorn main:app --host 0.0.0.0 --port 8000
```

### Terminal 2: App Flutter

Modo recomendado nesta máquina (usa menos memória). Se você **não** mudou o código
do app desde a última vez, a pasta `build/web` já existe e basta servir:

```bash
cd /workspaces/SecureLab/mobile
python3 -m http.server 8081 --directory build/web
```

Se mudou o código do app (ou a pasta `build/web` não existe), gere de novo:

```bash
cd /workspaces/SecureLab/mobile
flutter build web --release
python3 -m http.server 8081 --directory build/web
```

Modo de desenvolvimento, com hot reload (usa muita memória e pode ser encerrado
pelo sistema; se falhar, use o modo acima):

```bash
cd /workspaces/SecureLab
bash .devcontainer/dev.sh app
```

### Portas públicas

Abra a aba **Portas** (ao lado de Terminal) e confira as portas **8000** e **8081**.
Se não estiverem como **Pública**, clique com o botão direito na porta →
**Visibilidade da Porta** → **Pública**. Com a 8000 privada, o app dá erro de CORS.

### Entrar no app

1. Abra a URL da porta 8081 (ícone de globo na aba Portas).
2. Na tela de login, abra a opção de **servidor** e confira se o endereço é a URL
   da porta 8000, **sem** `/docs` e sem barra no final.
3. Entre com o usuário e a senha do admin.

Para ver as URLs do seu Codespace:

```bash
bash .devcontainer/dev.sh urls
```

---

## Outros comandos úteis

```bash
bash .devcontainer/dev.sh seed       # dados de exemplo (só em banco vazio)
bash .devcontainer/dev.sh psql       # console do PostgreSQL
bash .devcontainer/dev.sh firmware   # compila o firmware do ESP32 (não grava)
free -h                              # memória livre
```

Ver as tabelas no banco:

```bash
PGPASSWORD=securelab psql -h localhost -U postgres -d securelab -c "\dt"
```

---

## Se algo der errado

| Sintoma | O que fazer |
|---|---|
| `backend/venv/bin/python: No such file` | Rode `bash .devcontainer/setup.sh` |
| `psql: command not found` | Rode `bash .devcontainer/setup.sh` |
| `flutter: command not found` | Abra um terminal novo; se persistir, `export PATH="$HOME/flutter/bin:$PATH"` |
| `connection refused` ao subir a API | O banco ainda está iniciando: `pg_isready -h localhost -U postgres` e tente de novo |
| Erro de CORS no app | Porta 8000 não está Pública, ou falta `CORS_ORIGIN_REGEX` no `backend/.env` |
| App diz "não foi possível conectar" | API parada, porta 8000 privada, ou URL do servidor errada |
| `The Dart compiler exited unexpectedly` | Falta de memória: pare a API, use `flutter build web --release` |
| Login recusado | Veja "Trocar a senha do admin" abaixo |
| Mudei `devcontainer.json` ou `docker-compose.yml` | `F1` → **Codespaces: Rebuild Container** |

O `setup.sh` pode ser rodado de novo sem risco: ele mantém o `.env` existente e
não apaga dados do banco.

### Trocar a senha do admin

```bash
cd /workspaces/SecureLab/backend
./venv/bin/python -c "from passlib.context import CryptContext; print(CryptContext(schemes=['bcrypt']).hash('NOVA_SENHA'))"
```

Cole o resultado na linha `ADMIN_PASSWORD_HASH=` do `backend/.env` (sem aspas),
pare a API com `Ctrl+C` e suba de novo.

### Recriar tudo do zero (último recurso)

`F1` → **Codespaces: Rebuild Container** refaz os containers e roda o `setup.sh`.
Se precisar apagar também os dados do banco, use **Full Rebuild** e confirme que
não precisa do que está lá.

---

## Observações

- A API fica exposta na internet enquanto a porta 8000 estiver Pública. Use uma
  senha forte de admin e deixe o Codespace parado quando não estiver usando.
- O Codespace consome horas gratuitas enquanto está ligado. Se trocou para uma
  máquina maior, volte para a menor quando terminar.
- O ESP32 não grava pelo Codespace (ele não enxerga a porta USB). Grave pelo seu
  computador, apontando `API_URL` do firmware para onde a API estiver rodando.
