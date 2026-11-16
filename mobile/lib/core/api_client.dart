import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  /// Código HTTP, ou null quando nem chegou a falar com o servidor.
  final int? status;
  final String message;

  const ApiException(this.status, this.message);

  bool get semConexao => status == null;

  @override
  String toString() => message;
}

/// Resposta já decodificada + headers (para ler o X-Total-Count).
class ApiResponse {
  final dynamic body;
  final Map<String, String> headers;

  const ApiResponse(this.body, this.headers);

  int? get totalCount => int.tryParse(headers['x-total-count'] ?? '');
}

/// Cliente HTTP genérico: monta URLs, envia o token e traduz erros da API.
class ApiClient {
  ApiClient({required this.baseUrl, this.token});

  String baseUrl;
  String? token;

  /// Chamado quando a API responde 401 numa rota de admin (token expirado).
  void Function()? onUnauthorized;

  final http.Client _http = http.Client();
  static const _timeout = Duration(seconds: 12);

  Uri uri(String path, [Map<String, Object?>? query]) {
    final base = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final u = Uri.parse('$base$path');
    if (query == null) return u;
    final q = <String, String>{};
    query.forEach((k, v) {
      if (v != null) q[k] = '$v';
    });
    return q.isEmpty ? u : u.replace(queryParameters: q);
  }

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<ApiResponse> get(String path, {Map<String, Object?>? query}) =>
      _send(() => _http.get(uri(path, query), headers: _headers));

  Future<ApiResponse> post(String path, {Object? json}) => _send(() => _http.post(
        uri(path),
        headers: {..._headers, 'Content-Type': 'application/json'},
        body: json == null ? null : jsonEncode(json),
      ));

  Future<ApiResponse> patch(String path, {Object? json}) => _send(() => _http.patch(
        uri(path),
        headers: {..._headers, 'Content-Type': 'application/json'},
        body: jsonEncode(json ?? {}),
      ));

  Future<ApiResponse> delete(String path) =>
      _send(() => _http.delete(uri(path), headers: _headers));

  /// POST como formulário (usado só no /auth/login).
  Future<ApiResponse> postForm(String path, Map<String, String> fields) =>
      _send(() => _http.post(uri(path), headers: {'Accept': 'application/json'}, body: fields),
          isLogin: true);

  Future<ApiResponse> _send(Future<http.Response> Function() call, {bool isLogin = false}) async {
    http.Response res;
    try {
      res = await call().timeout(_timeout);
    } on TimeoutException {
      throw ApiException(null, 'A API não respondeu a tempo ($baseUrl).');
    } on http.ClientException {
      throw ApiException(null, 'Não foi possível conectar à API em $baseUrl.');
    } on FormatException {
      throw ApiException(null, 'Endereço da API inválido: $baseUrl');
    } on ArgumentError {
      throw ApiException(null, 'Endereço da API inválido: $baseUrl');
    } catch (_) {
      // Sem rede, API desligada etc. (inclui SocketException no celular)
      throw ApiException(null, 'Não foi possível conectar à API em $baseUrl.');
    }

    final text = utf8.decode(res.bodyBytes);
    dynamic body;
    if (text.isNotEmpty) {
      try {
        body = jsonDecode(text);
      } on FormatException {
        body = text;
      }
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return ApiResponse(body, res.headers);
    }

    if (res.statusCode == 401 && !isLogin) {
      onUnauthorized?.call();
    }
    throw ApiException(res.statusCode, _mensagemDeErro(res.statusCode, body));
  }

  /// O FastAPI devolve {"detail": "..."} ou, no 422, {"detail": [ {msg, loc}, ... ]}.
  String _mensagemDeErro(int status, dynamic body) {
    final detail = body is Map ? body['detail'] : null;
    if (detail is String) return detail;
    if (detail is List && detail.isNotEmpty) {
      final first = detail.first;
      if (first is Map && first['msg'] != null) return 'Dados inválidos: ${first['msg']}';
    }
    switch (status) {
      case 401:
        return 'Sessão expirada. Faça login novamente.';
      case 404:
        return 'Registro não encontrado.';
      case 409:
        return 'Conflito com um dado já cadastrado.';
      case 422:
        return 'Dados inválidos.';
      default:
        return 'Erro inesperado no servidor ($status).';
    }
  }
}
