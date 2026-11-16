import 'package:flutter/material.dart';

/// Ícone exportado do Figma (assets/icons/<nome>.png).
/// Se o arquivo ainda não foi baixado (scripts/baixar_icones.ps1), mostra o
/// ícone Material equivalente para o app continuar funcionando.
class FigmaIcon extends StatelessWidget {
  const FigmaIcon(this.icon, {super.key, this.size = 30, this.fallbackColor});

  final AppIcon icon;
  final double size;
  final Color? fallbackColor;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icons/${icon.file}.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => SizedBox(
        width: size,
        height: size,
        child: Icon(icon.fallback, size: size * 0.9, color: fallbackColor ?? icon.color),
      ),
    );
  }
}

class AppIcon {
  const AppIcon(this.file, this.fallback, [this.color = const Color(0xFF666666)]);

  final String file;
  final IconData fallback;
  final Color color;
}

const _white = Colors.white;
const _blue = Color(0xFF1690C7);
const _navy = Color(0xFF0B1F33);

/// Todos os ícones das telas do Figma. O nome do arquivo bate com o script de download.
class AppIcons {
  // Marca
  static const shieldWhite = AppIcon('shield_white', Icons.shield_outlined, _white);
  static const fingerprintWhite = AppIcon('fingerprint_white', Icons.fingerprint, _white);
  static const shieldBlue = AppIcon('shield_blue', Icons.shield_outlined, _blue);
  static const fingerprintBlue = AppIcon('fingerprint_blue', Icons.fingerprint, _blue);

  // Cabeçalho
  static const bellWhite = AppIcon('bell_white', Icons.notifications_none, _white);

  // Login
  static const userWhite = AppIcon('user_white', Icons.person, _white);
  static const lock = AppIcon('lock', Icons.lock_outline, _white);
  static const eye = AppIcon('eye', Icons.visibility_outlined, _white);

  // Barra de navegação (cinza = inativo, *_active = selecionado)
  static const navHome = AppIcon('nav_home', Icons.home_outlined);
  static const navHomeActive = AppIcon('nav_home_active', Icons.home, _navy);
  static const navUsers = AppIcon('nav_users', Icons.groups_outlined);
  static const navUsersActive = AppIcon('nav_users_active', Icons.groups, _navy);
  static const navDoor = AppIcon('nav_door', Icons.door_front_door_outlined);
  static const navDoorActive = AppIcon('door_dark', Icons.door_front_door, _navy);
  static const navHistory = AppIcon('nav_history', Icons.schedule);
  static const navHistoryActive = AppIcon('nav_history_active', Icons.schedule, _navy);
  static const navConfig = AppIcon('nav_config', Icons.settings_outlined);
  static const navConfigActive = AppIcon('nav_config_active', Icons.settings, _navy);

  // Início
  static const userDark = AppIcon('user_dark', Icons.person, _navy);
  static const doorDark = AppIcon('door_dark', Icons.door_front_door_outlined, _navy);
  static const enter = AppIcon('enter', Icons.login, _navy);
  static const cancel = AppIcon('cancel', Icons.cancel_outlined, _navy);
  static const serverBlue = AppIcon('server_blue', Icons.dns_outlined, _blue);
  static const checkBlue = AppIcon('check_blue', Icons.check, _blue);
  static const checkBlue2 = AppIcon('check_blue_2', Icons.check, _blue);

  // Listas
  static const forward = AppIcon('forward', Icons.chevron_right);
  static const search = AppIcon('search', Icons.search, _white);
  static const plus = AppIcon('plus', Icons.add_circle, _white);
  static const download = AppIcon('download', Icons.download, _white);
  static const arrowBack = AppIcon('arrow_back', Icons.arrow_back, _white);

  // Ambientes
  static const serverWhite = AppIcon('server_white', Icons.dns_outlined, _white);
  static const adjust = AppIcon('adjust', Icons.tune, _white);
  static const workstation = AppIcon('workstation', Icons.computer, _white);

  // Configurações / Biometria
  static const bellBlue = AppIcon('bell_blue', Icons.notifications_none, _blue);
  static const loadingRing = AppIcon('loading_ring', Icons.radio_button_unchecked, _blue);
}
