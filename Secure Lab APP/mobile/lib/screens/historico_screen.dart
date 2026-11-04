import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/session.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../widgets/app_header.dart';
import '../widgets/common.dart';
import '../widgets/figma_icon.dart';

/// Tela "Histórico" do Figma: GET /acessos com filtro por resultado e paginação
/// (header X-Total-Count).
class HistoricoScreen extends StatefulWidget {
  const HistoricoScreen({super.key, this.filtroInicial = 0});

  /// 0 Todos, 1 Autorizados, 2 Negados.
  final int filtroInicial;

  @override
  State<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen> {
  static const _pagina = 50;

  late int _filtro = widget.filtroInicial;
  String _busca = '';
  final List<Acesso> _itens = [];
  int _total = 0;
  int _hoje = 0;
  int _negadosHoje = 0;
  bool _carregando = true;
  bool _carregandoMais = false;
  Object? _erro;

  String? get _resultado => switch (_filtro) { 1 => 'AUTORIZADO', 2 => 'NEGADO', _ => null };

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    final api = AppScope.read(context).api;
    final hoje = DateTime.now();
    try {
      final r = await Future.wait([
        api.acessos(limit: _pagina, resultado: _resultado),
        api.contarAcessos(dia: hoje),
        api.contarAcessos(dia: hoje, resultado: 'NEGADO'),
      ]);
      if (!mounted) return;
      final p = r[0] as Pagina<Acesso>;
      setState(() {
        _itens
          ..clear()
          ..addAll(p.itens);
        _total = p.total;
        _hoje = r[1] as int;
        _negadosHoje = r[2] as int;
      });
    } catch (e) {
      if (mounted) setState(() => _erro = e);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _maisItens() async {
    if (_carregandoMais || _itens.length >= _total) return;
    setState(() => _carregandoMais = true);
    try {
      final p = await AppScope.read(context)
          .api
          .acessos(limit: _pagina, offset: _itens.length, resultado: _resultado);
      if (mounted) setState(() => _itens.addAll(p.itens));
    } catch (e) {
      if (mounted) showMessage(context, errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _carregandoMais = false);
    }
  }

  void _trocarFiltro(int f) {
    if (f == _filtro) return;
    _filtro = f;
    _carregar();
  }

  List<Acesso> get _visiveis {
    final q = _busca.trim().toLowerCase();
    if (q.isEmpty) return _itens;
    return _itens
        .where((a) =>
            (a.usuarioNome ?? 'desconhecido').toLowerCase().contains(q) ||
            (a.dispositivoNome ?? '').toLowerCase().contains(q))
        .toList();
  }

  /// Copia os registros carregados como CSV (abre no Excel).
  Future<void> _exportar() async {
    final linhas = <String>['data;hora;usuario;ambiente;template;resultado'];
    for (final a in _visiveis) {
      linhas.add([
        formatDate(a.dataHora),
        formatHour(a.dataHora),
        a.usuarioNome ?? 'Desconhecido',
        a.dispositivoNome ?? '${a.dispositivoId}',
        a.templateIdLido?.toString() ?? '',
        a.resultado,
      ].map((c) => c.replaceAll(';', ',')).join(';'));
    }
    await Clipboard.setData(ClipboardData(text: linhas.join('\n')));
    if (mounted) showMessage(context, '${linhas.length - 1} registros copiados como CSV.');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppHeader(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HeaderTitle(title: 'Histórico', subtitle: '$_total registros . $_hoje hoje'),
              const SizedBox(height: 8),
              Row(children: [
                StatChip(value: '$_hoje', label: 'Hoje', color: AppColors.green),
                const SizedBox(width: 12),
                StatChip(value: '$_negadosHoje', label: 'Negados', color: AppColors.red,
                    onTap: () => _trocarFiltro(2)),
                const Spacer(),
                HeaderSquareButton(
                  icon: AppIcons.download,
                  tooltip: 'Copiar como CSV',
                  onTap: _exportar,
                  color: const Color(0x80D9D9D9),
                  width: 50,
                  height: 50,
                ),
              ]),
              const SizedBox(height: 12),
              NavySearchField(
                hint: 'Buscar por usuário ou ambiente...',
                onChanged: (v) => setState(() => _busca = v),
              ),
            ],
          ),
        ),
        SegmentTabs(
          labels: const ['Todos', 'Autorizados', 'Negados'],
          selected: _filtro,
          onChanged: _trocarFiltro,
        ),
        Expanded(child: RefreshIndicator(onRefresh: _carregar, child: _lista())),
      ],
    );
  }

  Widget _lista() {
    if (_carregando && _itens.isEmpty) return ListView(children: const [LoadingView()]);
    if (_erro != null) return ListView(children: [ErrorView(error: _erro!, onRetry: _carregar)]);
    final itens = _visiveis;
    if (itens.isEmpty) return ListView(children: const [EmptyView('Nenhum registro de acesso.')]);

    final temMais = _busca.isEmpty && _itens.length < _total;
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (temMais && n.metrics.pixels > n.metrics.maxScrollExtent - 300) _maisItens();
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
        itemCount: itens.length + (temMais ? 1 : 0),
        itemBuilder: (_, i) {
          if (i >= itens.length) return const LoadingView();
          final a = itens[i];
          final mostrarData = i == 0 || !_mesmoDia(itens[i - 1].dataHora, a.dataHora);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (mostrarData)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8, top: 2),
                  child: Text(_rotuloDia(a.dataHora), style: AppText.bold(15, AppColors.gray)),
                ),
              _AcessoCard(a: a),
            ],
          );
        },
      ),
    );
  }

  bool _mesmoDia(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  String _rotuloDia(DateTime d) {
    final hoje = DateTime.now();
    if (_mesmoDia(d, hoje)) return 'Hoje';
    if (_mesmoDia(d, hoje.subtract(const Duration(days: 1)))) return 'Ontem';
    return formatDate(d);
  }
}

class _AcessoCard extends StatelessWidget {
  const _AcessoCard({required this.a});

  final Acesso a;

  @override
  Widget build(BuildContext context) {
    final conhecido = a.usuarioNome != null;
    final nome = a.usuarioNome ?? 'Desconhecido';
    return ListCard(
      child: Row(children: [
        InitialsBox(
          text: conhecido ? initialsOf(nome) : '?',
          color: conhecido ? AppColors.avatarFor(a.usuarioId ?? 0) : AppColors.red,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(nome, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.regular(20)),
            Text(a.dispositivoNome ?? 'Dispositivo ${a.dispositivoId}', maxLines: 1, overflow: TextOverflow.ellipsis,
                style: AppText.regular(15, AppColors.gray)),
            Text(
              a.templateIdLido == null ? 'Impressão Digital' : 'Impressão Digital #${a.templateIdLido}',
              style: AppText.regular(15, AppColors.gray),
            ),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(a.autorizado ? 'Autorizado' : 'Negado',
              style: AppText.regular(15, a.autorizado ? AppColors.green : AppColors.red)),
          const SizedBox(height: 8),
          Text(formatHour(a.dataHora), style: AppText.regular(15, AppColors.gray)),
        ]),
      ]),
    );
  }
}
