import 'package:flutter/material.dart';

import '../core/session.dart';
import '../core/theme.dart';
import '../widgets/app_header.dart';
import '../widgets/figma_icon.dart';
import 'ambientes_screen.dart';
import 'configuracoes_screen.dart';
import 'historico_screen.dart';
import 'inicio_screen.dart';
import 'usuarios_screen.dart';

enum AppTab { inicio, usuarios, ambientes, historico, config }

/// Estrutura principal: conteúdo da aba + barra de navegação inferior do Figma.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  static HomeShellState of(BuildContext context) => context.findAncestorStateOfType<HomeShellState>()!;

  @override
  State<HomeShell> createState() => HomeShellState();
}

class HomeShellState extends State<HomeShell> {
  AppTab _tab = AppTab.inicio;

  /// Filtro inicial do Histórico (0 Todos, 1 Autorizados, 2 Negados).
  int _historicoFiltro = 0;

  /// Abas de Usuários e Ambientes também aceitam um filtro inicial.
  int _usuariosFiltro = 0;
  int _ambientesFiltro = 0;

  int _alertas = 0;

  @override
  void initState() {
    super.initState();
    atualizarAlertas();
  }

  /// Negadas de hoje: alimentam o ponto vermelho do sino.
  Future<void> atualizarAlertas() async {
    try {
      final n = await AppScope.read(context).api.contarAcessos(resultado: 'NEGADO', dia: DateTime.now());
      if (mounted) setState(() => _alertas = n);
    } catch (_) {
      // Sem conexão: o sino só fica sem o ponto.
    }
  }

  void goTo(AppTab tab, {int filtro = 0}) {
    setState(() {
      _tab = tab;
      switch (tab) {
        case AppTab.historico:
          _historicoFiltro = filtro;
        case AppTab.usuarios:
          _usuariosFiltro = filtro;
        case AppTab.ambientes:
          _ambientesFiltro = filtro;
        default:
          break;
      }
    });
    atualizarAlertas();
  }

  Widget _body() {
    switch (_tab) {
      case AppTab.inicio:
        return const InicioScreen();
      case AppTab.usuarios:
        return UsuariosScreen(key: ValueKey('u$_usuariosFiltro'), filtroInicial: _usuariosFiltro);
      case AppTab.ambientes:
        return AmbientesScreen(key: ValueKey('a$_ambientesFiltro'), filtroInicial: _ambientesFiltro);
      case AppTab.historico:
        return HistoricoScreen(key: ValueKey('h$_historicoFiltro'), filtroInicial: _historicoFiltro);
      case AppTab.config:
        return const ConfiguracoesScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShellScope(
      alertas: _alertas,
      onBell: () => goTo(AppTab.historico, filtro: 2),
      onAvatar: () => goTo(AppTab.config),
      child: Scaffold(
        body: _body(),
        bottomNavigationBar: _BottomBar(current: _tab, onTap: goTo),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.current, required this.onTap});

  final AppTab current;
  final void Function(AppTab) onTap;

  static const _items = [
    (AppTab.inicio, 'Início', AppIcons.navHome, AppIcons.navHomeActive),
    (AppTab.usuarios, 'Usuários', AppIcons.navUsers, AppIcons.navUsersActive),
    (AppTab.ambientes, 'Ambientes', AppIcons.navDoor, AppIcons.navDoorActive),
    (AppTab.historico, 'Histórico', AppIcons.navHistory, AppIcons.navHistoryActive),
    (AppTab.config, 'Config.', AppIcons.navConfig, AppIcons.navConfigActive),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.footer,
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
        boxShadow: AppColors.shadow,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              for (final (tab, label, icon, activeIcon) in _items)
                Expanded(
                  child: InkWell(
                    onTap: () => onTap(tab),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FigmaIcon(tab == current ? activeIcon : icon, size: 28),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            label,
                            style: AppText.bold(14, tab == current ? AppColors.navy : AppColors.gray),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
