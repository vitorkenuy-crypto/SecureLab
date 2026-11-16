#include <Arduino.h>

#include "state_machine.h"
#include "display.h"
#include "led.h"
#include "buzzer.h"
#include "relay.h"

static EstadoSistema estadoAtual = EstadoSistema::INICIALIZANDO;

static unsigned long inicioEstado = 0;

void inicializarMaquinaEstados()
{

    estadoAtual = EstadoSistema::INICIALIZANDO;
    inicioEstado = millis();

    Serial.println("[STATE] Sistema inicializando");

    mostrarMensagem("SECURELAB");
}

const char *nomeEstado(EstadoSistema estado)
{

    switch (estado)
    {

    case EstadoSistema::INICIALIZANDO:
        return "INICIALIZANDO";

    case EstadoSistema::CONECTANDO_WIFI:
        return "CONECTANDO_WIFI";

    case EstadoSistema::AGUARDANDO_DIGITAL:
        return "AGUARDANDO_DIGITAL";

    case EstadoSistema::IDENTIFICANDO_DIGITAL:
        return "IDENTIFICANDO_DIGITAL";

    case EstadoSistema::CONSULTANDO_API:
        return "CONSULTANDO_API";

    case EstadoSistema::ACESSO_AUTORIZADO:
        return "ACESSO_AUTORIZADO";

    case EstadoSistema::ACESSO_NEGADO:
        return "ACESSO_NEGADO";

    case EstadoSistema::ABRINDO_PORTA:
        return "ABRINDO_PORTA";

    case EstadoSistema::PORTA_ABERTA:
        return "PORTA_ABERTA";

    case EstadoSistema::FECHANDO_PORTA:
        return "FECHANDO_PORTA";

    case EstadoSistema::ERRO_WIFI:
        return "ERRO_WIFI";

    case EstadoSistema::ERRO_BIOMETRIA:
        return "ERRO_BIOMETRIA";

    case EstadoSistema::ERRO_API:
        return "ERRO_API";

    default:
        return "DESCONHECIDO";
    }
}

void mudarEstado(EstadoSistema novoEstado)
{

    if (estadoAtual == novoEstado)
    {
        return;
    }

    Serial.print("[STATE] ");
    Serial.print(nomeEstado(estadoAtual));
    Serial.print(" -> ");
    Serial.println(nomeEstado(novoEstado));

    estadoAtual = novoEstado;

    inicioEstado = millis();

    /*
     * Ações executadas somente quando
     * entramos em um novo estado.
     */

    switch (estadoAtual)
    {

    case EstadoSistema::INICIALIZANDO:

        mostrarMensagem("Inicializando sistema...");
        break;

    case EstadoSistema::CONECTANDO_WIFI:

        mostrarMensagem("Conectando WiFi...");
        break;

    case EstadoSistema::AGUARDANDO_DIGITAL:

        mostrarMensagem("Aproxime sua digital");
        ledAguardando();
        break;

    case EstadoSistema::IDENTIFICANDO_DIGITAL:

        mostrarMensagem("Identificando...");
        break;

    case EstadoSistema::CONSULTANDO_API:

        mostrarMensagem("Consultando...");
        break;

    case EstadoSistema::ACESSO_AUTORIZADO:

        mostrarMensagem("Acesso autorizado");
        sinalizarAutorizado();
        ledAutorizado();
        break;

    case EstadoSistema::ACESSO_NEGADO:

        mostrarMensagem("Acesso negado");
        sinalizarNegado();
        ledNegado();
        break;

    case EstadoSistema::ABRINDO_PORTA:

        mostrarMensagem("Abrindo porta...");
        abrirPorta();
        break;

    case EstadoSistema::PORTA_ABERTA:

        mostrarMensagem("Porta aberta");
        break;

    case EstadoSistema::FECHANDO_PORTA:

        mostrarMensagem("Fechando porta...");
        fecharPorta();
        break;

    case EstadoSistema::ERRO_WIFI:

        mostrarMensagem("Erro WiFi");
        sinalizarNegado();
        break;

    case EstadoSistema::ERRO_BIOMETRIA:

        mostrarMensagem("Erro biometria");
        sinalizarNegado();
        break;

    case EstadoSistema::ERRO_API:

        mostrarMensagem("Erro API");
        sinalizarNegado();
        break;
    }
}

void executarEstado()
{

    unsigned long tempoNoEstado = millis() - inicioEstado;

    switch (estadoAtual)
    {

    case EstadoSistema::INICIALIZANDO:

        if (tempoNoEstado >= 2000)
        {

            mudarEstado(
                EstadoSistema::CONECTANDO_WIFI);
        }

        break;

    case EstadoSistema::CONECTANDO_WIFI:

        /*
         * Temporariamente vamos simular
         * a conexão WiFi.
         *
         * Depois substituiremos por:
         * WiFi.status()
         */

        if (tempoNoEstado >= 2000)
        {

            mudarEstado(
                EstadoSistema::AGUARDANDO_DIGITAL);
        }

        break;

    case EstadoSistema::AGUARDANDO_DIGITAL:

        /*
         * Futuramente:
         *
         * if (digitalDetectada()) {
         *
         *     mudarEstado(
         *         EstadoSistema::IDENTIFICANDO_DIGITAL
         *     );
         * }
         */

        break;

    case EstadoSistema::IDENTIFICANDO_DIGITAL:

        /*
         * Futuramente será o R307.
         */

        break;

    case EstadoSistema::CONSULTANDO_API:

        /*
         * Futuramente:
         *
         * chamada para FastAPI
         */

        break;

    case EstadoSistema::ACESSO_AUTORIZADO:

        // Exibe a autorização por 1 segundo
        // antes de liberar a fechadura.
        if (tempoNoEstado >= 1000)
        {
            mudarEstado(EstadoSistema::ABRINDO_PORTA);
        }

        break;

    case EstadoSistema::ACESSO_NEGADO:

        if (tempoNoEstado >= 2000)
        {

            mudarEstado(
                EstadoSistema::AGUARDANDO_DIGITAL);
        }

        break;

    case EstadoSistema::ABRINDO_PORTA:

        if (tempoNoEstado >= 500)
        {

            mudarEstado(
                EstadoSistema::PORTA_ABERTA);
        }

        break;

    case EstadoSistema::PORTA_ABERTA:

        /*
         * Futuramente podemos controlar
         * o tempo que a porta permanece aberta.
         */

        if (tempoNoEstado >= 5000)
        {

            mudarEstado(
                EstadoSistema::FECHANDO_PORTA);
        }

        break;

    case EstadoSistema::FECHANDO_PORTA:

        if (tempoNoEstado >= 500)
        {

            mudarEstado(
                EstadoSistema::AGUARDANDO_DIGITAL);
        }

        break;

    case EstadoSistema::ERRO_WIFI:

        break;

    case EstadoSistema::ERRO_BIOMETRIA:

        if (tempoNoEstado >= 2000)
        {

            mudarEstado(
                EstadoSistema::AGUARDANDO_DIGITAL);
        }

        break;

    case EstadoSistema::ERRO_API:

        if (tempoNoEstado >= 2000)
        {

            mudarEstado(
                EstadoSistema::AGUARDANDO_DIGITAL);
        }

        break;
    }
}

EstadoSistema obterEstadoAtual()
{

    return estadoAtual;
}

void simularResultadoAcesso(bool autorizado)
{

    // Só permite simular quando o sistema
    // estiver aguardando uma digital.
    if (estadoAtual != EstadoSistema::AGUARDANDO_DIGITAL)
    {
        Serial.println("[TESTE] Sistema nao esta aguardando digital.");
        return;
    }

    Serial.println("[TESTE] Digital detectada");

    mudarEstado(EstadoSistema::IDENTIFICANDO_DIGITAL);

    delay(600);

    mudarEstado(EstadoSistema::CONSULTANDO_API);

    delay(600);

    if (autorizado)
    {
        mudarEstado(EstadoSistema::ACESSO_AUTORIZADO);
    }
    else
    {
        mudarEstado(EstadoSistema::ACESSO_NEGADO);
    }
}