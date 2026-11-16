#ifndef API_H
#define API_H

#include <Arduino.h>

enum class ResultadoAcesso {
    AUTORIZADO,
    NEGADO,
    ERRO_COMUNICACAO
};

bool conectarWiFi();

bool wifiConectado();

ResultadoAcesso consultarAcesso(
    uint16_t templateId
);

#endif