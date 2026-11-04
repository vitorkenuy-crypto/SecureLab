/// Modelos espelhando as respostas da API SecureLab (docs/api/api-securelab.md).

class Usuario {
  final int id;
  final String nome;
  final String? email;
  final bool ativo;

  const Usuario({required this.id, required this.nome, this.email, required this.ativo});

  factory Usuario.fromJson(Map<String, dynamic> j) => Usuario(
        id: j['id'] as int,
        nome: j['nome'] as String,
        email: j['email'] as String?,
        ativo: (j['ativo'] as bool?) ?? true,
      );
}

/// Na interface, um dispositivo aparece como "Ambiente" (porta + sensor + fechadura).
class Dispositivo {
  final int id;
  final String nome;
  final String? local;
  final bool ativo;

  const Dispositivo({required this.id, required this.nome, this.local, required this.ativo});

  factory Dispositivo.fromJson(Map<String, dynamic> j) => Dispositivo(
        id: j['id'] as int,
        nome: j['nome'] as String,
        local: j['local'] as String?,
        ativo: (j['ativo'] as bool?) ?? true,
      );
}

/// Resposta de POST /dispositivos e POST /dispositivos/{id}/chave.
class DispositivoComChave {
  final Dispositivo dispositivo;
  final String apiKey;

  const DispositivoComChave(this.dispositivo, this.apiKey);

  factory DispositivoComChave.fromJson(Map<String, dynamic> j) =>
      DispositivoComChave(Dispositivo.fromJson(j), j['api_key'] as String);
}

class Digital {
  final int id;
  final int usuarioId;
  final int templateId;

  const Digital({required this.id, required this.usuarioId, required this.templateId});

  factory Digital.fromJson(Map<String, dynamic> j) => Digital(
        id: j['id'] as int,
        usuarioId: j['usuario_id'] as int,
        templateId: j['template_id'] as int,
      );
}

class Acesso {
  final int id;
  final int? usuarioId;
  final String? usuarioNome;
  final int dispositivoId;
  final String? dispositivoNome;
  final int? templateIdLido;
  final DateTime dataHora;
  final String resultado;

  const Acesso({
    required this.id,
    this.usuarioId,
    this.usuarioNome,
    required this.dispositivoId,
    this.dispositivoNome,
    this.templateIdLido,
    required this.dataHora,
    required this.resultado,
  });

  bool get autorizado => resultado == 'AUTORIZADO';

  factory Acesso.fromJson(Map<String, dynamic> j) => Acesso(
        id: j['id'] as int,
        usuarioId: j['usuario_id'] as int?,
        usuarioNome: j['usuario_nome'] as String?,
        dispositivoId: j['dispositivo_id'] as int,
        dispositivoNome: j['dispositivo_nome'] as String?,
        templateIdLido: j['template_id_lido'] as int?,
        dataHora: DateTime.parse(j['data_hora'] as String).toLocal(),
        resultado: j['resultado'] as String,
      );
}

/// Lista paginada: itens + total vindo do header X-Total-Count.
class Pagina<T> {
  final List<T> itens;
  final int total;

  const Pagina(this.itens, this.total);
}
