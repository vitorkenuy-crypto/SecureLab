# SecureLab

Sistema de controle de acesso biométrico composto por três partes:

```text
SecureLab/
├── backend/   API FastAPI e banco PostgreSQL
├── database/  esquema e dados opcionais do PostgreSQL
├── docs/      documentação complementar da API
├── firmware/  firmware ESP32, compilado com PlatformIO
└── mobile/    aplicativo administrativo Flutter
```

## Como o sistema funciona

1. O ESP32 lê o `template_id` da digital no sensor R307.
2. O firmware envia `dispositivo_id` e `template_id_lido` à API por
   `POST /acessos`, com a chave `X-API-Key`.
3. A API consulta o PostgreSQL, registra a tentativa e devolve
   `AUTORIZADO` ou `NEGADO`.
4. O ESP32 libera ou mantém a fechadura fechada. O app administra usuários,
   digitais e dispositivos e mostra o histórico.

O ESP32 nunca decide sozinho se um acesso deve ser liberado.

## Pré-requisitos

- PostgreSQL;
- Python 3.11 ou superior;
- Flutter e Chrome, para executar o app web;
- VS Code com PlatformIO, apenas para gravar o ESP32.

## Primeira configuração

### Banco de dados

Crie um banco PostgreSQL chamado `securelab`. No PowerShell, com `psql`
disponível, execute:

```powershell
psql -U postgres -d securelab -f database\schema.sql
```

Para criar dados de demonstração em um banco vazio:

```powershell
psql -U postgres -d securelab -f database\seeds\seed.sql
```

### Backend

```powershell
cd backend
copy .env.example .env
python -m venv venv
.\venv\Scripts\python.exe -m pip install -r requirements.txt
```

Edite `backend/.env` e informe a senha do PostgreSQL, o hash da senha do
administrador e uma `SECRET_KEY`. Gere o hash da senha com:

```powershell
.\venv\Scripts\python.exe -c "from passlib.context import CryptContext; print(CryptContext(schemes=['bcrypt']).hash('SUA_SENHA'))"
```

Inicie a API:

```powershell
.\venv\Scripts\python.exe -m uvicorn main:app --host 0.0.0.0 --port 8000
```

Confirme que ela está funcionando ao abrir http://127.0.0.1:8000/docs.
Mantenha esse terminal aberto.

### Aplicativo

Em outro PowerShell:

```powershell
cd ..\mobile
flutter pub get
flutter run -d chrome
```

O Chrome abre o aplicativo. Entre com o `ADMIN_USERNAME` e a senha
configurados no `.env`. Para parar o app, pressione `q` no terminal do
Flutter; para parar a API, use `Ctrl+C`.

Também é possível iniciar ambos com `mobile\INICIAR_SECURELAB.bat`, quando
a porta 8000 estiver livre.

## ESP32

1. Crie um dispositivo no app, em **Ambientes**, e guarde o ID e a chave de
   API apresentada.
2. Ajuste Wi-Fi, `DISPOSITIVO_ID`, `API_KEY` e `API_URL` em
   `firmware/include/config.h`.
3. Use em `API_URL` o IP local do computador, por exemplo
   `http://192.168.1.10:8000`; nunca `localhost`.
4. Abra `firmware/` no VS Code e faça o upload usando PlatformIO.
5. Cadastre uma digital pelo monitor serial e vincule o mesmo `template_id`
   a um usuário pelo app.

O computador, ESP32 e celular devem estar na mesma rede local para se
comunicarem. App e API no mesmo computador funcionam com `localhost` e não
precisam de internet após as dependências já terem sido instaladas.

## Verificação rápida

- API: http://127.0.0.1:8000/docs abre o Swagger.
- App: o login e as telas de usuários/dispositivos carregam sem erro de API.
- Hardware: uma leitura aparece no histórico como autorizada ou negada.

Consulte também os READMEs de `backend/`, `firmware/` e `mobile/`.
