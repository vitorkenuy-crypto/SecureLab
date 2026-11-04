import 'package:flutter/material.dart';

import '../core/session.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import '../widgets/figma_icon.dart';
import 'servidor_dialog.dart';

/// Tela "Login" do Figma. Faz POST /auth/login com o usuário admin do .env da API.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _user = TextEditingController();
  final _pass = TextEditingController();
  bool _hide = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Se a sessão expirou com telas abertas (detalhes, diálogos), fecha todas.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    });
    final ultimo = AppScope.read(context).username;
    if (ultimo != null) _user.text = ultimo;
  }

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (_user.text.trim().isEmpty || _pass.text.isEmpty) {
      showMessage(context, 'Informe usuário e senha.', error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await AppScope.read(context).login(_user.text, _pass.text);
      // O main.dart troca para o app automaticamente.
    } catch (e) {
      if (mounted) showMessage(context, errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    const BrandLogo(size: 150, white: false),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('SecureLab', style: AppText.bold(64, Colors.white)),
                    ),
                    Text('Controle de Acesso', style: AppText.bold(28, AppColors.blue)),
                    const SizedBox(height: 28),
                    Text(
                      'Acesso seguro para um\nambiente mais inteligente',
                      textAlign: TextAlign.center,
                      style: AppText.bold(19, AppColors.blue),
                    ),
                    const SizedBox(height: 56),
                    _Field(
                      controller: _user,
                      hint: 'E-mail ou usuário',
                      icon: AppIcons.userWhite,
                      action: TextInputAction.next,
                    ),
                    const SizedBox(height: 13),
                    _Field(
                      controller: _pass,
                      hint: 'Senha',
                      icon: AppIcons.lock,
                      obscure: _hide,
                      action: TextInputAction.done,
                      onSubmitted: (_) => _entrar(),
                      suffix: IconButton(
                        tooltip: _hide ? 'Mostrar senha' : 'Ocultar senha',
                        onPressed: () => setState(() => _hide = !_hide),
                        icon: _EyeIcon(slashed: _hide),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => showMessage(context,
                            'A senha do administrador é definida no .env da API. Fale com o responsável pelo backend.'),
                        child: Text('Esqueci minha senha?', style: AppText.bold(15, AppColors.blue)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 59,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _entrar,
                        style: ElevatedButton.styleFrom(elevation: 4, shadowColor: Colors.black54),
                        child: _loading
                            ? const SizedBox(
                                width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                            : Text('Entrar', style: AppText.bold(20, Colors.white)),
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(height: 24),
                    TextButton.icon(
                      onPressed: () => showServidorDialog(context),
                      icon: const Icon(Icons.dns_outlined, size: 16, color: AppColors.blue),
                      label: Text(AppScope.of(context).baseUrl, style: AppText.bold(13, AppColors.blue)),
                    ),
                    Text('Versão 1.0.0', style: AppText.bold(15, Colors.white)),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffix,
    this.action,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final AppIcon icon;
  final bool obscure;
  final Widget? suffix;
  final TextInputAction? action;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 59,
      decoration: BoxDecoration(
        color: AppColors.fieldOnNavy,
        borderRadius: BorderRadius.circular(10),
        boxShadow: AppColors.shadow,
      ),
      padding: const EdgeInsets.only(left: 12, right: 4),
      child: Row(
        children: [
          FigmaIcon(icon, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              textInputAction: action,
              onSubmitted: onSubmitted,
              autocorrect: false,
              enableSuggestions: !obscure,
              style: AppText.bold(15, Colors.white),
              cursorColor: AppColors.blue,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: AppText.bold(15, Colors.white),
              ),
            ),
          ),
          if (suffix != null) suffix!,
        ],
      ),
    );
  }
}

/// Olho do Figma, com o traço diagonal quando a senha está oculta.
class _EyeIcon extends StatelessWidget {
  const _EyeIcon({required this.slashed});

  final bool slashed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 30,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const FigmaIcon(AppIcons.eye, size: 30),
          if (slashed)
            Transform.rotate(
              angle: 0.65, // ~37° como no Figma
              child: Container(width: 34, height: 2.5, color: Colors.white),
            ),
        ],
      ),
    );
  }
}
