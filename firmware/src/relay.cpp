
#include <Arduino.h>
#include "relay.h"

const int RELE_PIN = 23;

// Modulo testado: acionamento em nivel LOW.
const int RELE_LIGADO = LOW;
const int RELE_DESLIGADO = HIGH;

void inicializarRele() {
    pinMode(RELE_PIN, OUTPUT);

    // Mantem o rele desligado durante a inicializacao.
    digitalWrite(RELE_PIN, RELE_DESLIGADO);

    Serial.println("[RELE] Inicializado e desligado");
}

void abrirPorta() {
    digitalWrite(RELE_PIN, RELE_LIGADO);
    Serial.println("[RELE] Acionado: comando de abertura");
}

void fecharPorta() {
    digitalWrite(RELE_PIN, RELE_DESLIGADO);
    Serial.println("[RELE] Desligado: fim do acionamento");
}
