#include <Arduino.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>

#include "api.h"
#include "config.h"

bool conectarWiFi() {
    Serial.println("[WIFI] Conectando...");

    WiFi.mode(WIFI_STA);
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

    unsigned long inicio = millis();

    while (WiFi.status() != WL_CONNECTED &&
           millis() - inicio < 15000) {
        delay(500);
        Serial.print(".");
    }

    if (WiFi.status() == WL_CONNECTED) {
        Serial.println();
        Serial.println("[WIFI] Conectado!");
        Serial.print("[WIFI] IP do ESP32: ");
        Serial.println(WiFi.localIP());
        return true;
    }

    Serial.println();
    Serial.println("[WIFI] Falha na conexao.");
    return false;
}

bool wifiConectado() {
    return WiFi.status() == WL_CONNECTED;
}

ResultadoAcesso consultarAcesso(uint16_t templateId) {

    if (!wifiConectado()) {
        Serial.println("[API] Wi-Fi desconectado.");
        return ResultadoAcesso::ERRO_COMUNICACAO;
    }

    HTTPClient http;

    String url = String(API_URL) + "/acessos";

    http.begin(url);
    http.setTimeout(5000);

    http.addHeader("Content-Type", "application/json");
    http.addHeader("X-API-Key", API_KEY);

    JsonDocument documento;

    documento["dispositivo_id"] = DISPOSITIVO_ID;
    documento["template_id_lido"] = templateId;

    String corpo;
    serializeJson(documento, corpo);

    Serial.println("[API] Enviando requisicao...");
    Serial.println(corpo);

    int codigoHTTP = http.POST(corpo);

    if (codigoHTTP <= 0) {
        Serial.print("[API] Erro HTTP: ");
        Serial.println(http.errorToString(codigoHTTP));

        http.end();
        return ResultadoAcesso::ERRO_COMUNICACAO;
    }

    Serial.print("[API] Status HTTP: ");
    Serial.println(codigoHTTP);

    String resposta = http.getString();

    Serial.print("[API] Resposta: ");
    Serial.println(resposta);

    http.end();

    if (codigoHTTP != 200) {
        return ResultadoAcesso::ERRO_COMUNICACAO;
    }

    JsonDocument retorno;

    DeserializationError erro =
        deserializeJson(retorno, resposta);

    if (erro) {
        Serial.println("[API] JSON invalido.");
        return ResultadoAcesso::ERRO_COMUNICACAO;
    }

    const char* resultado = retorno["resultado"];

    if (resultado == nullptr) {
        Serial.println("[API] Campo resultado ausente.");
        return ResultadoAcesso::ERRO_COMUNICACAO;
    }

    if (strcmp(resultado, "AUTORIZADO") == 0) {
        return ResultadoAcesso::AUTORIZADO;
    }

    if (strcmp(resultado, "NEGADO") == 0) {
        return ResultadoAcesso::NEGADO;
    }

    return ResultadoAcesso::ERRO_COMUNICACAO;
}