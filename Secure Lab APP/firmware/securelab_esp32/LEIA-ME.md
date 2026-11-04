# ESP32 + R307 ligado ao SecureLab (para o Vitor)

Código-base em `securelab_esp32.ino`, que já conversa com a API do SecureLab. O ESP32 só lê a digital e pergunta para a API, e quem decide se libera é sempre a API. Ainda não foi compilado nem testado no hardware: é o ponto de partida para você ajustar.

## 1. Preparar o Arduino IDE

1. **Arquivo > Preferências > URLs adicionais**: `https://espressif.github.io/arduino-esp32/package_esp32_index.json`
2. **Ferramentas > Placa > Gerenciador de Placas**: instale **esp32** (Espressif).
3. **Ferramentas > Gerenciar Bibliotecas**: instale **Adafruit Fingerprint Sensor Library** e **Adafruit SSD1306** (aceite instalar a Adafruit GFX junto).
4. Placa: **ESP32 Dev Module**.

## 2. Ligações (as mesmas do slide de arquitetura)

| Peça | Pino da peça | ESP32 |
| --- | --- | --- |
| R307 | TX | GPIO16 |
| R307 | RX | GPIO17 |
| OLED 0,96" | SDA / SCL | GPIO21 / GPIO22 |
| LED verde (com resistor) | + | GPIO25 |
| LED vermelho (com resistor) | + | GPIO26 |
| Buzzer | + | GPIO27 |
| Relé | IN | GPIO14 |
| Fechadura 12 V | | fonte 12 V passando pelo contato do relé, **nunca** pelo ESP32 |

Se a fechadura abrir sozinha quando o ESP32 liga, troque `RELE_ATIVO_EM_LOW` para `false`.

## 3. Configurar (topo do arquivo)

```cpp
const char* WIFI_NOME  = "nome da rede";
const char* WIFI_SENHA = "senha";
const char* API_URL    = "http://IP-DO-PC:8000/acessos";
const char* API_KEY    = "chave-lab1";
const int   DISPOSITIVO_ID = 1;
```

- **O IP do PC** aparece na janela preta do `RODAR_SECURELAB.bat`, na linha "API para o ESP32".
- **O PC e o ESP32 precisam estar no mesmo Wi-Fi.** Na primeira vez, o Windows pergunta sobre o Firewall: marque *Redes privadas* e clique em *Permitir*.
- Na rede da faculdade os aparelhos podem estar isolados entre si; se não conectar, use o roteador do celular.
- **Chaves no modo de teste:** `chave-lab1` (dispositivo 1) e `chave-servidores` (dispositivo 2).

## 4. Testar

1. No PC, dê dois cliques em `RODAR_SECURELAB.bat`.
2. Grave o sketch no ESP32 e abra o **Monitor Serial a 115200 baud**.
3. A tela deve mostrar "Sensor R307 OK", "Wi-Fi conectado" e "Aproxime sua digital".

### Cadastrar uma digital

1. No Monitor Serial, digite `cadastrar 4` e aperte Enter.
2. Coloque o dedo, tire e coloque de novo. O sensor grava o template 4.
3. No app, abra o usuário e use **Cadastrar** na parte de biometria, com o número **4**.
4. Encoste o dedo: a fechadura abre, o LED verde acende e o acesso aparece no Histórico.

Outros comandos do Monitor Serial: `apagar 4` e `listar`.

### O que o ESP32 manda e recebe

- **Envia:** `POST /acessos` com o header `X-API-Key: chave-lab1` e o corpo `{"dispositivo_id": 1, "template_id_lido": 4}`.
- **Digital fora da memória do sensor:** envia `template_id_lido: -1`, e a API registra como NEGADO.
- **Resposta `"resultado": "AUTORIZADO"`:** relé ligado por 3 s, LED verde e 1 bip.
- **Qualquer outra resposta, ou falta de resposta:** fechadura continua trancada, LED vermelho e 3 bips.

O contrato completo está em `docs/api/api-securelab.md`.
