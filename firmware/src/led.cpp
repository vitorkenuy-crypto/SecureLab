
#include <Arduino.h>
#include "led.h"

const int LED_VERDE_PIN = 27;
const int LED_VERMELHO_PIN = 25;

void inicializarLEDs() {
    pinMode(LED_VERDE_PIN, OUTPUT);
    pinMode(LED_VERMELHO_PIN, OUTPUT);
    ledAguardando();
}

void ledAguardando() {
    digitalWrite(LED_VERDE_PIN, LOW);
    digitalWrite(LED_VERMELHO_PIN, LOW);
}

void ledAutorizado() {
    digitalWrite(LED_VERMELHO_PIN, LOW);
    digitalWrite(LED_VERDE_PIN, HIGH);
}

void ledNegado() {
    digitalWrite(LED_VERDE_PIN, LOW);
    digitalWrite(LED_VERMELHO_PIN, HIGH);
}

void ledLeituraOk() {
    ledAutorizado();
}

void ledLeituraErro() {
    ledNegado();
}
