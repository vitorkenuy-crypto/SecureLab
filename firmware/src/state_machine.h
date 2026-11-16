#ifndef STATE_MACHINE_H
#define STATE_MACHINE_H

#include "state.h"

void inicializarMaquinaEstados();
void executarEstado();

EstadoSistema obterEstadoAtual();
void mudarEstado(EstadoSistema novoEstado);

const char* nomeEstado(EstadoSistema estado);

// Função temporária para testar os acessos
void simularResultadoAcesso(bool autorizado);

#endif