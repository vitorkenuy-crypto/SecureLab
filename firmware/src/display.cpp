#include <Arduino.h>
#include <Wire.h>

#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

#include "display.h"

#define SDA_PIN 21
#define SCL_PIN 22

#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64

#define OLED_RESET -1

#define OLED_ADDRESS 0x3C

Adafruit_SSD1306 display(
    SCREEN_WIDTH,
    SCREEN_HEIGHT,
    &Wire,
    OLED_RESET
);

void inicializarDisplay() {

    Wire.begin(SDA_PIN, SCL_PIN);

    if (!display.begin(
        SSD1306_SWITCHCAPVCC,
        OLED_ADDRESS
    )) {

        Serial.println("[DISPLAY] ERRO: OLED nao encontrado!");

        while (true) {
            delay(1000);
        }
    }

    Serial.println("[DISPLAY] OLED iniciado");

    display.clearDisplay();

    display.setTextColor(SSD1306_WHITE);
    display.setTextSize(1);

    display.setCursor(0, 0);

    display.println("SECURELAB");
    display.println();
    display.println("Inicializando...");

    display.display();
}

void mostrarMensagem(const char* mensagem) {

    display.clearDisplay();

    display.setTextColor(SSD1306_WHITE);
    display.setTextSize(1);

    display.setCursor(0, 0);

    display.println("SECURELAB");
    display.println();

    display.println(mensagem);

    display.display();

    Serial.print("[DISPLAY] ");
    Serial.println(mensagem);
}