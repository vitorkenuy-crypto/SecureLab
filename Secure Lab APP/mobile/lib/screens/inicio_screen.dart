import 'package:flutter/material.dart';

import '../core/session.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../widgets/app_header.dart';
import '../widgets/common.dart';
import '../widgets/figma_icon.dart';
import 'home_shell.dart';

/// Resumo usado pela tela Início, montado com várias chamadas à API.
class _Resumo {
  bool apiOnline = false;
  List<Usuario> usuarios = [];
  List<Dispositivo> dispositivos = [];
  int autorizadosHoje = 0;
  int autorizadosOntem = 0;
  int negadosHoje = 0;
  int totalHoje = 0;

  int get usuariosAtivos => usuarios.where((u) => u.ativo).length;
  int get dispositivosAtivos => dispositivos.where((d) => d.ativo).length;
  int get emManutencao => dispositivos.length - dispositivosAtivos;
}

class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  late Future<_Resumo> _future;

  @override
  void initState() {
    super.initState();
    _future = _carregar();
  }

  Future<_Resumo> _carregar() async {
    final api = AppScope.read(context).api;
    final hoje = DateTime.now();
    final ontem = hoje.subtract(const Duration(days: 1));
    final r = _Resumo();
    final results = await Future.wait([
      api.ping(),
      api.usuarios(),
      api.dispositivos(),
      api.contarAcessos(resultado: 'AUTORIZADO', dia: hoje),
      api.contarAcessos(resultado: 'AUTORIZADO', dia: ontem),
      api.contarAcessos(resultado: 'NEGADO', dia: hoje),
    ]);
    r.apiOnline = results[0] as bool;
    r.usuarios = results[1] as List<Usuario>;
    r.dispositivos = results[2] as List<Dispositivo>;
    r.autorizadosHoje = results[3] as int;
    r.autorizadosOntem = results[4] as int;
    r.negadosHoje = results[5] as int;
    r.totalHoje = r.autorizadosHoje + r.negadosHoje;
    return r;
  }

  Future<void> _refresh() async {
    final f = _carregar();
    setState(() => _future = f);
    await f;
    if (mounted) HomeShell.of(context).atualizarAlertas();
  }

  @override
  Widget build(BuildContext context) {
    final nome = AppScope.of(context).username ?? 'Admin';
    return Column(
      children: [
        const AppHeader(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 24),
              children: [
                Text('Olá, $nome', style: AppText.bold(30)),
                Text('Veja o que está acontecendo no sistema.', style: AppText.bold(15, AppColors.gray)),
                const SizedBox(height: 10),
                FutureBuilder<_Resumo>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.connectionState != ConnectionState.done) return const LoadingView();
                    if (snap.hasError) {
                      return Column(children: [
                        const _SistemaCard(online: false, dispositivosOnline: 0, taxa: 0),
                        ErrorView(error: snap.error!, onRetry: _refresh),
                      ]);
                    }
                    return _conteudo(snap.data!);
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _conteudo(_Resumo r) {
    final shell = HomeShell.of(context);
    final taxa = r.totalHoje == 0 ? 1.0 : r.autorizadosHoje / r.totalHoje;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SistemaCard(online: r.apiOnline, dispositivosOnline: r.dispositivosAtivos, taxa: taxa),
        const SizedBox(height: 22),
        Text('Visão geral', style: AppText.bold(25)),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 20,
          crossAxisSpacing: 24,
          childAspectRatio: 160 / 146,
          children: [
            _StatCard(
              icon: AppIcons.userDark,
              tint: AppColors.green,
              valor: r.usuarios.length,
              titulo: 'Usuários',
              detalhe: '${r.usuariosAtivos} ativos',
              detalheCor: AppColors.green,
              onTap: () => shell.goTo(AppTab.usuarios),
            ),
            _StatCard(
              icon: AppIcons.doorDark,
              tint: AppColors.yellow,
              valor: r.dispositivos.length,
              titulo: 'Ambientes',
              detalhe: r.emManutencao == 0 ? 'todos operacionais' : '${r.emManutencao} em manutenção',
              detalheCor: r.emManutencao == 0 ? AppColors.green : AppColors.yellowText,
              onTap: () => shell.goTo(AppTab.ambientes),
            ),
            _StatCard(
              icon: AppIcons.enter,
              tint: AppColors.green,
              valor: r.autorizadosHoje,
              titulo: 'Acessos hoje',
              detalhe: _comparativo(r.autorizadosHoje, r.autorizadosOntem),
              detalheCor: r.autorizadosHoje >= r.autorizadosOntem ? AppColors.green : AppColors.red,
              onTap: () => shell.goTo(AppTab.historico, filtro: 1),
            ),
            _StatCard(
              icon: AppIcons.cancel,
              tint: AppColors.red,
              valor: r.negadosHoje,
              titulo: 'Negadas',
              detalhe: r.negadosHoje == 0 ? 'nenhuma hoje' : '${r.negadosHoje} hoje',
              detalheCor: r.negadosHoje == 0 ? AppColors.green : AppColors.red,
              onTap: () => shell.goTo(AppTab.historico, filtro: 2),
            ),
          ],
        ),
      ],
    );
  }

  String _comparativo(int hoje, int ontem) {
    if (ontem == 0) return hoje == 0 ? 'sem acessos ontem' : 'ontem: 0';
    final pct = ((hoje - ontem) / ontem * 100).round();
    return '${pct >= 0 ? '+' : ''}$pct% vs. ontem';
  }
}

/// Card azul-marinho "Sistema Operacional".
class _SistemaCard extends StatelessWidget {
  const _SistemaCard({required this.online, required this.dispositivosOnline, required this.taxa});

  final bool online;
  final int dispositivosOnline;
  final double taxa;

  @override
  Widget build(BuildContext context) {
    final cor = online ? AppColors.green : AppColors.red;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 22),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: cor,
                          shape: BoxShape.circle,
                          border: Border.all(color: cor.withAlpha(0x66), width: 3),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(online ? 'Sistema Operacional' : 'API indisponível', style: AppText.bold(15, cor)),
                    ]),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.only(left: 13),
                      child: Text(
                        online ? 'Todos os Sistemas Funcionando' : 'Verifique o servidor da API',
                        style: AppText.bold(23, Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 72,
                height: 69,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(color: AppColors.tint(AppColors.blue), borderRadius: BorderRadius.circular(20)),
                child: const Stack(
                  alignment: Alignment.center,
                  children: [
                    FigmaIcon(AppIcons.shieldBlue, size: 41),
                    FigmaIcon(AppIcons.checkBlue, size: 22),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 13),
            child: Row(children: [
              const FigmaIcon(AppIcons.serverBlue, size: 20),
              const SizedBox(width: 6),
              Text(
                '$dispositivosOnline ${dispositivosOnline == 1 ? 'dispositivo ativo' : 'dispositivos ativos'}',
                style: AppText.bold(15, AppColors.blue),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: Text('Taxa de autorização hoje', style: AppText.bold(15, Colors.white))),
            Text('${(taxa * 100).toStringAsFixed(1).replaceAll('.', ',')}%', style: AppText.bold(15, AppColors.green)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: taxa.clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: AppColors.red.withAlpha(0x99),
              color: AppColors.green,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.tint,
    required this.valor,
    required this.titulo,
    required this.detalhe,
    required this.detalheCor,
    this.onTap,
  });

  final AppIcon icon;
  final Color tint;
  final int valor;
  final String titulo;
  final String detalhe;
  final Color detalheCor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x0D000000)),
        boxShadow: AppColors.shadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 50,
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.tint(tint),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: AppColors.shadow,
                    ),
                    child: FigmaIcon(icon, size: 30),
                  ),
                  const Spacer(),
                  Text(two(valor), style: AppText.bold(38)),
                ]),
                const Spacer(),
                FittedBox(fit: BoxFit.scaleDown, child: Text(titulo, style: AppText.bold(19, AppColors.gray))),
                const SizedBox(height: 4),
                FittedBox(fit: BoxFit.scaleDown, child: Text(detalhe, style: AppText.bold(14, detalheCor))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
