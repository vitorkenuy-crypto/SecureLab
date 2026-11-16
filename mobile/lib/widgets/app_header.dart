import 'package:flutter/material.dart';

import '../core/session.dart';
import '../core/theme.dart';
import 'common.dart';
import 'figma_icon.dart';

/// Cabeçalho azul-marinho: logo, sino e avatar do admin, mais o conteúdo
/// específico de cada tela (título, chips, busca) logo abaixo.
class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    this.child,
    this.alertas = 0,
    this.onBell,
    this.onAvatar,
  });

  final Widget? child;

  /// Quantidade de alertas (tentativas negadas hoje). >0 mostra o ponto vermelho.
  final int alertas;
  final VoidCallback? onBell;
  final VoidCallback? onAvatar;

  @override
  Widget build(BuildContext context) {
    final session = AppScope.of(context);
    final shell = ShellScope.maybeOf(context);
    final alertas = shell?.alertas ?? this.alertas;
    final onBell = this.onBell ?? shell?.onBell;
    final onAvatar = this.onAvatar ?? shell?.onAvatar;
    return Container(
      color: AppColors.navy,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(23, 14, 23, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const BrandLogo(size: 60),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SecureLab', style: AppText.bold(25, Colors.white)),
                        Text('Controle de Acesso', style: AppText.bold(15, AppColors.blue)),
                      ],
                    ),
                  ),
                  _BoxButton(
                    color: AppColors.bellBox,
                    onTap: onBell,
                    tooltip: 'Alertas',
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const FigmaIcon(AppIcons.bellWhite, size: 34),
                        if (alertas > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(color: AppColors.red, shape: BoxShape.circle),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  _BoxButton(
                    color: AppColors.blue,
                    onTap: onAvatar,
                    tooltip: 'Perfil',
                    child: Text(initialsOf(session.username ?? 'Admin'), style: AppText.regular(25, Colors.white)),
                  ),
                ],
              ),
              if (child != null) ...[const SizedBox(height: 18), child!],
            ],
          ),
        ),
      ),
    );
  }
}

/// Dados que a navegação principal compartilha com os cabeçalhos das abas.
class ShellScope extends InheritedWidget {
  const ShellScope({
    super.key,
    required this.alertas,
    required this.onBell,
    required this.onAvatar,
    required super.child,
  });

  final int alertas;
  final VoidCallback onBell;
  final VoidCallback onAvatar;

  static ShellScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellScope>();

  @override
  bool updateShouldNotify(ShellScope old) => old.alertas != alertas;
}

/// Cabeçalho das telas internas (seta de voltar + título), como em "Cadastrar Biometria".
class DetailHeader extends StatelessWidget {
  const DetailHeader({super.key, required this.title, this.child, this.onBack});

  final String title;
  final Widget? child;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return AppHeader(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onBack ?? () => Navigator.of(context).maybePop(),
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: FigmaIcon(AppIcons.arrowBack, size: 36),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.bold(25, Colors.white)),
              ),
            ],
          ),
          if (child != null) ...[const SizedBox(height: 14), child!],
        ],
      ),
    );
  }
}

class _BoxButton extends StatelessWidget {
  const _BoxButton({required this.color, required this.child, this.onTap, this.tooltip});

  final Color color;
  final Widget child;
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: SizedBox(width: 48, height: 48, child: Center(child: child)),
        ),
      ),
    );
  }
}

/// Título + subtítulo azul usado no cabeçalho ("Usuários" / "7 cadastrados . 6 ativos").
class HeaderTitle extends StatelessWidget {
  const HeaderTitle({super.key, required this.title, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.bold(25, Colors.white)),
              if (subtitle != null) Text(subtitle!, style: AppText.bold(15, AppColors.blue)),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Botão quadrado do cabeçalho (o "+" azul e o download cinza).
class HeaderSquareButton extends StatelessWidget {
  const HeaderSquareButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.color = AppColors.blue,
    this.width = 53,
    this.height = 41,
  });

  final AppIcon icon;
  final VoidCallback onTap;
  final String tooltip;
  final Color color;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), boxShadow: AppColors.shadow),
        child: Material(
          color: color,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: SizedBox(width: width, height: height, child: Center(child: FigmaIcon(icon, size: 28))),
          ),
        ),
      ),
    );
  }
}
