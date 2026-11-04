import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/session.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../widgets/app_header.dart';
import '../widgets/common.dart';
import '../widgets/figma_icon.dart';
import 'usuario_form_screen.dart' show formDecoration;

/// Tela "Ambientes" do Figma. Cada ambiente é um dispositivo (ESP32 + sensor + fechadura).
/// "Operacional" = dispositivo ativo; "Manutenção" = dispositivo desativado.
class AmbientesScreen extends StatefulWidget {
  const AmbientesScreen({super.key, this.filtroInicial = 0});

  final int filtroInicial;

  @override
  State<AmbientesScreen> createState() => _AmbientesScreenState();
}

class _AmbientesScreenState extends State<AmbientesScreen> {
  late int _filtro = widget.filtroInicial;
  List<Dispositivo>? _itens;
  Object? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final itens = await AppScope.read(context).api.dispositivos();
      if (mounted) setState(() {
        _itens = itens;
        _erro = null;
      });
    } catch (e) {
      if (mounted) setState(() => _erro = e);
    }
  }

  Future<void> _novo() async {
    final criado = await showModalBottomSheet<DispositivoComChave>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      builder: (_) => const _NovoAmbienteSheet(),
    );
    if (criado == null || !mounted) return;
    await mostrarChave(context, criado);
    _carregar();
  }

  @override
  Widget build(BuildContext context) {
    final todos = _itens ?? [];
    final ativos = todos.where((d) => d.ativo).length;
    final visiveis = todos.where((d) => _filtro == 0 || (_filtro == 1 ? d.ativo : !d.ativo)).toList();

    return Column(
      children: [
        AppHeader(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HeaderTitle(
                title: 'Ambientes',
                subtitle: '${todos.length} cadastrados . $ativos ativos',
                trailing: HeaderSquareButton(icon: AppIcons.plus, tooltip: 'Novo ambiente', onTap: _novo),
              ),
              const SizedBox(height: 10),
              Row(children: [
                StatChip(value: '$ativos', label: 'Ativos', color: AppColors.green,
                    onTap: () => setState(() => _filtro = 1)),
                const SizedBox(width: 12),
                StatChip(value: '${todos.length - ativos}', label: 'Manutenção', color: AppColors.yellow,
                    onTap: () => setState(() => _filtro = 2)),
              ]),
            ],
          ),
        ),
        SegmentTabs(
          labels: const ['Todos', 'Ativos', 'Manutenção'],
          selected: _filtro,
          onChanged: (i) => setState(() => _filtro = i),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _carregar,
            child: Builder(builder: (context) {
              if (_erro != null && _itens == null) {
                return ListView(children: [ErrorView(error: _erro!, onRetry: _carregar)]);
              }
              if (_itens == null) return ListView(children: const [LoadingView()]);
              if (visiveis.isEmpty) {
                return ListView(children: [
                  EmptyView(todos.isEmpty ? 'Nenhum ambiente cadastrado.\nToque no + para adicionar.' : 'Nenhum ambiente aqui.'),
                ]);
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
                itemCount: visiveis.length,
                itemBuilder: (_, i) => _AmbienteCard(
                  d: visiveis[i],
                  onTap: () => _detalhe(visiveis[i]),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  void _detalhe(Dispositivo d) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      builder: (_) => _AmbienteDetalheSheet(d: d),
    );
  }
}

/// Ícone do card escolhido pelo nome, como no protótipo (servidor, controle, laboratório).
AppIcon iconeDoAmbiente(String nome) {
  final n = nome.toLowerCase();
  if (n.contains('servidor') || n.contains('server') || n.contains('rede')) return AppIcons.serverWhite;
  if (n.contains('controle') || n.contains('energia') || n.contains('elétric')) return AppIcons.adjust;
  return AppIcons.workstation;
}

class _AmbienteCard extends StatelessWidget {
  const _AmbienteCard({required this.d, this.onTap});

  final Dispositivo d;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListCard(
      onTap: onTap,
      child: Row(children: [
        Container(
          width: 50,
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.blue,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0x1A000000)),
            boxShadow: AppColors.shadow,
          ),
          child: FigmaIcon(iconeDoAmbiente(d.nome), size: 30),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d.nome, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.regular(20)),
            const SizedBox(height: 4),
            Text(d.local ?? 'Local não informado', maxLines: 1, overflow: TextOverflow.ellipsis,
                style: AppText.regular(15, AppColors.gray)),
          ]),
        ),
        StatusDot(
          label: d.ativo ? 'Operacional' : 'Manutenção',
          color: d.ativo ? AppColors.green : AppColors.yellowText,
        ),
      ]),
    );
  }
}

class _AmbienteDetalheSheet extends StatefulWidget {
  const _AmbienteDetalheSheet({required this.d});

  final Dispositivo d;

  @override
  State<_AmbienteDetalheSheet> createState() => _AmbienteDetalheSheetState();
}

class _AmbienteDetalheSheetState extends State<_AmbienteDetalheSheet> {
  bool _gerando = false;

  Future<void> _novaChave() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gerar nova chave?'),
        content: const Text(
            'A chave atual deixa de funcionar na hora. O ESP32 deste ambiente só volta a registrar acessos depois de receber a chave nova.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Gerar')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _gerando = true);
    try {
      final r = await AppScope.read(context).api.novaChave(widget.d.id);
      if (!mounted) return;
      final nav = Navigator.of(context);
      await mostrarChave(context, r);
      nav.pop();
    } catch (e) {
      if (mounted) showMessage(context, errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _gerando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.d;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(d.nome, style: AppText.bold(24)),
            Text(d.local ?? 'Local não informado', style: AppText.regular(16, AppColors.gray)),
            const SizedBox(height: 12),
            Row(children: [
              StatusDot(label: d.ativo ? 'Operacional' : 'Manutenção',
                  color: d.ativo ? AppColors.green : AppColors.yellowText),
              const Spacer(),
              Text('ID do dispositivo: ${d.id}', style: AppText.bold(15, AppColors.gray)),
            ]),
            const SizedBox(height: 14),
            Text(
              'O dispositivo_id e a chave de API vão no código do ESP32. '
              'Ativar ou colocar em manutenção ainda não tem rota na API (é feito direto no banco).',
              style: AppText.regular(13, AppColors.gray),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _gerando ? null : _novaChave,
              icon: const Icon(Icons.key),
              label: const Text('Gerar nova chave de API'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NovoAmbienteSheet extends StatefulWidget {
  const _NovoAmbienteSheet();

  @override
  State<_NovoAmbienteSheet> createState() => _NovoAmbienteSheetState();
}

class _NovoAmbienteSheetState extends State<_NovoAmbienteSheet> {
  final _nome = TextEditingController();
  final _local = TextEditingController();
  bool _salvando = false;

  @override
  void dispose() {
    _nome.dispose();
    _local.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_nome.text.trim().isEmpty) {
      showMessage(context, 'Informe o nome do ambiente.', error: true);
      return;
    }
    setState(() => _salvando = true);
    try {
      final r = await AppScope.read(context).api.criarDispositivo(nome: _nome.text.trim(), local: _local.text);
      if (mounted) Navigator.of(context).pop(r);
    } catch (e) {
      if (mounted) showMessage(context, errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(22, 18, 22, 22 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Novo ambiente', style: AppText.bold(24)),
          const SizedBox(height: 14),
          TextField(
            controller: _nome,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: formDecoration('Nome (ex: Porta Lab 1)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _local,
            textCapitalization: TextCapitalization.sentences,
            decoration: formDecoration('Local (ex: Bloco A - Piso 1)'),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: _salvando ? null : _salvar,
            child: _salvando
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                : const Text('Cadastrar e gerar chave'),
          ),
        ],
      ),
    );
  }
}

/// A API mostra a chave uma única vez, então o diálogo insiste em copiar.
Future<void> mostrarChave(BuildContext context, DispositivoComChave r) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Text('Chave de "${r.dispositivo.nome}"'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('dispositivo_id: ${r.dispositivo.id}', style: AppText.bold(15)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(8)),
            child: SelectableText(r.apiKey, style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
          ),
          const SizedBox(height: 10),
          Text(
            'Esta chave aparece só agora. Copie e entregue ao responsável pelo ESP32 (não suba para o GitHub).',
            style: AppText.regular(13, AppColors.red),
          ),
        ],
      ),
      actions: [
        TextButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: r.apiKey));
            if (ctx.mounted) {
              ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Chave copiada.')));
            }
          },
          icon: const Icon(Icons.copy),
          label: const Text('Copiar'),
        ),
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Já copiei')),
      ],
    ),
  );
}
