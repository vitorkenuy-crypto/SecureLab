#ifndef ACCESS_H
#define ACCESS_H

enum class EstadoAcesso {
    AUTORIZADO,
    NEGADO
};

void processarAcesso(EstadoAcesso estado);

#endif