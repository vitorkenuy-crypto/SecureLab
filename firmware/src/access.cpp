#include <Arduino.h>
#include "access.h"
#include "display.h"
#include "buzzer.h"
#include "led.h"
#include "relay.h"

void processarAcesso(EstadoAcesso estado) {

    if (estado == EstadoAcesso::AUTORIZADO) {

        Serial.println("[ACESSO] Autorizado");

        mostrarMensagem("Acesso autorizado");
        sinalizarAutorizado();
        ledAutorizado();
        abrirPorta();

    } else {

        Serial.println("[ACESSO] Negado");

        mostrarMensagem("Acesso negado");
        sinalizarNegado();
        ledNegado();

    }
}