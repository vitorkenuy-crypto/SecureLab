-- SecureLab: dados de exemplo para desenvolvimento (OPCIONAL).
-- Rode DEPOIS do schema.sql, num banco vazio. Não rode em um banco com dados reais.
--
-- Os dispositivos nascem SEM chave de API. Depois de subir a API, gere a chave de cada um
-- com POST /dispositivos/{id}/chave (veja o README).

INSERT INTO usuario (nome, email, ativo) VALUES
    ('Ana Silva',    'ana.silva@exemplo.com',    TRUE),
    ('Bruno Costa',  'bruno.costa@exemplo.com',  TRUE),
    ('Carla Souza',  'carla.souza@exemplo.com',  FALSE);  -- usuária removida: nunca é autorizada

INSERT INTO dispositivo (nome, local, ativo) VALUES
    ('Porta Lab 1',             'Laboratório 1',      TRUE),
    ('Porta Sala de Servidores', 'Sala de Servidores', TRUE);

INSERT INTO digital (usuario_id, template_id)
SELECT id, 1 FROM usuario WHERE email = 'ana.silva@exemplo.com';
INSERT INTO digital (usuario_id, template_id)
SELECT id, 2 FROM usuario WHERE email = 'bruno.costa@exemplo.com';
INSERT INTO digital (usuario_id, template_id)
SELECT id, 3 FROM usuario WHERE email = 'carla.souza@exemplo.com';

-- Histórico de exemplo: um autorizado, um negado por usuário inativo, um negado por digital desconhecida.
INSERT INTO acesso (usuario_id, dispositivo_id, template_id_lido, resultado)
SELECT u.id, d.id, 1, 'AUTORIZADO'
  FROM usuario u, dispositivo d
 WHERE u.email = 'ana.silva@exemplo.com' AND d.nome = 'Porta Lab 1';

INSERT INTO acesso (usuario_id, dispositivo_id, template_id_lido, resultado)
SELECT NULL, d.id, 3, 'NEGADO' FROM dispositivo d WHERE d.nome = 'Porta Lab 1';

INSERT INTO acesso (usuario_id, dispositivo_id, template_id_lido, resultado)
SELECT NULL, d.id, 99, 'NEGADO' FROM dispositivo d WHERE d.nome = 'Porta Sala de Servidores';
