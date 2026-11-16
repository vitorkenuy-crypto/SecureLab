#include <Arduino.h>
#include <Adafruit_Fingerprint.h>

#include "display.h"
#include "led.h"
#include "api.h"
#include "buzzer.h"
#include "relay.h"
#include "state_machine.h"

const int SENSOR_RX = 13;
const int SENSOR_TX = 14;

Adafruit_Fingerprint sensor = Adafruit_Fingerprint(&Serial2);

bool sensorConectado = false;
unsigned long ultimaTentativaSensor = 0;
bool aguardarRetiradaParaNovaLeitura = false;

bool capturarDigital() {
    Serial.println("Aproxime o dedo...");
    mostrarMensagem("Aproxime o dedo");

    unsigned long inicio = millis();

    while (millis() - inicio < 30000) {
        uint8_t resultado = sensor.getImage();

        if (resultado == FINGERPRINT_OK) {
            Serial.println("[OK] Digital capturada!");
            return true;
        }

        if (resultado != FINGERPRINT_NOFINGER) {
            Serial.print("[ERRO] Captura: ");
            Serial.println(resultado);
            return false;
        }

        delay(100);
    }

    Serial.println("[ERRO] Tempo esgotado.");
    return false;
}

bool aguardarRetirada() {
    Serial.println("Retire o dedo...");
    unsigned long inicio = millis();

    while (millis() - inicio < 15000) {
        if (sensor.getImage() == FINGERPRINT_NOFINGER) {
            delay(300);
            return true;
        }

        delay(100);
    }

    Serial.println("[AVISO] Tempo para retirar o dedo esgotado.");
    return false;
}

void cadastrarDigital(uint16_t id) {
    if (id < 1 || id > 127) {
        Serial.println("[ERRO] ID deve estar entre 1 e 127.");
        return;
    }

    Serial.print("Cadastro do ID ");
    Serial.println(id);

    if (!capturarDigital()) {
        mostrarMensagem("Falha na captura");
        return;
    }

    uint8_t resultado = sensor.image2Tz(1);

    if (resultado != FINGERPRINT_OK) {
        Serial.println("[ERRO] Falha ao processar primeira imagem.");
        mostrarMensagem("Erro na imagem");
        return;
    }

    if (!aguardarRetirada()) {
        mostrarMensagem("Tente novamente");
        return;
    }

    Serial.println("Coloque o mesmo dedo novamente.");

    if (!capturarDigital()) {
        mostrarMensagem("Falha na captura");
        return;
    }

    resultado = sensor.image2Tz(2);

    if (resultado != FINGERPRINT_OK) {
        Serial.println("[ERRO] Falha ao processar segunda imagem.");
        mostrarMensagem("Erro na imagem");
        return;
    }

    resultado = sensor.createModel();

    if (resultado != FINGERPRINT_OK) {
        Serial.println("[ERRO] As capturas nao coincidiram.");
        mostrarMensagem("Digital diferente");
        ledLeituraErro();
        sinalizarLeituraErro();
        ledAguardando();
        return;
    }

    resultado = sensor.storeModel(id);

    if (resultado == FINGERPRINT_OK) {
        Serial.println("[OK] Digital cadastrada!");
        Serial.print("ID salvo: ");
        Serial.println(id);

        mostrarMensagem("Cadastro concluido");
        ledLeituraOk();
        sinalizarLeituraOk();
        delay(700);
        ledAguardando();
    } else {
        Serial.print("[ERRO] Falha ao salvar: ");
        Serial.println(resultado);
        mostrarMensagem("Erro ao salvar");
    }
}

void processarDigital() {
    uint8_t resultado = sensor.image2Tz(1);

    if (resultado != FINGERPRINT_OK) {
        Serial.println("[ERRO] Nao foi possivel processar a imagem.");
        mudarEstado(EstadoSistema::ERRO_BIOMETRIA);
        return;
    }

    Serial.println("[BIOMETRIA] Buscando digital...");
    resultado = sensor.fingerFastSearch();

    if (resultado == FINGERPRINT_OK) {
        uint16_t id = sensor.fingerID;

        Serial.print("[BIOMETRIA] ID encontrado: ");
        Serial.println(id);

        Serial.print("[BIOMETRIA] Confianca: ");
        Serial.println(sensor.confidence);

        // Encontrar uma digital nao significa autorizar o acesso.
        mudarEstado(EstadoSistema::IDENTIFICANDO_DIGITAL);

        mudarEstado(EstadoSistema::CONSULTANDO_API);

        ResultadoAcesso resultadoAPI = consultarAcesso(id);

        switch (resultadoAPI) {

            case ResultadoAcesso::AUTORIZADO:
                Serial.println("[ACESSO] AUTORIZADO PELA API");
                mudarEstado(EstadoSistema::ACESSO_AUTORIZADO);
                break;

            case ResultadoAcesso::NEGADO:
                Serial.println("[ACESSO] NEGADO PELA API");
                mudarEstado(EstadoSistema::ACESSO_NEGADO);
                break;

            case ResultadoAcesso::ERRO_COMUNICACAO:
                Serial.println("[ACESSO] ERRO DE COMUNICACAO COM A API");
                mudarEstado(EstadoSistema::ERRO_API);
                break;
        }
    } else if (resultado == FINGERPRINT_NOTFOUND) {
        Serial.println("[ACESSO] NEGADO: digital nao cadastrada.");
        mudarEstado(EstadoSistema::ACESSO_NEGADO);

    } else {
        Serial.print("[ERRO] Busca biometrica: ");
        Serial.println(resultado);
        mudarEstado(EstadoSistema::ERRO_BIOMETRIA);
    }
}

void mostrarMenu() {
    Serial.println();
    Serial.println("======= SECURELAB =======");
    Serial.println("C - Cadastrar digital");
    Serial.println("Reconhecimento automatico ativo");
    Serial.println("=========================");
}

void setup() {
    Serial.begin(115200);
    delay(500);

    Serial.println();
    Serial.println("=== SECURELAB ===");

    inicializarDisplay();
    inicializarLEDs();
    inicializarBuzzer();

    // Inicializa o rele desligado; nao sera acionado neste teste.
    inicializarRele();

    inicializarMaquinaEstados();
    mudarEstado(EstadoSistema::CONECTANDO_WIFI);
    bool wifiOK = conectarWiFi();

    Serial2.begin(
        57600,
        SERIAL_8N1,
        SENSOR_RX,
        SENSOR_TX
    );

    sensor.begin(57600);

    if (sensor.verifyPassword()) {
    sensorConectado = true;
    Serial.println("[OK] R307S conectado!");
    } else {
        Serial.println("[ERRO] Sensor nao respondeu.");
        mudarEstado(EstadoSistema::ERRO_BIOMETRIA);
    }

    if (wifiOK && sensorConectado) {
        mudarEstado(EstadoSistema::AGUARDANDO_DIGITAL);
    } else if (!wifiOK) {
        mudarEstado(EstadoSistema::ERRO_WIFI);
    }

    mostrarMenu();
}

void loop() {
    executarEstado();

    // Tenta reconectar ao sensor se ele nao respondeu na inicializacao.
    if (!sensorConectado) {
        if (millis() - ultimaTentativaSensor >= 2000) {
            ultimaTentativaSensor = millis();

            if (sensor.verifyPassword()) {
                sensorConectado = true;
                Serial.println("[OK] R307S reconectado!");
                mudarEstado(EstadoSistema::AGUARDANDO_DIGITAL);
            }
        }

        return;
    }

    // Cadastro manual pelo Monitor Serial.
    if (Serial.available() > 0) {
        char comando = Serial.read();

        if (comando == 'C' || comando == 'c') {
            Serial.println("Digite o ID (1 a 127):");

            unsigned long inicio = millis();

            while (Serial.available() == 0 &&
                   millis() - inicio < 30000) {
                delay(10);
            }

            if (Serial.available() == 0) {
                Serial.println("[ERRO] Tempo esgotado.");
                return;
            }

            int id = Serial.parseInt();

            while (Serial.available() > 0) {
                Serial.read();
            }

            cadastrarDigital(id);
            mostrarMenu();
        }
    }

    // So procura digitais enquanto o sistema esta aguardando.
    if (obterEstadoAtual() != EstadoSistema::AGUARDANDO_DIGITAL) {
        return;
    }

    uint8_t resultado = sensor.getImage();

    // Impede processar o mesmo dedo repetidamente.
    if (aguardarRetiradaParaNovaLeitura) {
        if (resultado == FINGERPRINT_NOFINGER) {
            aguardarRetiradaParaNovaLeitura = false;
        }
        return;
    }

    if (resultado == FINGERPRINT_NOFINGER) {
        return;
    }

    if (resultado == FINGERPRINT_OK) {
        aguardarRetiradaParaNovaLeitura = true;

        Serial.println("[BIOMETRIA] Digital detectada!");
        mudarEstado(EstadoSistema::IDENTIFICANDO_DIGITAL);
        processarDigital();
        
    } else {
        Serial.print("[ERRO] Leitura: ");
        Serial.println(resultado);
        mudarEstado(EstadoSistema::ERRO_BIOMETRIA);
    }
}
