# SecureLab: rodar no VS Code e testar

Guia para subir o banco, a API e o app no Windows, pelo VS Code, e testar as funcionalidades **sem o hardware**. O ESP32 é simulado por um script.

Ordem: **Banco → API → App → Testes**.

---

## 0. Instalar (uma vez só)

| O quê | Para quê | Como conferir |
|---|---|---|
| [VS Code](https://code.visualstudio.com/) | editor | — |
| [Python 3.11+](https://www.python.org/downloads/) (marque *Add to PATH*) | API | `python --version` |
| [PostgreSQL + pgAdmin](https://www.postgresql.org/download/windows/) | banco | pgAdmin abre |
| [Flutter SDK](https://docs.flutter.dev/get-started/install/windows/mobile) | app | `flutter --version` |
| [Android Studio](https://developer.android.com/studio) | SDK Android + emulador | `flutter doctor` |

Depois de instalar o Android Studio:
```powershell
flutter doctor --android-licenses   # aceite tudo com "y"
flutter doctor                      # Flutter e Android toolchain precisam estar com ✓
```
No Android Studio: **More Actions > Virtual Device Manager > Create device** (ex: Pixel 7, Android 14). É esse emulador que o VS Code vai usar.

### Abrir o projeto
1. VS Code > **File > Open Folder** > escolha a pasta **`Secure Lab`** (a raiz, não `mobile`).
2. O VS Code vai sugerir as extensões recomendadas (Python, Python Debugger, Dart, Flutter). Clique em **Install All**.
3. Use o terminal do VS Code (**Ctrl + '**). Ele já abre no PowerShell.
4. Ative as configurações de execução do projeto (uma vez só), na raiz `Secure Lab`:
   ```powershell
   Copy-Item tools\vscode .vscode -Recurse -Force
   ```
   Isso cria a `.vscode` com o botão **API + App** (passo 4) e as extensões recomendadas. Se as extensões não forem sugeridas, instale **Python**, **Python Debugger** e **Flutter** pela aba de extensões.

---

## 1. Banco de dados (PostgreSQL)

No **pgAdmin**:
1. Botão direito em *Databases* > *Create* > *Database* > nome **`securelab`**.
2. Clique no banco `securelab` > **Query Tool** > abra `database/schema.sql` > **F5**.
3. Na mesma Query Tool, abra `database/seeds/seed.sql` > **F5**.

Os dados de exemplo criam:

| Usuário | Situação | Digital (template) |
|---|---|---|
| Ana Silva | ativa | 1 |
| Bruno Costa | ativo | 2 |
| Carla Souza | **inativa** | 3 |

E os ambientes **Porta Lab 1** (id 1) e **Porta Sala de Servidores** (id 2), ainda sem chave de API.

---

## 2. API (FastAPI)

No terminal do VS Code:
```powershell
cd backend
python -m venv venv
.\venv\Scripts\Activate.ps1          # se bloquear: Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned
pip install -r requirements.txt
copy .env.example .env
```

Gere o hash da senha do admin e a chave do JWT:
```powershell
python -c "from passlib.context import CryptContext; print(CryptContext(schemes=['bcrypt']).hash('admin123'))"
python -c "import secrets; print(secrets.token_hex(32))"
```
Abra `backend\.env` e preencha `DB_PASSWORD` (senha do seu PostgreSQL), `ADMIN_PASSWORD_HASH` (primeira saída) e `SECRET_KEY` (segunda saída). Deixe `ADMIN_USERNAME=admin`.

Teste subindo a API:
```powershell
uvicorn main:app --host 0.0.0.0 --port 8000
```
Abra http://127.0.0.1:8000/docs. Se o Swagger aparecer, a API está funcionando. Pare com **Ctrl + C**: daqui em diante ela sobe pelo VS Code.

> Se a API reclamar de `bcrypt`, de acento na senha ou de `.env`, veja *Problemas comuns* no `backend/README.md`.

---

## 3. App (Flutter)

Em outro terminal (**+** no painel do terminal):
```powershell
cd mobile
.\configurar.ps1        # se bloquear: Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```
O script gera as pastas Android/iOS, libera HTTP, baixa os ícones do Figma e roda `flutter pub get`.

Teste rápido do código:
```powershell
flutter analyze
flutter test
```

---

## 4. Rodar tudo pelo VS Code

1. Abra o emulador: **Ctrl + Shift + P** > `Flutter: Launch Emulator` > escolha o Pixel. Ou clique no nome do dispositivo no canto inferior direito do VS Code.
2. Vá em **Executar e Depurar** (**Ctrl + Shift + D**).
3. No menu de cima, escolha **API + App** e aperte **F5**.

Sobem dois processos: a API (com debugger Python: dá para pôr breakpoint no `main.py`) e o app no emulador (com *hot reload*: salve um arquivo `.dart` e a tela atualiza na hora).

No app, faça login com **admin / admin123** (ou a senha que você usou no hash).

> **Celular físico em vez de emulador:** ative *Depuração USB*, conecte no PC e escolha o celular no canto inferior direito do VS Code. No login, toque no endereço do servidor e troque para `http://IP-DO-PC:8000` (veja o IP com `ipconfig`). Libere a porta 8000 no Firewall do Windows.

---

## 5. Simular o ESP32

O ESP32 manda o template lido para `POST /acessos` com a chave do dispositivo. O script `tools/simular_esp32.ps1` faz exatamente isso.

1. No app: **Ambientes** > toque em **Porta Lab 1** > **Gerar nova chave de API** > **Copiar**.
2. Num terminal na raiz do projeto:
```powershell
.\tools\simular_esp32.ps1 -Chave "COLE_A_CHAVE" -Template 1
```
Resultado esperado: `AUTORIZADO` (é a digital da Ana). Use `-Dispositivo 2` com a chave da Sala de Servidores.

---

## 6. Roteiro de testes

Marque cada item conforme testar. Entre parênteses fica o que deve acontecer.

### Login
- [ ] Senha errada (*mensagem "Usuário ou senha incorretos"*)
- [ ] Olho da senha mostra e esconde o texto
- [ ] Login certo (*abre o Início com "Olá, admin"*)
- [ ] Fechar e abrir o app de novo (*continua logado*)

### Simular acessos (gera dados para as outras telas)
- [ ] `-Template 1` (*AUTORIZADO*: Ana, ativa, com digital)
- [ ] `-Template 3` (*NEGADO*: Carla está inativa)
- [ ] `-Template 99` (*NEGADO*: digital desconhecida)
- [ ] Chave errada (*401*)

### Início
- [ ] Arraste para baixo para atualizar (*Acessos hoje e Negadas mostram os números acima*)
- [ ] Card do sistema verde, "Sistema Operacional", com a taxa de autorização do dia
- [ ] Ponto vermelho no sino (*há negadas hoje*); tocar no sino abre o Histórico em **Negados**
- [ ] Cada card leva à aba correspondente

### Histórico
- [ ] Abas Todos / Autorizados / Negados filtram a lista
- [ ] Busca por "Ana" ou "Lab"
- [ ] Acesso negado de digital desconhecida aparece como **Desconhecido** com avatar vermelho "?"
- [ ] Botão de download (*"N registros copiados como CSV"*: cole no Excel)

### Usuários
- [ ] Contadores do topo (*3 cadastrados, 2 ativos*)
- [ ] Abas Ativos / Inativos e busca
- [ ] **+** > cadastrar "Teste Gabriel" (*abre o detalhe do novo usuário*)
- [ ] Cadastrar com e-mail repetido (*mensagem de e-mail já cadastrado*)
- [ ] Detalhe > **Permissões** (*todos os ambientes "Bloqueado: sem digital cadastrada"*)
- [ ] Editar o nome (lápis)

### Cadastrar biometria
- [ ] No detalhe do "Teste Gabriel" > **Cadastrar** (*template sugerido: 4*)
- [ ] Continuar > Confirmar (*tela de conclusão*)
- [ ] Voltar no detalhe: Permissões agora **Liberado** nos ambientes ativos
- [ ] Simular `-Template 4` (*AUTORIZADO*)
- [ ] Tentar cadastrar o template 1 (*bloqueia: já é da Ana*)

### Desativar e reativar
- [ ] Detalhe do "Teste Gabriel" > **Desativar usuário** (*aparece como Inativo*)
- [ ] Simular `-Template 4` (*NEGADO*)
- [ ] **Reativar usuário** > simular de novo (*AUTORIZADO*)

### Ambientes
- [ ] **+** > novo ambiente "Porta Lab 2" (*mostra a chave uma única vez*)
- [ ] Simular com a chave nova e o id dele (*funciona*)
- [ ] Gerar nova chave e simular com a **antiga** (*401*)

### Configurações
- [ ] **Biometria** lista as 4 digitais com o dono de cada uma
- [ ] Remover a digital 2 (Bruno) e simular `-Template 2` (*NEGADO*)
- [ ] **Servidor da API** mostra e testa o endereço
- [ ] **Sair** (*volta ao login*)

### Erros e sessão
- [ ] Parar a API (Shift + F5 no VS Code) e atualizar uma tela (*mensagem de conexão + "Tentar de novo"*)
- [ ] Token expirado: no `.env`, coloque `ACCESS_TOKEN_EXPIRE_MINUTES=1`, reinicie a API, espere 1 minuto e atualize (*volta sozinho para o login*). Depois volte para 60.

---

## Problemas comuns

| Sintoma | Solução |
|---|---|
| App: "Não foi possível conectar à API em http://10.0.2.2:8000" | A API não está rodando, ou você está num celular físico (use o IP do PC). |
| App: tudo funciona no emulador mas não no celular | Suba a API com `--host 0.0.0.0` (já está no launch) e libere a porta 8000 no firewall. |
| `CLEARTEXT communication not permitted` | Rode o `configurar.ps1` de novo: ele libera HTTP no AndroidManifest. |
| Ícones padrão no lugar dos do Figma | Os links do Figma expiraram (7 dias). Peça novos ou exporte os ícones do Figma para `mobile/assets/icons/` com os mesmos nomes. |
| VS Code: "API (FastAPI)" não acha o Python | Crie o venv em `backend\venv` (passo 2) ou escolha o interpretador com **Ctrl+Shift+P > Python: Select Interpreter**. |
| `flutter` não reconhecido | Adicione `C:\caminho\flutter\bin` ao PATH e reabra o VS Code. |
| Swagger dá 401 em tudo | Token de 60 min expirou: *Authorize* de novo. |
