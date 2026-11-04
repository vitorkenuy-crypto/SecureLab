# API SecureLab: Documentação de Endpoints

> Backend: FastAPI + PostgreSQL. Base URL local: `http://127.0.0.1:8000`
> Documentação interativa (Swagger): `http://127.0.0.1:8000/docs`
> Responsável: Matheus

## Índice
- [Visão geral e regra de negócio](#visão-geral-e-regra-de-negócio)
- [Autenticação](#autenticação)
- [GET /](#get-)
- [Usuários](#usuários)
- [Dispositivos](#dispositivos)
- [Digitais](#digitais)
- [Acessos](#acessos)
- [Códigos de erro](#códigos-de-erro)
- [Melhorias conhecidas](#melhorias-conhecidas-ainda-não-implementadas)

---

## Visão geral e regra de negócio

O controle de acesso segue uma regra simples (modelo atual, sem permissão granular por ambiente):

> **Usuário ativo + digital cadastrada + dispositivo ativo → acesso AUTORIZADO.**
> Qualquer outro caso → acesso NEGADO.

**Para quem integra o hardware (Vitor):** o ESP32 nunca decide se o acesso é autorizado. Ele só envia o `template_id` que o sensor R307 leu e o `dispositivo_id` que o identifica, junto com a **chave de API do dispositivo** no header `X-API-Key`. Toda a decisão acontece no backend, na rota `POST /acessos`. A fonte da verdade é sempre o banco de dados.

**Para quem integra o app (Gabriel):** o app faz login como administrador (`POST /auth/login`), guarda o token e o envia em todas as demais rotas, no header `Authorization: Bearer <token>`. Toda tentativa de acesso, autorizada ou negada, fica registrada e pode ser consultada em `GET /acessos`, com o nome do usuário e do dispositivo já resolvidos.

### Quem pode chamar o quê

| Quem | Como se identifica | Rotas |
|---|---|---|
| Qualquer pessoa | nada | `GET /`, `POST /auth/login` |
| Administrador (app, Swagger) | token JWT (`Authorization: Bearer ...`) | todas as rotas de usuários, dispositivos, digitais e `GET /acessos` |
| Dispositivo (ESP32) | chave de API (`X-API-Key: ...`) | somente `POST /acessos` |

---

## Autenticação

### POST /auth/login
Login do administrador. Recebe um **formulário** (`application/x-www-form-urlencoded`), não JSON. O Swagger já monta isso pelo botão *Authorize*.

**Campos do formulário:**
- `username`: valor de `ADMIN_USERNAME` no `.env`
- `password`: a senha do admin (o `.env` guarda só o hash dela)

**Resposta 200:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer"
}
```

**Erros:** `401` (`"Usuário ou senha incorretos"`).

O token expira em `ACCESS_TOKEN_EXPIRE_MINUTES` (padrão 60). Depois disso as rotas de admin devolvem `401` e é preciso fazer login de novo.

### Como enviar o token
Em toda rota de administrador:
```
Authorization: Bearer <access_token>
```
Sem o header, ou com token inválido ou expirado, a resposta é `401`.

---

## GET /

Rota pública de verificação. Confirma que a API está no ar.

**Resposta 200:**
```json
{
  "mensagem": "SecureLab API rodando com sucesso"
}
```

---

## Usuários

Todas as rotas desta seção exigem **token de admin**.

### POST /usuarios
Cadastra um novo usuário.

**Corpo:**
```json
{
  "nome": "Ana Silva",
  "email": "ana.silva@email.com",
  "ativo": true
}
```
- `nome` (string, obrigatório)
- `email` (string, opcional, único)
- `ativo` (boolean, opcional, padrão `true`)

**Resposta 200:**
```json
{ "id": 1, "nome": "Ana Silva", "email": "ana.silva@email.com", "ativo": true }
```

**Erros:** `409` (e-mail já cadastrado), `422` (corpo inválido).

### GET /usuarios
Lista todos os usuários, inclusive os inativos.

**Resposta 200:**
```json
[
  { "id": 1, "nome": "Ana Silva", "email": "ana.silva@email.com", "ativo": true },
  { "id": 3, "nome": "Carla Souza", "email": "carla.souza@email.com", "ativo": false }
]
```

### GET /usuarios/{id}
Busca um usuário.

**Resposta 200:** o objeto do usuário (mesmo formato acima). **Erros:** `404`.

### PATCH /usuarios/{id}
Altera **somente os campos enviados**. Serve para corrigir dados e também para **reativar** um usuário removido.

**Corpo (todos os campos opcionais):**
```json
{ "nome": "Ana Souza Silva", "email": "ana.nova@email.com", "ativo": true }
```
Exemplo para reativar: `{ "ativo": true }`.

**Resposta 200:** o usuário atualizado.

**Erros:**
- `400`: `nome` ou `ativo` enviado como `null` (são obrigatórios)
- `404`: usuário não existe
- `409`: o e-mail já pertence a outro usuário

### DELETE /usuarios/{id}
Remove o usuário do sistema por **soft delete**: marca `ativo = false`. O registro e o histórico de acessos dele continuam no banco, mas ele deixa de ser autorizado em qualquer dispositivo. Para desfazer, use `PATCH` com `{ "ativo": true }`.

**Resposta 200:** o usuário já com `"ativo": false`. **Erros:** `404`.

---

## Dispositivos

Cada `dispositivo` representa fisicamente uma unidade ESP32 + R307 + fechadura instalada em um local. Todas as rotas desta seção exigem **token de admin**.

### POST /dispositivos
Cadastra um dispositivo e **gera a chave de API dele**.

**Corpo:**
```json
{ "nome": "Porta Lab 1", "local": "Laboratório 1", "ativo": true }
```
- `nome` (string, obrigatório)
- `local` (string, opcional)
- `ativo` (boolean, opcional, padrão `true`)

**Resposta 200:**
```json
{
  "id": 1,
  "nome": "Porta Lab 1",
  "local": "Laboratório 1",
  "ativo": true,
  "api_key": "qIXgg...(chave longa e aleatória)"
}
```
> **A `api_key` aparece uma única vez.** No banco fica apenas o hash dela. Copie e entregue ao responsável pelo ESP32. Se perder, gere outra (rota abaixo).

### POST /dispositivos/{id}/chave
Gera uma **nova** chave de API para um dispositivo. A chave antiga deixa de funcionar imediatamente. Use para dispositivos criados sem chave ou quando uma chave vazar.

**Resposta 200:** mesmo formato do `POST /dispositivos` (com o `api_key` novo). **Erros:** `404`.

### GET /dispositivos
Lista os dispositivos (a chave e o hash **não** aparecem aqui).

**Resposta 200:**
```json
[
  { "id": 1, "nome": "Porta Lab 1", "local": "Laboratório 1", "ativo": true },
  { "id": 2, "nome": "Porta Sala Servidores", "local": "Sala de Servidores", "ativo": true }
]
```

---

## Digitais

Vincula um `template_id` (identificador que o sensor R307 atribui internamente à digital) a um usuário. **Cada `template_id` só pode existir uma vez**, porque o sistema assume um único sensor físico no MVP atual. Todas as rotas desta seção exigem **token de admin**.

### POST /digitais
Cadastra uma digital para um usuário existente.

**Corpo:**
```json
{ "usuario_id": 1, "template_id": 10 }
```

**Resposta 200:**
```json
{ "id": 1, "usuario_id": 1, "template_id": 10 }
```

**Erros:** `404` (`usuario_id` não existe), `409` (`template_id` já cadastrado).

### GET /digitais
Lista as digitais. Filtro opcional: `?usuario_id=1`.

**Resposta 200:**
```json
[
  { "id": 1, "usuario_id": 1, "template_id": 10 },
  { "id": 2, "usuario_id": 2, "template_id": 11 }
]
```

### DELETE /digitais/{id}
Remove uma digital **definitivamente**. O histórico de acessos não é afetado (ele guarda `usuario_id` e `template_id_lido`, não o id da digital). Depois disso, leituras daquele `template_id` passam a ser `NEGADO`, e o `template_id` fica livre para ser cadastrado de novo.

> A digital continua gravada na memória do sensor R307. Apagá-la do sensor é feito no código do ESP32; para o backend, a digital deixa de valer assim que sai do banco.

**Resposta 200:** os dados da digital removida. **Erros:** `404`.

---

## Acessos

### POST /acessos
O coração do sistema. É esta rota que o **ESP32 chama** a cada leitura biométrica. **Não usa token de admin**: o dispositivo se identifica pela chave de API.

**Header obrigatório:**
```
X-API-Key: <chave do dispositivo>
```

**Corpo (o que o ESP32 envia):**
```json
{ "dispositivo_id": 1, "template_id_lido": 10 }
```
- `dispositivo_id` (int, obrigatório): qual dispositivo está fazendo a leitura
- `template_id_lido` (int, obrigatório): o que o sensor R307 leu. Pode ser um valor sem correspondência (digital desconhecida): a API trata normalmente e apenas nega

**Resposta 200, exemplo AUTORIZADO:**
```json
{ "id": 15, "usuario_id": 1, "dispositivo_id": 1, "template_id_lido": 10, "resultado": "AUTORIZADO" }
```

**Resposta 200, exemplo NEGADO:**
```json
{ "id": 16, "usuario_id": null, "dispositivo_id": 1, "template_id_lido": 999, "resultado": "NEGADO" }
```

**Quando o resultado é NEGADO** (a tentativa é registrada do mesmo jeito):
- a digital lida não está cadastrada
- a digital é de um usuário inativo
- o dispositivo está desativado (`ativo = false`)

**O que o ESP32 deve fazer com a resposta:** checar o campo `resultado`. Se `"AUTORIZADO"`, aciona o relé/fechadura e acende o LED verde. Se `"NEGADO"`, mantém a fechadura trancada, acende o LED vermelho e aciona o buzzer.

**Erros:**
- `401`: dispositivo inexistente **ou** chave ausente/errada. A resposta é a mesma nos dois casos, de propósito, para não revelar quais ids existem. Indica erro de configuração do hardware.
- `422`: corpo com formato inválido.

> A chave de API deve ficar apenas no código local do ESP32, **sem ir para o GitHub**.

### GET /acessos
Histórico de tentativas, mais recentes primeiro, com nomes já resolvidos. Exige **token de admin**.

**Parâmetros de consulta (todos opcionais, combináveis):**

| Parâmetro | Tipo | Descrição |
|---|---|---|
| `limit` | int | Quantos registros devolver. Padrão 50, máximo 500 |
| `offset` | int | Quantos registros pular (paginação). Padrão 0 |
| `usuario_id` | int | Só acessos desse usuário |
| `dispositivo_id` | int | Só acessos desse dispositivo |
| `resultado` | texto | `AUTORIZADO` ou `NEGADO` |
| `data_inicio` | data `AAAA-MM-DD` | A partir desse dia, inclusive |
| `data_fim` | data `AAAA-MM-DD` | Até o fim desse dia, inclusive |

O header **`X-Total-Count`** da resposta traz o total de registros que batem com os filtros (antes de `limit`/`offset`), para calcular o número de páginas.

Exemplo: `GET /acessos?resultado=NEGADO&data_inicio=2026-10-19&limit=20&offset=20`

**Resposta 200:**
```json
[
  {
    "id": 16,
    "usuario_id": null,
    "usuario_nome": null,
    "dispositivo_id": 1,
    "dispositivo_nome": "Porta Lab 1",
    "template_id_lido": 999,
    "data_hora": "2026-10-19T09:32:10.123456-03:00",
    "resultado": "NEGADO"
  },
  {
    "id": 15,
    "usuario_id": 1,
    "usuario_nome": "Ana Silva",
    "dispositivo_id": 1,
    "dispositivo_nome": "Porta Lab 1",
    "template_id_lido": 10,
    "data_hora": "2026-10-19T09:30:05.654321-03:00",
    "resultado": "AUTORIZADO"
  }
]
```
`data_hora` vem com o fuso horário (`-03:00`, horário de Brasília). Em Dart, `DateTime.parse` lê esse formato e converte corretamente.

**Erros:** `401` (sem token), `422` (parâmetro inválido, ex: `limit=0` ou `resultado=TESTE`).

---

## Códigos de erro

| Código | Quando acontece |
|---|---|
| `200` | Sucesso |
| `400` | Valor não permitido (ex: `PATCH /usuarios` com `nome` nulo) |
| `401` | Sem token, token inválido ou expirado (rotas de admin); usuário/senha errados (`/auth/login`); chave de API inválida (`POST /acessos`) |
| `404` | Recurso referenciado não existe (ex: `usuario_id` inválido, ou `id` na URL inexistente) |
| `409` | Conflito com um dado existente (e-mail de usuário ou `template_id` de digital já cadastrados) |
| `422` | Corpo ou parâmetros não batem com o formato esperado. O FastAPI valida isso automaticamente |
| `500` | Erro inesperado no servidor |

## Melhorias conhecidas, ainda não implementadas
- **Não há rota para alterar ou remover dispositivos** (ex: `PATCH /dispositivos/{id}` para desativar um). Hoje isso é feito direto no banco.
- Suporte a **vários sensores físicos** exigiria repensar a unicidade de `template_id` (hoje é única globalmente): passaria a ser única por dispositivo.
- Limite de tentativas no `POST /auth/login` (proteção contra tentativas repetidas de senha).
- HTTPS entre o ESP32 e a API (hoje o tráfego é HTTP na rede local).
- Migrações de banco com Alembic, quando o schema passar a mudar com frequência.
- Registro (log) das ações de administrador (quem criou, alterou ou removeu o quê).
