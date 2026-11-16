-- SecureLab: schema completo do banco (PostgreSQL)
--
-- Como usar: crie o banco vazio "securelab" e rode este arquivo INTEIRO conectado a ele
-- (pgAdmin: Query Tool no banco securelab > abrir o arquivo > F5).
-- É seguro rodar de novo: usa IF NOT EXISTS e não apaga dados.
--
-- Este arquivo deve refletir os models em models.py. Se um mudar, atualize o outro.

-- Fuso horário padrão do banco (vale para conexões novas).
ALTER DATABASE securelab SET timezone TO 'America/Sao_Paulo';

-- Pessoas cadastradas no sistema. "Remover" um usuário = ativo = FALSE (soft delete),
-- para preservar o histórico de acessos.
CREATE TABLE IF NOT EXISTS usuario (
    id         SERIAL PRIMARY KEY,
    nome       VARCHAR(100) NOT NULL,
    email      VARCHAR(150) UNIQUE,
    ativo      BOOLEAN NOT NULL DEFAULT TRUE,
    criado_em  TIMESTAMPTZ DEFAULT NOW()
);

-- Cada unidade física ESP32 + sensor R307 + fechadura.
-- api_key_hash guarda o SHA-256 da chave de API do dispositivo (nunca a chave em si).
CREATE TABLE IF NOT EXISTS dispositivo (
    id            SERIAL PRIMARY KEY,
    nome          VARCHAR(100) NOT NULL,
    local         VARCHAR(100),
    ativo         BOOLEAN NOT NULL DEFAULT TRUE,
    api_key_hash  VARCHAR(64)
);

-- Liga o template_id do sensor R307 a um usuário. Cada template_id é único (MVP com um sensor).
CREATE TABLE IF NOT EXISTS digital (
    id             SERIAL PRIMARY KEY,
    usuario_id     INTEGER NOT NULL REFERENCES usuario (id),
    template_id    INTEGER NOT NULL UNIQUE,
    cadastrada_em  TIMESTAMPTZ DEFAULT NOW()
);

-- Toda tentativa de acesso, autorizada ou negada. usuario_id é nulo quando a digital
-- é desconhecida ou o usuário está inativo.
CREATE TABLE IF NOT EXISTS acesso (
    id                SERIAL PRIMARY KEY,
    usuario_id        INTEGER REFERENCES usuario (id),
    dispositivo_id    INTEGER NOT NULL REFERENCES dispositivo (id),
    template_id_lido  INTEGER,
    data_hora         TIMESTAMPTZ DEFAULT NOW(),
    resultado         VARCHAR(20) NOT NULL,
    CONSTRAINT check_resultado CHECK (resultado IN ('AUTORIZADO', 'NEGADO'))
);

-- Índices para filtros e ordenação (nomes no padrão do SQLAlchemy).
CREATE INDEX IF NOT EXISTS ix_acesso_data_hora      ON acesso (data_hora);
CREATE INDEX IF NOT EXISTS ix_acesso_usuario_id     ON acesso (usuario_id);
CREATE INDEX IF NOT EXISTS ix_acesso_dispositivo_id ON acesso (dispositivo_id);
CREATE INDEX IF NOT EXISTS ix_digital_usuario_id    ON digital (usuario_id);
