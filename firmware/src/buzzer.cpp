
#include <Arduino.h>
#include "buzzer.h"

const int BUZZER_PIN = 26;

void inicializarBuzzer() {
    pinMode(BUZZER_PIN, OUTPUT);
    digitalWrite(BUZZER_PIN, LOW);
}

void sinalizarAutorizado() {
    digitalWrite(BUZZER_PIN, HIGH);
    delay(150);
    digitalWrite(BUZZER_PIN, LOW);
}

void sinalizarNegado() {
    for (int i = 0; i < 2; i++) {
        digitalWrite(BUZZER_PIN, HIGH);
        delay(150);
        digitalWrite(BUZZER_PIN, LOW);
        delay(100);
    }
}

void sinalizarLeituraOk() {
    sinalizarAutorizado();
}

void sinalizarLeituraErro() {
    sinalizarNegado();
}
