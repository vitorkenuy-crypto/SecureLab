import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/session.dart';
import 'core/theme.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  final session = await Session.load();
  runApp(SecureLabApp(session: session));
}

class SecureLabApp extends StatelessWidget {
  const SecureLabApp({super.key, required this.session});

  final Session session;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      session: session,
      child: MaterialApp(
        title: 'SecureLab',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        // No navegador, permite "puxar para atualizar" arrastando com o mouse.
        scrollBehavior: const MaterialScrollBehavior().copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
            PointerDeviceKind.stylus,
          },
        ),
        // Troca automaticamente entre login e app quando o token muda
        // (inclusive quando a API devolve 401 por token expirado).
        home: ListenableBuilder(
          listenable: session,
          builder: (context, _) => session.isLoggedIn ? const HomeShell() : const LoginScreen(),
        ),
      ),
    );
  }
}
