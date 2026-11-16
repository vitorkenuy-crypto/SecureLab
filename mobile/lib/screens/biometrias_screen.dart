import 'package:flutter/material.dart';

import '../core/session.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../widgets/app_header.dart';
import '../widgets/common.dart';
import '../widgets/figma_icon.dart';
import 'cadastro_biometria_screen.dart';

/// Configurações > Biometria: todas as digitais cadastradas, com o dono de cada uma.
class BiometriasScreen extends StatefulWidget {
  const BiometriasScreen({super.key});

  @override
  State<BiometriasScreen> createState() => _BiometriasScreenState();
}

class _BiometriasScreenState extends State<BiometriasScreen> {
  List<Digital>? _digitais;
  Map<int, Usuario> _usuarios = {};
  Object? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final api = AppScope.read(context).api;
    try {
      final r = await Future.wait([api.digitais(), api.usuarios()]);
      if (!mounted) return;
      setState(() {
        _digitais = (r[0] as List<Digital>)..sort((a, b) => a.templateId.compareTo(b.templateId));
        _usuarios = {for (final u in r[1] as List<Usuario>) u.id: u};
        _erro = null;
      });
    } catch (e) {
      if (mounted) setState(() => _erro = e);
    }
  }

  Future<void> _remover(Digital d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remover digital #${d.templateId}?'),
        content: const Text('Leituras desse template passam a ser NEGADAS. Apague também na memória do sensor.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Remover', style: TextStyle(color: AppColors.red))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await AppScope.read(context).api.removerDigital(d.id);
      if (mounted) showMessage(context, 'Digital removida.');
      _carregar();
    } catch (e) {
      if (mounted) showMessage(context, errorText(e), error: true);
    }
  }

  Future<void> _nova() async {
    final ok = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => const CadastroBiometriaScreen()));
    if (ok == true) _carregar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nova,
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.fingerprint),
        label: const Text('Cadastrar'),
      ),
      body: Column(
        children: [
          DetailHeader(
            title: 'Biometria',
            child: Text(
              _digitais == null ? 'Carregando...' : '${_digitais!.length} digitais cadastradas',
              style: AppText.bold(15, AppColors.blue),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _carregar,
              child: Builder(builder: (_) {
                if (_erro != null && _digitais == null) {
                  return ListView(children: [ErrorView(error: _erro!, onRetry: _carregar)]);
                }
                if (_digitais == null) return ListView(children: const [LoadingView()]);
                if (_digitais!.isEmpty) return ListView(children: const [EmptyView('Nenhuma digital cadastrada.')]);
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
                  itemCount: _digitais!.length,
                  itemBuilder: (_, i) {
                    final d = _digitais![i];
                    final u = _usuarios[d.usuarioId];
                    return ListCard(
                      minHeight: 72,
                      child: Row(children: [
                        const FigmaIcon(AppIcons.fingerprintBlue, size: 44),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(u?.nome ?? 'Usuário ${d.usuarioId}', style: AppText.regular(19)),
                            Text(
                              'Template #${d.templateId}${u != null && !u.ativo ? ' · usuário inativo' : ''}',
                              style: AppText.regular(14, u != null && !u.ativo ? AppColors.red : AppColors.gray),
                            ),
                          ]),
                        ),
                        IconButton(
                          tooltip: 'Remover',
                          onPressed: () => _remover(d),
                          icon: const Icon(Icons.delete_outline, color: AppColors.red),
                        ),
                      ]),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
