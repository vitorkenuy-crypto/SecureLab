/*
  SecureLab - ESP32 + sensor biométrico R307 (código-base para integração com a API)

  O que faz:
    1. Lê a digital no R307 e procura na memória do sensor (template_id).
    2. Envia { dispositivo_id, template_id_lido } para a API: POST /acessos com o header X-API-Key.
    3. A API decide. AUTORIZADO -> relé abre a fechadura + LED verde.
                     NEGADO     -> LED vermelho + buzzer.
    4. Cadastro de digitais pelo Monitor Serial (115200 baud):
         cadastrar 4   -> grava uma digital nova no sensor com o template 4
         apagar 4      -> apaga o template 4 da memória do sensor
         listar        -> mostra quantas digitais o sensor tem
       Depois de cadastrar no sensor, vincule o MESMO número ao usuário no app
       (Usuário > Biometria > Cadastrar, campo "Número do template").

  Bibliotecas (Arduino IDE > Ferramentas > Gerenciar Bibliotecas):
    - Adafruit Fingerprint Sensor Library
    - Adafruit SSD1306  (instala junto a Adafruit GFX)
  Placa: "ESP32 Dev Module" (pacote esp32 da Espressif).

  Ligações (slide "Arquitetura do Hardware"):
    R307 TX -> GPIO16 (RX2)     R307 RX -> GPIO17 (TX2)     R307 VCC -> 3.3V ou 5V (veja o modelo), GND -> GND
    OLED SDA -> GPIO21          OLED SCL -> GPIO22
    LED verde -> GPIO25         LED vermelho -> GPIO26      (cada um com resistor de 220 a 330 ohms)
    Buzzer -> GPIO27            Relé IN -> GPIO14
    Fechadura 12V: alimentada pela fonte 12V, passando pelo contato do relé (NUNCA pelo ESP32).
*/

#include <WiFi.h>
#include <HTTPClient.h>
#include <Wire.h>
#include <Adafruit_Fingerprint.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

// ================== CONFIGURE AQUI ==================
const char* WIFI_NOME  = "NOME_DA_REDE_WIFI";
const char* WIFI_SENHA = "SENHA_DA_REDE_WIFI";

// IP do PC onde o SecureLab está rodando (aparece na janela do RODAR/INICIAR_SECURELAB.bat).
// O PC e o ESP32 precisam estar na MESMA rede Wi-Fi.
const char* API_URL = "http://192.168.0.10:8000/acessos";

// Modo local: dispositivo 1 = Porta Lab 1 (chave-lab1), dispositivo 2 = Sala de Servidores (chave-servidores).
// Com a API "de verdade" (PostgreSQL), use a chave gerada no app (Ambientes > Gerar nova chave).
// Esta chave NÃO deve ir para o GitHub.
const char* API_KEY      = "chave-lab1";
const int   DISPOSITIVO_ID = 1;
// ====================================================

// Pinos
const int PINO_SENSOR_RX = 16;   // recebe do TX do R307
const int PINO_SENSOR_TX = 17;   // envia para o RX do R307
const int PINO_SDA       = 21;
const int PINO_SCL       = 22;
const int PINO_LED_VERDE = 25;
const int PINO_LED_VERM  = 26;
const int PINO_BUZZER    = 27;
const int PINO_RELE      = 14;

// Muitos módulos de relé acionam com nível BAIXO. Se a fechadura abrir ao ligar o ESP32, troque para false.
const bool RELE_ATIVO_EM_LOW = true;
const unsigned long TEMPO_PORTA_ABERTA_MS = 3000;

// Template enviado quando a digital não está na memória do sensor (a API registra como NEGADO).
const int TEMPLATE_DESCONHECIDO = -1;

HardwareSerial serialSensor(2);
Adafruit_Fingerprint sensor(&serialSensor);
Adafruit_SSD1306 tela(128, 64, &Wire, -1);
bool temTela = false;

// ---------------- Saídas ----------------

void rele(bool ligado) {
  digitalWrite(PINO_RELE, (ligado ^ RELE_ATIVO_EM_LOW) ? HIGH : LOW);
}

void mostrar(const String& linha1, const String& linha2 = "", const String& linha3 = "") {
  Serial.print(linha1);
  if (linha2.length()) { Serial.print(" | "); Serial.print(linha2); }
  if (linha3.length()) { Serial.print(" | "); Serial.print(linha3); }
  Serial.println();
  if (!temTela) return;
  tela.clearDisplay();
  tela.setTextColor(SSD1306_WHITE);
  tela.setTextSize(2);
  tela.setCursor(0, 0);
  tela.println("SecureLab");
  tela.setTextSize(1);
  tela.setCursor(0, 24);
  tela.println(linha1);
  tela.setCursor(0, 38);
  tela.println(linha2);
  tela.setCursor(0, 52);
  tela.println(linha3);
  tela.display();
}

void bip(int vezes, int duracaoMs) {
  for (int i = 0; i < vezes; i++) {
    digitalWrite(PINO_BUZZER, HIGH);
    delay(duracaoMs);
    digitalWrite(PINO_BUZZER, LOW);
    delay(duracaoMs);
  }
}

void acessoAutorizado() {
  mostrar("ACESSO", "AUTORIZADO");
  digitalWrite(PINO_LED_VERDE, HIGH);
  rele(true);
  bip(1, 80);
  delay(TEMPO_PORTA_ABERTA_MS);
  rele(false);
  digitalWrite(PINO_LED_VERDE, LOW);
}

void acessoNegado(const String& motivo) {
  mostrar("ACESSO NEGADO", motivo);
  digitalWrite(PINO_LED_VERM, HIGH);
  bip(3, 150);
  delay(1200);
  digitalWrite(PINO_LED_VERM, LOW);
}

// ---------------- Wi-Fi e API ----------------

void conectarWifi() {
  if (WiFi.status() == WL_CONNECTED) return;
  mostrar("Conectando Wi-Fi", WIFI_NOME);
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_NOME, WIFI_SENHA);
  unsigned long inicio = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - inicio < 15000) {
    delay(300);
  }
  if (WiFi.status() == WL_CONNECTED) {
    mostrar("Wi-Fi conectado", WiFi.localIP().toString());
    delay(800);
  } else {
    mostrar("Sem Wi-Fi", "confira nome/senha");
    delay(1500);
  }
}

// Envia a leitura para a API. A decisão é sempre da API; sem resposta, a porta fica fechada.
void enviarLeitura(int templateId) {
  conectarWifi();
  if (WiFi.status() != WL_CONNECTED) {
    acessoNegado("sem Wi-Fi");
    return;
  }

  mostrar("Validando...", "template " + String(templateId));
  HTTPClient http;
  http.setTimeout(5000);
  http.begin(API_URL);
  http.addHeader("Content-Type", "application/json");
  http.addHeader("X-API-Key", API_KEY);
  String corpo = "{\"dispositivo_id\":" + String(DISPOSITIVO_ID) +
                 ",\"template_id_lido\":" + String(templateId) + "}";
  int codigo = http.POST(corpo);
  String resposta = codigo > 0 ? http.getString() : "";
  http.end();

  Serial.printf("API -> HTTP %d %s\n", codigo, resposta.c_str());

  if (codigo == 200 && resposta.indexOf("\"AUTORIZADO\"") >= 0) {
    acessoAutorizado();
  } else if (codigo == 200) {
    acessoNegado(templateId == TEMPLATE_DESCONHECIDO ? "digital desconhecida" : "sem permissao");
  } else if (codigo == 401) {
    acessoNegado("chave/ID invalidos");
  } else if (codigo <= 0) {
    acessoNegado("API fora do ar");
  } else {
    acessoNegado("erro " + String(codigo));
  }
}

// ---------------- Sensor ----------------

// Espera um dedo e converte a imagem para o buffer indicado (1 ou 2). true se deu certo.
bool capturar(uint8_t buffer, unsigned long timeoutMs) {
  unsigned long inicio = millis();
  while (millis() - inicio < timeoutMs) {
    uint8_t p = sensor.getImage();
    if (p == FINGERPRINT_OK) return sensor.image2Tz(buffer) == FINGERPRINT_OK;
    delay(50);
  }
  return false;
}

void esperarTirarDedo() {
  while (sensor.getImage() != FINGERPRINT_NOFINGER) delay(50);
}

void cadastrar(int id) {
  if (id < 1 || id > 1000) {
    Serial.println("Use um numero de 1 a 1000 (ex.: cadastrar 4)");
    return;
  }
  mostrar("Cadastro #" + String(id), "Coloque o dedo");
  if (!capturar(1, 15000)) { mostrar("Cadastro falhou", "dedo nao lido"); bip(3, 150); return; }
  mostrar("Cadastro #" + String(id), "Retire o dedo");
  bip(1, 60);
  delay(800);
  esperarTirarDedo();
  mostrar("Cadastro #" + String(id), "Coloque de novo");
  if (!capturar(2, 15000)) { mostrar("Cadastro falhou", "2a leitura"); bip(3, 150); return; }
  if (sensor.createModel() != FINGERPRINT_OK) { mostrar("Cadastro falhou", "digitais diferentes"); bip(3, 150); return; }
  if (sensor.storeModel(id) != FINGERPRINT_OK) { mostrar("Cadastro falhou", "erro ao gravar"); bip(3, 150); return; }
  mostrar("Digital gravada", "template #" + String(id), "vincule no app");
  bip(2, 80);
  esperarTirarDedo();
  delay(1500);
}

void lerComandoSerial() {
  if (!Serial.available()) return;
  String cmd = Serial.readStringUntil('\n');
  cmd.trim();
  cmd.toLowerCase();
  if (cmd.startsWith("cadastrar")) {
    cadastrar(cmd.substring(9).toInt());
  } else if (cmd.startsWith("apagar")) {
    int id = cmd.substring(6).toInt();
    bool ok = sensor.deleteModel(id) == FINGERPRINT_OK;
    mostrar(ok ? "Template apagado" : "Falha ao apagar", "#" + String(id));
  } else if (cmd == "listar") {
    sensor.getTemplateCount();
    mostrar("Digitais no sensor:", String(sensor.templateCount));
  } else if (cmd.length()) {
    Serial.println("Comandos: cadastrar N | apagar N | listar");
  }
}

// ---------------- Arduino ----------------

void setup() {
  Serial.begin(115200);
  pinMode(PINO_LED_VERDE, OUTPUT);
  pinMode(PINO_LED_VERM, OUTPUT);
  pinMode(PINO_BUZZER, OUTPUT);
  pinMode(PINO_RELE, OUTPUT);
  rele(false);

  Wire.begin(PINO_SDA, PINO_SCL);
  temTela = tela.begin(SSD1306_SWITCHCAPVCC, 0x3C);
  if (!temTela) Serial.println("OLED nao encontrado (seguindo sem tela)");

  serialSensor.begin(57600, SERIAL_8N1, PINO_SENSOR_RX, PINO_SENSOR_TX);
  delay(100);
  if (sensor.verifyPassword()) {
    mostrar("Sensor R307 OK");
  } else {
    mostrar("R307 nao responde", "confira TX/RX");
    bip(5, 100);
  }

  conectarWifi();
  mostrar("Aproxime sua", "digital");
  Serial.println("Comandos no Monitor Serial: cadastrar N | apagar N | listar");
}

void loop() {
  lerComandoSerial();

  uint8_t p = sensor.getImage();
  if (p != FINGERPRINT_OK) {   // sem dedo (ou leitura ruim): tenta de novo
    delay(60);
    return;
  }
  if (sensor.image2Tz(1) != FINGERPRINT_OK) {
    mostrar("Leitura ruim", "tente de novo");
    delay(800);
    mostrar("Aproxime sua", "digital");
    return;
  }

  int templateId = TEMPLATE_DESCONHECIDO;
  if (sensor.fingerFastSearch() == FINGERPRINT_OK) {
    templateId = sensor.fingerID;
    Serial.printf("Digital encontrada: template %d (confianca %d)\n", templateId, sensor.confidence);
  } else {
    Serial.println("Digital nao esta na memoria do sensor");
  }

  enviarLeitura(templateId);
  esperarTirarDedo();
  mostrar("Aproxime sua", "digital");
}
