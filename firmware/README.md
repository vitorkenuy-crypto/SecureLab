# SecureLab — Firmware ESP32

## 1. Sobre o projeto

O **SecureLab** é um sistema inteligente de controle de acesso biométrico desenvolvido para ambientes educacionais, utilizando um microcontrolador ESP32, sensor de impressão digital R307S e uma API responsável pelo gerenciamento das autorizações.

O firmware é responsável pela comunicação com os componentes eletrônicos, identificação biométrica, comunicação com a API e execução das ações físicas de controle de acesso.

A decisão de autorizar ou negar a entrada é realizada pelo backend, e não pelo ESP32.

### Objetivos do firmware

- Inicializar e controlar os componentes eletrônicos.
- Realizar a leitura e identificação de impressões digitais.
- Conectar-se à rede Wi-Fi.
- Enviar solicitações de autorização para a API.
- Interpretar as respostas do backend.
- Controlar LEDs, display, buzzer e relé.
- Gerenciar o fluxo de funcionamento por meio de uma máquina de estados.

## 2. Tecnologias utilizadas

| Tecnologia | Finalidade |
|---|---|
| ESP32 | Microcontrolador principal |
| C++ | Linguagem de programação |
| Arduino Framework | Framework embarcado |
| PlatformIO | Gerenciamento, compilação e gravação do firmware |
| R307S | Identificação biométrica |
| OLED I2C | Interface visual |
| FastAPI | Comunicação com o backend |
| PostgreSQL | Persistência dos dados, acessada pela API |
| HTTP/JSON | Comunicação entre firmware e backend |

## 3. Componentes eletrônicos

O protótipo utiliza os seguintes componentes:

- ESP32 DevKit V1.
- Sensor biométrico R307S.
- Display OLED I2C.
- LED verde para indicação de acesso autorizado.
- LED vermelho para indicação de acesso negado.
- Buzzer ativo para sinalização sonora.
- Módulo relé para controle da fechadura elétrica.
- Fechadura solenoide de 12 V.
- Fonte de alimentação adequada aos componentes.

## 4. Mapeamento dos pinos

O mapeamento abaixo representa a configuração utilizada no firmware documentado.

| Componente | Pino ESP32 | Função |
|---|---|---|
| LED verde | GPIO 27 | Sinalização de autorização |
| LED vermelho | GPIO 25 | Sinalização de acesso negado |
| Buzzer | GPIO 26 | Sinalização sonora |
| OLED SDA | GPIO 21 | Comunicação I2C |
| OLED SCL | GPIO 22 | Comunicação I2C |
| Relé | GPIO 23 | Controle da fechadura |
| R307S TX | GPIO 13 | Recepção serial pelo ESP32 |
| R307S RX | GPIO 14 | Transmissão serial pelo ESP32 |

**Observação:** o TX do sensor deve ser conectado ao RX do ESP32, e o RX do sensor ao TX do ESP32.

Os LEDs utilizam resistores em série. A alimentação da fechadura deve ser independente da alimentação lógica do ESP32, com o relé realizando a comutação da carga.

## 5. Estrutura do projeto

```text
firmware/
│
├── include/
│   └── config.h
│
├── src/
│   ├── main.cpp
│   │
│   ├── api.cpp
│   ├── api.h
│   │
│   ├── access.cpp
│   ├── access.h
│   │
│   ├── display.cpp
│   ├── display.h
│   │
│   ├── led.cpp
│   ├── led.h
│   │
│   ├── buzzer.cpp
│   ├── buzzer.h
│   │
│   ├── relay.cpp
│   ├── relay.h
│   │
│   ├── state.cpp
│   ├── state.h
│   │
│   ├── state_machine.cpp
│   └── state_machine.h
│
├── platformio.ini
├── .gitignore
└── README.md
```

### Responsabilidade dos módulos

| Arquivo | Responsabilidade |
|---|---|
| `main.cpp` | Inicialização e coordenação geral do firmware |
| `api.cpp / api.h` | Comunicação HTTP com o backend |
| `access.cpp / access.h` | Operações de identificação biométrica |
| `display.cpp / display.h` | Controle do display OLED |
| `led.cpp / led.h` | Controle dos LEDs |
| `buzzer.cpp / buzzer.h` | Controle do buzzer |
| `relay.cpp / relay.h` | Controle do módulo relé |
| `state.cpp / state.h` | Definição e gerenciamento dos estados |
| `state_machine.cpp / state_machine.h` | Transições e execução da máquina de estados |
| `config.h` | Configurações locais de rede e API |

## 6. Máquina de estados

O firmware utiliza uma máquina de estados para organizar o fluxo de execução.

Estados definidos no projeto:

| Estado | Descrição |
|---|---|
| `INICIALIZANDO` | Inicialização dos componentes |
| `CONECTANDO_WIFI` | Conexão com a rede Wi-Fi |
| `AGUARDANDO_DIGITAL` | Aguarda a aproximação do dedo |
| `IDENTIFICANDO_DIGITAL` | Realiza a identificação biométrica |
| `CONSULTANDO_API` | Envia a identificação ao backend |
| `ACESSO_AUTORIZADO` | Recebe autorização da API |
| `ACESSO_NEGADO` | Recebe negativa da API |
| `ABRINDO_PORTA` | Processo de acionamento da fechadura |
| `PORTA_ABERTA` | Indicação de porta aberta |
| `FECHANDO_PORTA` | Processo de fechamento |
| `ERRO_WIFI` | Falha na conexão Wi-Fi |
| `ERRO_BIOMETRIA` | Falha no sensor biométrico |
| `ERRO_API` | Falha na comunicação com o backend |

As transições são coordenadas pela máquina de estados, evitando concentrar toda a lógica de funcionamento no arquivo principal.

## 7. Comunicação com a API

O ESP32 se comunica com o backend por meio de requisições HTTP.

A API é responsável por verificar se:

- O usuário está ativo.
- A impressão digital está cadastrada.
- O dispositivo está ativo.

A regra de autorização é aplicada pelo backend.

### Endpoint utilizado

```http
POST /acessos
```

### Autenticação

A autenticação do dispositivo é realizada por meio do cabeçalho:

```http
X-API-Key: SUA_CHAVE_DE_API
```

### Corpo da requisição

```json
{
  "dispositivo_id": 3,
  "template_id_lido": 10
}
```

Onde:

- `dispositivo_id`: identificador do ESP32 cadastrado no sistema.
- `template_id_lido`: identificador da digital retornado pelo R307S.

### Resposta de autorização

```json
{
  "id": 15,
  "usuario_id": 1,
  "dispositivo_id": 3,
  "template_id_lido": 10,
  "resultado": "AUTORIZADO"
}
```

### Resposta de negativa

```json
{
  "resultado": "NEGADO"
}
```

A estrutura completa das respostas deve ser conferida na documentação da API.

## 8. Fluxo de funcionamento

1. O ESP32 é inicializado.
2. Os componentes eletrônicos são configurados.
3. O firmware estabelece conexão com a rede Wi-Fi.
4. O sensor R307S é inicializado.
5. O sistema aguarda a aproximação de uma impressão digital.
6. O sensor identifica a digital e retorna seu identificador.
7. O ESP32 envia o identificador para a API.
8. O backend consulta o banco PostgreSQL.
9. A API retorna o resultado da autorização.
10. O ESP32 interpreta a resposta e executa a ação correspondente.

### Acesso autorizado

- Acionamento da fechadura por meio do relé.
- Sinalização pelo LED verde.
- Atualização do display OLED.

### Acesso negado

- Fechadura permanece trancada.
- LED vermelho é acionado.
- Buzzer realiza a sinalização sonora.
- Display informa a negativa.

### Falha de comunicação

Caso a API esteja indisponível, ocorra timeout ou a resposta seja inválida, o firmware deve impedir a liberação do acesso.

**O sistema deve operar em modo fail-safe para o controle de autorização: nenhuma falha de comunicação pode resultar em liberação automática da fechadura.**

## 9. Configuração do ambiente

### Pré-requisitos

- Visual Studio Code.
- Extensão PlatformIO IDE.
- Driver USB da placa ESP32, quando necessário.
- Cabo USB com transmissão de dados.
- Python e PlatformIO CLI, caso a compilação seja realizada pelo terminal.

### Instalação das dependências

As bibliotecas utilizadas são gerenciadas pelo PlatformIO por meio do arquivo `platformio.ini`.

Exemplo de configuração:

```ini
[env:esp32dev]
platform = espressif32
board = esp32dev
framework = arduino
monitor_speed = 115200

lib_deps =
    adafruit/Adafruit GFX Library
    adafruit/Adafruit SSD1306
    adafruit/Adafruit Fingerprint Sensor Library
    bblanchon/ArduinoJson
```

### Compilação

Abra o terminal na pasta `firmware` e execute:

```powershell
python -m platformio run
```

### Upload para o ESP32

Conecte a placa pelo USB e execute:

```powershell
python -m platformio run --target upload
```

### Monitor Serial

Para acompanhar as mensagens de execução:

```powershell
python -m platformio device monitor --baud 115200
```

O monitor serial apresenta informações de inicialização, conexão Wi-Fi, identificação biométrica e comunicação com a API.

## 10. Configurações locais

As configurações de rede e autenticação devem ser mantidas localmente.

O arquivo `include/config.h` deve conter os parâmetros necessários:

```cpp
#ifndef CONFIG_H
#define CONFIG_H

#define WIFI_SSID "NOME_DA_REDE"
#define WIFI_PASSWORD "SENHA_DA_REDE"

#define API_URL "http://192.168.1.4:8000"
#define API_KEY "CHAVE_DO_DISPOSITIVO"

#define DISPOSITIVO_ID 3

#endif
```

Os valores apresentados são exemplos de configuração de desenvolvimento.

### Atenção à segurança

O arquivo `config.h` não deve ser enviado ao GitHub, pois contém credenciais e informações de autenticação.

O `.gitignore` deve conter:

```gitignore
.pio/
include/config.h
```

Cada desenvolvedor deve criar seu próprio arquivo de configuração local.

O IP da API deve corresponder ao endereço acessível pelo ESP32 na rede utilizada.

## 11. Executando a integração local

Para realizar os testes, o backend deve estar em execução no computador.

Inicie a API utilizando:

```powershell
uvicorn main:app --host 0.0.0.0 --port 8000
```

O endereço `0.0.0.0` permite que outros dispositivos da rede local, como o ESP32, acessem o servidor.

Exemplo:

```text
API:
http://192.168.1.4:8000

Documentação Swagger:
http://192.168.1.4:8000/docs
```

O computador e o ESP32 precisam estar conectados à mesma rede, e o Firewall deve permitir conexões de entrada na porta 8000.

## 12. Testes e validação

Os testes devem verificar individualmente os componentes e a integração completa.

| Teste | Resultado esperado |
|---|---|
| Inicialização do ESP32 | Componentes inicializados |
| Conexão Wi-Fi | Conexão estabelecida |
| Comunicação com R307S | Sensor reconhecido |
| Identificação biométrica | Retorno do ID da digital |
| Comunicação HTTP | Requisição recebida pela API |
| Digital cadastrada e usuário ativo | AUTORIZADO |
| Digital não vinculada ou usuário inativo | NEGADO |
| Dispositivo inativo | NEGADO |
| API indisponível | ERRO_API e acesso bloqueado |

As tentativas de acesso devem ser registradas pelo backend na tabela `acesso`.

## 13. Problemas comuns

### Connection refused

O ESP32 não conseguiu estabelecer conexão com a API.

Verificar:

- Se o backend está em execução.
- Se o Uvicorn foi iniciado com `--host 0.0.0.0`.
- Se o IP configurado no firmware está correto.
- Se o Firewall permite conexões na porta 8000.
- Se o ESP32 e o computador estão na mesma rede.

### HTTP 401

A chave de API do dispositivo pode estar incorreta, inválida ou ter sido substituída.

Verificar a chave cadastrada no backend.

### HTTP 200 com resultado NEGADO

A comunicação funcionou, mas a regra de autorização não foi satisfeita.

Verificar o cadastro do usuário, a digital e a situação do dispositivo.

### Erro na porta COM

A porta serial pode estar sendo utilizada por outro programa.

Fechar outros monitores seriais e verificar a porta no Gerenciador de Dispositivos do Windows.

### Erro de compilação

Verificar as dependências declaradas no `platformio.ini`, os arquivos de cabeçalho e a configuração do ambiente PlatformIO.

## 14. Segurança e boas práticas

- Não armazenar senhas ou chaves diretamente em arquivos versionados.
- Não permitir que o ESP32 decida sozinho sobre a autorização.
- Não liberar a fechadura em caso de falha de comunicação.
- Manter os módulos organizados por responsabilidade.
- Evitar bloqueios prolongados na execução da máquina de estados.
- Não transmitir imagens ou templates biométricos sem necessidade.
- Preservar a separação entre alimentação lógica e alimentação da fechadura.
- Validar todas as respostas recebidas da API.

## 15. Próximas etapas do desenvolvimento

- [X] Consolidar a integração entre firmware e backend.
- [X] Validar autorização e negativa com o sensor físico.
- [ ] Integrar o retorno da API ao acionamento do relé.
- [ ] Implementar o fluxo completo de abertura e fechamento da porta.
- [ ] Tratar reconexão Wi-Fi e indisponibilidade temporária da API.
- [ ] Melhorar o tratamento de erros e mensagens no OLED.
- [ ] Realizar testes de funcionamento contínuo.
- [ ] Preparar a montagem física definitiva do protótipo.

---

**SecureLab — Sistema Inteligente de Controle de Acesso**

Projeto Integrador — Sistemas de Informação.

Firmware desenvolvido em C++ para ESP32, integrado a um backend FastAPI e banco de dados PostgreSQL.
> Antes de compilar, copie `include/config.example.h` para
> `include/config.h` e preencha as credenciais locais. O arquivo
> `config.h` fica fora do Git por conter segredos.

