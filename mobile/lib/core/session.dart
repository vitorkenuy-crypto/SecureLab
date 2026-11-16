import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/securelab_api.dart';
import 'api_client.dart';

/// Guarda o endereço da API, o token e o usuário admin logado.
class Session extends ChangeNotifier {
  Session._(this._prefs, this.api);

  /// Endereço padrão da API:
  /// - app aberto pela própria API (pacote de teste, http://IP:8000/app): mesma origem,
  ///   funciona no PC e em qualquer celular da rede;
  /// - navegador em desenvolvimento (flutter run): http://localhost:8000;
  /// - emulador Android: o PC é 10.0.2.2. Em celular físico, use o IP do PC.
  static String get defaultBaseUrl {
    if (kIsWeb) {
      if (Uri.base.path.startsWith('/app')) return Uri.base.origin;
      return 'http://localhost:8000';
    }
    return 'http://10.0.2.2:8000';
  }

  static const _kBaseUrl = 'base_url';
  static const _kToken = 'token';
  static const _kUser = 'username';

  final SharedPreferences _prefs;
  final SecureLabApi api;
  String? username;

  static Future<Session> load() async {
    final prefs = await SharedPreferences.getInstance();
    final client = ApiClient(
      baseUrl: prefs.getString(_kBaseUrl) ?? defaultBaseUrl,
      token: prefs.getString(_kToken),
    );
    final s = Session._(prefs, SecureLabApi(client))..username = prefs.getString(_kUser);
    client.onUnauthorized = s.logout;
    return s;
  }

  bool get isLoggedIn => api.client.token != null;
  String get baseUrl => api.client.baseUrl;

  Future<void> setBaseUrl(String url) async {
    api.client.baseUrl = url.trim();
    await _prefs.setString(_kBaseUrl, api.client.baseUrl);
    notifyListeners();
  }

  Future<void> login(String user, String password) async {
    final token = await api.login(user.trim(), password);
    api.client.token = token;
    username = user.trim();
    await _prefs.setString(_kToken, token);
    await _prefs.setString(_kUser, username!);
    notifyListeners();
  }

  Future<void> logout() async {
    if (api.client.token == null) return;
    api.client.token = null;
    await _prefs.remove(_kToken);
    notifyListeners();
  }
}

/// Disponibiliza a Session para toda a árvore de widgets.
class AppScope extends InheritedNotifier<Session> {
  const AppScope({super.key, required Session session, required super.child})
      : super(notifier: session);

  static Session of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Leitura sem se inscrever para rebuilds (use em callbacks).
  static Session read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
