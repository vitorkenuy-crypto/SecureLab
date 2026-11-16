import '../core/api_client.dart';
import '../core/theme.dart';
import '../models/models.dart';

/// Todas as rotas da API SecureLab que o app usa.
/// O app não chama POST /acessos: essa rota é exclusiva do ESP32.
class SecureLabApi {
  SecureLabApi(this.client);

  final ApiClient client;

  // ---------- Saúde / autenticação ----------

  /// GET / : confirma que a API está no ar.
  Future<bool> ping() async {
    try {
      await client.get('/');
      return true;
    } on ApiException {
      return false;
    }
  }

  /// POST /auth/login (formulário). Devolve o access_token.
  Future<String> login(String username, String password) async {
    final res = await client.postForm('/auth/login', {
      'username': username,
      'password': password,
    });
    return (res.body as Map)['access_token'] as String;
  }

  // ---------- Usuários ----------

  Future<List<Usuario>> usuarios() async {
    final res = await client.get('/usuarios');
    return (res.body as List).map((e) => Usuario.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Usuario> criarUsuario({required String nome, String? email, bool ativo = true}) async {
    final res = await client.post('/usuarios', json: {
      'nome': nome,
      'email': (email == null || email.trim().isEmpty) ? null : email.trim(),
      'ativo': ativo,
    });
    return Usuario.fromJson(res.body as Map<String, dynamic>);
  }

  /// PATCH /usuarios/{id}: altera só o que for enviado.
  Future<Usuario> atualizarUsuario(int id, {String? nome, String? email, bool? ativo}) async {
    final body = <String, Object?>{
      if (nome != null) 'nome': nome,
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      if (ativo != null) 'ativo': ativo,
    };
    final res = await client.patch('/usuarios/$id', json: body);
    return Usuario.fromJson(res.body as Map<String, dynamic>);
  }

  /// DELETE /usuarios/{id}: soft delete (ativo = false).
  Future<Usuario> desativarUsuario(int id) async {
    final res = await client.delete('/usuarios/$id');
    return Usuario.fromJson(res.body as Map<String, dynamic>);
  }

  // ---------- Dispositivos (Ambientes) ----------

  Future<List<Dispositivo>> dispositivos() async {
    final res = await client.get('/dispositivos');
    return (res.body as List).map((e) => Dispositivo.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<DispositivoComChave> criarDispositivo({required String nome, String? local}) async {
    final res = await client.post('/dispositivos', json: {
      'nome': nome,
      'local': (local == null || local.trim().isEmpty) ? null : local.trim(),
      'ativo': true,
    });
    return DispositivoComChave.fromJson(res.body as Map<String, dynamic>);
  }

  Future<DispositivoComChave> novaChave(int dispositivoId) async {
    final res = await client.post('/dispositivos/$dispositivoId/chave');
    return DispositivoComChave.fromJson(res.body as Map<String, dynamic>);
  }

  // ---------- Digitais ----------

  Future<List<Digital>> digitais({int? usuarioId}) async {
    final res = await client.get('/digitais', query: {'usuario_id': usuarioId});
    return (res.body as List).map((e) => Digital.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Digital> cadastrarDigital({required int usuarioId, required int templateId}) async {
    final res = await client.post('/digitais', json: {'usuario_id': usuarioId, 'template_id': templateId});
    return Digital.fromJson(res.body as Map<String, dynamic>);
  }

  Future<void> removerDigital(int id) async {
    await client.delete('/digitais/$id');
  }

  // ---------- Acessos (histórico) ----------

  Future<Pagina<Acesso>> acessos({
    int limit = 50,
    int offset = 0,
    int? usuarioId,
    int? dispositivoId,
    String? resultado,
    DateTime? dataInicio,
    DateTime? dataFim,
  }) async {
    final res = await client.get('/acessos', query: {
      'limit': limit,
      'offset': offset,
      'usuario_id': usuarioId,
      'dispositivo_id': dispositivoId,
      'resultado': resultado,
      'data_inicio': dataInicio == null ? null : isoDay(dataInicio),
      'data_fim': dataFim == null ? null : isoDay(dataFim),
    });
    final itens = (res.body as List).map((e) => Acesso.fromJson(e as Map<String, dynamic>)).toList();
    return Pagina(itens, res.totalCount ?? itens.length);
  }

  /// Só a contagem (limit=1 e lê o X-Total-Count).
  Future<int> contarAcessos({String? resultado, DateTime? dia}) async {
    final p = await acessos(limit: 1, resultado: resultado, dataInicio: dia, dataFim: dia);
    return p.total;
  }
}
