# SecureLab: App Mobile (Flutter)

App do administrador do SecureLab, feito a partir do protótipo no Figma
(Login, Início, Usuários, Cadastrar Biometria, Ambientes, Histórico, Configurações)
e ligado à API FastAPI da pasta `../backend`.

**Responsável pelo app:** Gabriel.

## Primeira vez

Pré-requisitos: [Flutter](https://docs.flutter.dev/get-started/install/windows) instalado e um emulador Android (ou celular com depuração USB).

```powershell
cd mobile
.\configurar.ps1
```

O script:
1. roda `flutter create .` para gerar as pastas `android/` e `ios/` (não mexe em `lib/`);
2. libera HTTP no `AndroidManifest.xml` (`usesCleartextTraffic`), já que a API local roda sem HTTPS;
3. baixa os ícones do Figma para `assets/icons/` (os links do Figma valem por 7 dias, até mais ou menos 08/11/2026);
4. roda `flutter pub get`.

Se o PowerShell bloquear: `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass`.

Sem os ícones o app funciona igual: cada ícone faltando é trocado por um ícone padrão do Material.

## Rodando

1. Suba a API (ver `../backend/README.md`). Para o app acessar de um celular físico:
   `uvicorn main:app --host 0.0.0.0 --port 8000`
2. `flutter run`
3. Na tela de login, toque no endereço do servidor (embaixo) se precisar trocar:
   - Emulador Android: `http://10.0.2.2:8000` (padrão)
   - Celular na mesma rede Wi-Fi: `http://IP-DO-PC:8000`
4. Entre com o `ADMIN_USERNAME` e a senha do admin configurados no `.env` da API.

Testes: `flutter test`

## Estrutura

```
lib/
  main.dart                 troca entre Login e app conforme o token
  core/
    api_client.dart         HTTP, token Bearer, erros da API (detail), 401 -> logout
    session.dart            endereço da API, token e usuário (shared_preferences)
    theme.dart              cores e textos do Figma
  models/models.dart        Usuario, Dispositivo, Digital, Acesso
  services/securelab_api.dart  uma função por rota da API
  widgets/                  cabeçalho, chips, abas, cards, ícones do Figma
  screens/                  uma tela por frame do Figma
```

## Tela x rota da API

| Tela (Figma) | Rotas |
|---|---|
| Login | `POST /auth/login` |
| Início | `GET /`, `GET /usuarios`, `GET /dispositivos`, `GET /acessos` (contagens de hoje e ontem via `X-Total-Count`) |
| Usuários | `GET /usuarios`, `GET /digitais`, `POST /usuarios`, `PATCH /usuarios/{id}`, `DELETE /usuarios/{id}` |
| Cadastrar Biometria | `GET /digitais`, `POST /digitais` |
| Ambientes | `GET /dispositivos`, `POST /dispositivos`, `POST /dispositivos/{id}/chave` |
| Histórico | `GET /acessos` (filtro por resultado, paginação) |
| Configurações > Biometria | `GET /digitais`, `DELETE /digitais/{id}` |

## O que mudou em relação ao protótipo (a API ainda não tem esses dados)

- **Usuários:** não existe status "Suspenso", nem cargo e nível. As abas são Todos / Ativos / Inativos, e o card mostra e-mail e se o usuário tem biometria.
- **Ambientes:** "Operacional" = dispositivo ativo e "Manutenção" = dispositivo inativo. A API ainda não tem rota para trocar esse status (`PATCH /dispositivos/{id}`), então isso continua sendo feito no banco.
- **Início:** "Uptime" virou "Taxa de autorização hoje" (autorizados / tentativas), e "+4 esta semana" virou o número de ativos, porque a API não devolve a data de criação.
- **Cadastrar Biometria:** a captura acontece no sensor do ESP32. Como a API não tem rota para iniciar a captura pelo app, o admin informa o número do template gravado pelo sensor (o app sugere o próximo livre) e o app faz o vínculo.
- **Histórico:** o botão de download copia os registros como CSV (separado por `;`, abre no Excel).
- **Notificações e Segurança** (Configurações) ainda não têm suporte na API e só mostram um aviso.
- **Configurações:** também tem "Servidor da API" e "Sair".
