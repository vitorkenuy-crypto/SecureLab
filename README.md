# SecureLab - Sistema Inteligente de Controle de Acesso Biométrico

[![Status do Projeto](https://img.shields.io/badge/Status-Em%20Desenvolvimento%20(MVP)-yellow)](#)
[![Estrutura](https://img.shields.io/badge/Arquitetura-Monorepo-blue)](#)
[![Hardware](https://img.shields.io/badge/Hardware-ESP32%20%7C%20R307-green)](#)
[![Backend](https://img.shields.io/badge/Backend-FastAPI%20%7C%20PostgreSQL-darkblue)](#)
[![Mobile](https://img.shields.io/badge/Mobile-Flutter-02569B)](#)

O **SecureLab** é uma solução completa de controle de acesso físico e digital desenvolvida no âmbito do Projeto Integrador do curso de Sistemas de Informação. O sistema integra hardware embarcado (**ESP32** e sensor biométrico óptico **R307/R307S**), atuadores de acionamento (módulo relé e fechadura solenoide 12V), uma API RESTful de alta performance em **FastAPI**, persistência e auditoria em banco de dados relacional **PostgreSQL**, e uma interface administrativa mobile em **Flutter**.

---

## Objetivo do Projeto

Construir uma arquitetura integrada de ponta a ponta que elimine o uso de chaves físicas e cadastros descentralizados, garantindo que o acesso a ambientes controlados ocorra por meio de biometria validada em tempo real, com registro auditável de todas as tentativas (autorizadas ou negadas) e gestão centralizada via aplicativo mobile.

---

## Fluxo de Funcionamento e Lógica de Acesso

[ Usuário ] ──(Posiciona Digital)──► [ Sensor R307 ]
│
(UART / Serial)
▼
[ ESP32 Node ]
│
(HTTP POST / Wi-Fi)
▼
[ API REST (FastAPI) ]
│
(Consulta SQL)
▼
[ Banco PostgreSQL ]
│
┌────────────────────────────┴────────────────────────────┐
▼                                                         ▼
[ Retorno: AUTORIZADO ]                                   [ Retorno: NEGADO ]
│                                                         │
┌────────────┴────────────┐                               ┌────────────┴────────────┐
▼                         ▼                               ▼                         ▼
[ Relé / Fechadura 12V ]  [ OLED / LED Verde ]          [ LED Vermelho ]          [ Buzzer ]
(Pulso de Abertura)      (Mensagem de Boas-vindas)      (Feedback Visual)        (Alarme Sonoro)
│                                                         │
└────────────────────────────┬────────────────────────────┘
▼
[ Gravação do Log na Tabela ACESSO ]
▲
│ (Consulta / Gestão)
[ Aplicativo Flutter ]

### Regras de Negócio Fundamentais
1. **Autorização Positiva:** Ocorre apenas se o `template_id` da digital for reconhecido localmente no R307 e o backend confirmar que o usuário correspondente possui status `ativo = true`.
2. **Negação por Usuário Inativo:** Se a digital for reconhecida mas o usuário estiver inativo no banco, a fechadura permanece bloqueada e a tentativa é registrada como `NEGADO_INATIVO`.
3. **Negação por Não Reconhecimento:** Se a digital não constar na base biométrica, o ESP32 emite alertas visuais/sonoros e envia o evento de falha como `NEGADO_DESCONHECIDO`.
4. **Auditoria Obrigatória:** Toda e qualquer tentativa de acesso gera um registro imutável com carimbo de data/hora, identificador do dispositivo e status.
5. **Rastreabilidade de Dispositivos:** Cada ponto de acesso físico (ESP32) possui uma identificação única (`dispositivo_id`), permitindo identificar com precisão a porta ou laboratório acionado.

---

## 🛠️ Stack Tecnológica e Hardware

### 1. Hardware e Eletrônica
* **Microcontrolador:** ESP32 DevKit v1 (30 pinos, Wi-Fi integrado 2.4 GHz).
* **Sensor Biométrico:** R307 / R307S (comunicação serial UART com armazenamento de templates).
* **Atuação:** Módulo Relé 5V (com isolamento optoacoplado) acionando Fechadura Solenoide 12V DC.
* **Alimentação:** Fonte Chaveada AC/DC 12V 2A (alimentação da fechadura) e barramento USB 5V (ESP32/sensores).
* **Interface Física:** Display OLED 0.96" I2C (SSD1306), LEDs de sinalização (Verde/Vermelho), Buzzer ativo 5V e Push Button para abertura interna.

### 2. Software e Frameworks
* **Firmware:** C/C++ utilizando PlatformIO no VS Code sobre o framework Arduino-ESP32.
* **Backend:** Python 3.11+ utilizando FastAPI, Pydantic e SQLAlchemy.
* **Banco de Dados:** PostgreSQL 15+.
* **Mobile:** Flutter SDK / Dart (gerenciamento de estado, consumo de API REST).
* **Gestão e Versionamento:** Git/GitHub (Monorepo com Feature-Branch Workflow) e Trello.

---

## 📂 Estrutura do Repositório (Monorepo)

O projeto está centralizado em um único repositório para garantir consistência de versões e testes integrados contínuos:

```text
securelab/
│
├── .github/                       # Modelos de Pull Requests e Issues
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md
│   │   └── feature_request.md
│   └── pull_request_template.md
│
├── firmware/                      # Código C++ do ESP32 (PlatformIO)
│   ├── include/                   # Cabeçalhos (.h) e definições de pinagem
│   ├── src/                       # Lógica de controle, UART, Wi-Fi e HTTP (.cpp)
│   │   └── main.cpp
│   ├── platformio.ini             # Dependências de bibliotecas e parâmetros de build
│   └── README.md                  # Instruções de compilação, upload e pinout
│
├── backend/                       # API REST FastAPI
│   ├── app/
│   │   ├── api/                   # Rotas e controladores REST (v1)
│   │   ├── core/                  # Configurações de ambiente, segurança e CORS
│   │   ├── models/                # Modelos de entidades ORM (SQLAlchemy)
│   │   ├── schemas/               # Schemas de validação e serialização (Pydantic)
│   │   ├── services/              # Regras de negócio e validação de acessos
│   │   └── main.py                # Ponto de inicialização do servidor
│   ├── tests/                     # Testes de integração e unidade (pytest)
│   ├── requirements.txt           # Dependências Python
│   ├── Dockerfile                 # Containerização da aplicação
│   └── README.md                  # Guia de execução local e variáveis de ambiente
│
├── database/                      # Modelagem e persistência PostgreSQL
│   ├── migrations/                # Versionamento de schema
│   ├── seeds/                     # Dados iniciais para testes de laboratório
│   ├── schema.sql                 # DDL completo das tabelas
│   └── README.md                  # Diagrama Entidade-Relacionamento (DER) e dicionário
│
├── mobile/                        # Aplicativo administrativo em Flutter
│   ├── lib/
│   │   ├── core/                  # Rotas, temas e configurações de rede
│   │   ├── models/                # Classes de dados serializadas
│   │   ├── screens/               # Telas (Dashboard, Histórico de Acessos, Usuários)
│   │   ├── services/              # Clientes de integração HTTP com o backend
│   │   └── main.dart              # Ponto de entrada do app
│   ├── pubspec.yaml               # Dependências do ecossistema Flutter
│   └── README.md                  # Instruções para compilação e execução mobile
│
├── docs/                          # Documentação técnica centralizada
│   ├── arquitetura/               # Diagramas de blocos e fluxogramas
│   ├── hardware/                  # Tabela de pinagem oficial, esquemático elétrico e BOM
│   ├── api/                       # Contratos de payloads e especificação OpenAPI
│   └── regras_negocio.md          # Regras formais e critérios de segurança
│
├── .gitignore                     # Exclusões unificadas (.pio, .venv, build, .env)
├── docker-compose.yml             # Orquestração local de PostgreSQL e FastAPI
└── README.md                      # Documento principal de apresentação
