# SecureLab - Controle de Acesso Biometrico (IoT)

Sistema de controle de acesso a laboratorios com leitor de digital (ESP32), API em Python (FastAPI) e app mobile/web em Flutter.

```
SecureLab/
|-- RODAR_SECURELAB.bat     -> liga a API e abre o app (e o que os colegas usam)
|-- SIMULAR_DIGITAL.bat     -> simula alguem colocando o dedo no sensor
|-- ZERAR_BANCO.bat         -> volta o banco para os dados de exemplo
|-- GERAR_PACOTE.bat        -> recompila o app Flutter e gera o zip de teste
|-- backend/                -> API (FastAPI + SQLite) e app ja compilado (backend/app_web)
|-- mobile/                 -> codigo-fonte do app Flutter
|-- database/               -> schema.sql e seeds
|-- firmware/               -> codigo do ESP32 (Arduino)
|-- docs/                   -> documentacao da API e guia de testes
`-- tools/                  -> scripts auxiliares
```

---

## Parte 1 - Como rodar no seu PC (para os colegas)

Voce **nao precisa instalar Flutter**. O app ja vem compilado dentro de `backend/app_web`. So precisa de Windows 10/11 e internet na primeira vez.

### 1. Baixar o projeto

**Opcao A - pelo site (mais facil):**
1. Abra a pagina do repositorio no GitHub.
2. Clique no botao verde **Code** > **Download ZIP**.
3. Clique com o botao direito no zip baixado > **Extrair Tudo...**
4. **Importante:** rode sempre de dentro da pasta extraida, nunca de dentro do zip.

**Opcao B - com Git:**
```
git clone https://github.com/SEU-USUARIO/securelab.git
```

### 2. Rodar

1. Entre na pasta e de **dois cliques em `RODAR_SECURELAB.bat`**.
2. Na primeira vez ele instala sozinho o que falta (Python 3.12 e as bibliotecas da API). Leva de 5 a 10 minutos.
3. Se aparecer **"O Windows protegeu o computador"**: clique em **Mais informacoes** > **Executar assim mesmo**.
4. Se o Windows perguntar sobre o **Firewall**: marque **Redes privadas** e clique em **Permitir**.
5. O app abre sozinho no navegador em `http://localhost:8000/app/`.

**Login:** `admin`  |  **Senha:** `admin123`

> Deixe a janela preta aberta enquanto estiver testando. Para desligar, e so fechar ela.

### 3. Simular o sensor de digital (sem hardware)

Com o app aberto, de dois cliques em **`SIMULAR_DIGITAL.bat`** e digite o numero da digital:

| Digital | Pessoa | Resultado |
|---|---|---|
| 1 | Ana (ativa) | AUTORIZADO |
| 2 | Bruno (ativo) | AUTORIZADO |
| 3 | Carla (inativa) | NEGADO |
| 99 | desconhecida | NEGADO |

O acesso aparece no Historico do app.

### 4. Abrir no celular

O celular precisa estar **no mesmo Wi-Fi** do PC. Use o endereco que aparece na janela preta em **"App no celular"** (exemplo: `http://192.168.0.15:8000/app`).

### 5. ESP32 de verdade

Veja `firmware/securelab_esp32/LEIA-ME.md`. O ESP32 envia os acessos para o endereco **"API para o ESP32"** mostrado na janela preta.

### 6. Voltar aos dados de exemplo

Feche a janela preta e de dois cliques em **`ZERAR_BANCO.bat`**. Os dados de teste ficam so no PC de quem esta testando (`backend/securelab_local.db`).

### Problemas comuns

| Problema | Solucao |
|---|---|
| "Esta pasta nao tem o app pronto" | Falta a pasta `backend/app_web`. Baixe o projeto de novo pelo GitHub. |
| "Nao consegui instalar o Python 3.12" | Instale pelo [python.org](https://www.python.org/downloads/) (versao 3.12), marque **Add python.exe to PATH** e rode de novo. |
| Celular nao abre o app | Confira se esta no mesmo Wi-Fi e se o Firewall foi liberado em "Redes privadas". |
| Porta 8000 ocupada | Feche outras janelas do SecureLab que estejam abertas. |

---

## Parte 2 - Para quem vai mexer no app (desenvolvedores)

- **API:** `backend/` - FastAPI + SQLite. Detalhes em `backend/README.md` e `docs/api/api-securelab.md`.
- **App:** `mobile/` - Flutter/Dart. Para rodar em modo de desenvolvimento: `cd mobile`, `flutter pub get`, `flutter run -d chrome`.
- Depois de alterar o app, rode **`GERAR_PACOTE.bat`**: ele recompila o Flutter para web e atualiza `backend/app_web`. Faca commit dessa pasta para os colegas receberem o app novo.
- Guia completo de testes: `docs/guia-rodar-e-testar.md`.

---

## Parte 3 - Como subir este projeto para o GitHub (primeira vez)

### Passo 1 - Criar o repositorio
1. Entre em [github.com](https://github.com) e faca login.
2. Clique no **+** (canto superior direito) > **New repository**.
3. Nome: `securelab`. Escolha **Public** ou **Private**.
4. **Nao** marque "Add a README" nem ".gitignore" (ja estao no projeto).
5. Clique em **Create repository** e deixe a pagina aberta.

> Se for **Private**, va em **Settings > Collaborators > Add people** e adicione os colegas.

### Passo 2 - Enviar os arquivos

> O upload pelo navegador ("uploading an existing file") aceita no maximo 100 arquivos por vez, e este projeto tem mais que isso. Use uma das opcoes abaixo.

**Opcao A - GitHub Desktop (sem comandos, recomendado):**
1. Instale o [GitHub Desktop](https://desktop.github.com) e entre com sua conta.
2. **File > Add local repository...** > escolha a pasta extraida `SecureLab`.
3. Ele vai dizer que a pasta nao e um repositorio: clique em **create a repository** > **Create repository**.
4. Clique em **Publish repository** (barra de cima). Escolha o nome `securelab`, marque/desmarque **Keep this code private** e clique em **Publish**.
   - Se voce ja criou o repositorio no Passo 1, use **Repository > Repository settings > Remote** e cole a URL dele, depois **Push origin**.

**Opcao B - Git pelo terminal:**
1. Instale o [Git](https://git-scm.com/download/win) (pode deixar tudo padrao).
2. Abra a pasta `SecureLab`, clique na barra de endereco, digite `cmd` e aperte Enter.
3. Rode (troque `SEU-USUARIO` pelo seu usuario do GitHub):

```
git config --global user.name "Seu Nome"
git config --global user.email "seu-email@exemplo.com"

git init
git add .
git commit -m "Primeira versao do SecureLab"
git branch -M main
git remote add origin https://github.com/SEU-USUARIO/securelab.git
git push -u origin main
```

4. Na primeira vez, o Git abre uma janela para voce entrar na conta do GitHub. Faca login e o envio continua.
5. Atualize a pagina do repositorio: os arquivos e este README ja aparecem.

### Passo 3 - Enviar alteracoes depois
```
git add .
git commit -m "Descreva o que mudou"
git push
```
No GitHub Desktop: escreva a mensagem no canto inferior esquerdo, clique em **Commit to main** e depois em **Push origin**.

### O que NAO vai para o GitHub
O arquivo `.gitignore` ja impede o envio de: ambiente Python (`backend/venv`), banco local (`securelab_local.db`), senhas (`.env`), caches do Flutter (`.dart_tool`, `build`) e arquivos zip. Cada colega gera esses arquivos sozinho ao rodar o `RODAR_SECURELAB.bat`.
