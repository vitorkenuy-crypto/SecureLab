import 'package:flutter/material.dart';

import '../core/session.dart';
import '../core/theme.dart';
import '../widgets/app_header.dart';
import '../widgets/common.dart';
import '../widgets/figma_icon.dart';
import 'biometrias_screen.dart';
import 'servidor_dialog.dart';

/// Tela "Configurações" do Figma.
class ConfiguracoesScreen extends StatelessWidget {
  const ConfiguracoesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = AppScope.of(context);
    final nome = session.username ?? 'Admin';

    return Column(
      children: [
        AppHeader(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Configurações', style: AppText.regular(25, Colors.white)),
              Text('SecureLab v1.0.0', style: AppText.regular(11, AppColors.blue)),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.fieldOnNavy,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: AppColors.shadow,
                ),
                padding: const EdgeInsets.fromLTRB(14, 13, 8, 13),
                child: Row(children: [
                  InitialsBox(text: initialsOf(nome), color: AppColors.blue, size: 54, fontSize: 25, shadow: false),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(nome, style: AppText.regular(15, Colors.white)),
                      Text('Administrador', style: AppText.regular(15, AppColors.gray)),
                      Text(session.baseUrl, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: AppText.regular(15, AppColors.blue)),
                    ]),
                  ),
                ]),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            children: [
              Text('Sistema', style: AppText.regular(25, AppColors.gray)),
              const SizedBox(height: 10),
              _Opcao(
                leading: const FigmaIcon(AppIcons.bellBlue, size: 50),
                titulo: 'Notificações',
                subtitulo: 'Push, alertas e relatórios',
                onTap: () => showMessage(context, 'Notificações push ainda não estão disponíveis na API.'),
              ),
              _Opcao(
                leading: const SizedBox(
                  width: 50,
                  height: 50,
                  child: Stack(alignment: Alignment.center, children: [
                    FigmaIcon(AppIcons.shieldBlue, size: 50),
                    FigmaIcon(AppIcons.checkBlue2, size: 30),
                  ]),
                ),
                titulo: 'Segurança',
                subtitulo: '2FA, bloqueio e acesso remoto',
                onTap: () => showMessage(context, 'Opções de segurança ainda não estão disponíveis na API.'),
              ),
              _Opcao(
                leading: const FigmaIcon(AppIcons.fingerprintBlue, size: 50),
                titulo: 'Biometria',
                subtitulo: 'Cadastro e gerenciamento',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BiometriasScreen())),
              ),
              _Opcao(
                leading: const FigmaIcon(AppIcons.serverBlue, size: 44),
                titulo: 'Servidor da API',
                subtitulo: session.baseUrl,
                onTap: () => showServidorDialog(context),
              ),
              const SizedBox(height: 6),
              _Opcao(
                leading: const SizedBox(width: 50, child: Icon(Icons.logout, size: 40, color: AppColors.red)),
                titulo: 'Sair',
                subtitulo: 'Encerrar a sessão neste aparelho',
                onTap: () => session.logout(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Opcao extends StatelessWidget {
  const _Opcao({required this.leading, required this.titulo, required this.subtitulo, this.onTap});

  final Widget leading;
  final String titulo;
  final String subtitulo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x1A000000)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: SizedBox(
            height: 88,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(children: [
                leading,
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titulo, style: AppText.regular(23, Colors.black)),
                      Text(subtitulo, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: AppText.regular(15, AppColors.gray)),
                    ],
                  ),
                ),
                const FigmaIcon(AppIcons.forward, size: 40),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
