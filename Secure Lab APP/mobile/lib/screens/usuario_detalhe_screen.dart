import 'package:flutter/material.dart';

import '../core/session.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../widgets/app_header.dart';
import '../widgets/common.dart';
import '../widgets/figma_icon.dart';
import 'cadastro_biometria_screen.dart';
import 'usuario_form_screen.dart';

/// Detalhe do usuário: dados, digitais vinculadas, últimos acessos,
/// editar, desativar (DELETE = soft delete) e reativar (PATCH ativo=true).
class UsuarioDetalheScreen extends StatefulWidget {
  const UsuarioDetalheScreen({super.key, required this.usuario});

  final Usuario usuario;

  @override
  State<UsuarioDetalheScreen> createState() => _UsuarioDetalheScreenState();
}

class _UsuarioDetalheScreenState extends State<UsuarioDetalheScreen> {
  late Usuario _u = widget.usuario;
  List<Digital>? _digitais;
  List<Acesso>? _acessos;
  Object? _erro;
  bool _ocupado = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final api = AppScope.read(context).api;
    try {
      final r = await Future.wait([
        api.digitais(usuarioId: _u.id),
        api.acessos(usuarioId: _u.id, limit: 5),
      ]);
      if (!mounted) return;
      setState(() {
        _digitais = r[0] as List<Digital>;
        _acessos = (r[1] as Pagina<Acesso>).itens;
        _erro = null;
      });
    } catch (e) {
      if (mounted) setState(() => _erro = e);
    }
  }

  Future<void> _editar() async {
    final novo = await Navigator.of(context).push<Usuario>(
      MaterialPageRoute(builder: (_) => UsuarioFormScreen(usuario: _u)),
    );
    if (novo != null) setState(() => _u = novo);
  }

  Future<void> _alternarAtivo() async {
    final desativar = _u.ativo;
    if (desativar) {
      final ok = await _confirmar(
        'Desativar ${_u.nome}?',
        'O usuário deixa de ser autorizado em qualquer porta. O histórico é mantido e você pode reativar depois.',
        'Desativar',
      );
      if (!ok) return;
    }
    setState(() => _ocupado = true);
    final api = AppScope.read(context).api;
    try {
      final u = desativar ? await api.desativarUsuario(_u.id) : await api.atualizarUsuario(_u.id, ativo: true);
      if (!mounted) return;
      setState(() => _u = u);
      showMessage(context, desativar ? 'Usuário desativado.' : 'Usuário reativado.');
    } catch (e) {
      if (mounted) showMessage(context, errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _removerDigital(Digital d) async {
    final ok = await _confirmar(
      'Remover digital #${d.templateId}?',
      'Leituras desse template passam a ser NEGADAS. Lembre de apagar a digital também na memória do sensor.',
      'Remover',
    );
    if (!ok || !mounted) return;
    try {
      await AppScope.read(context).api.removerDigital(d.id);
      if (mounted) showMessage(context, 'Digital removida.');
      _carregar();
    } catch (e) {
      if (mounted) showMessage(context, errorText(e), error: true);
    }
  }

  Future<void> _cadastrarBiometria() async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CadastroBiometriaScreen(usuario: _u)),
    );
    if (ok == true) _carregar();
  }

  Future<bool> _confirmar(String titulo, String texto, String acao) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: Text(texto),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(acao, style: const TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    return r == true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          DetailHeader(
            title: 'Usuário',
            child: Row(children: [
              InitialsBox(
                text: initialsOf(_u.nome),
                color: _u.ativo ? AppColors.avatarFor(_u.id) : AppColors.gray,
                size: 56,
                fontSize: 22,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_u.nome, style: AppText.bold(20, Colors.white)),
                    Text(_u.email ?? 'Sem e-mail', style: AppText.regular(15, AppColors.blue)),
                    Text(_u.ativo ? 'Ativo' : 'Inativo',
                        style: AppText.bold(14, _u.ativo ? AppColors.green : AppColors.red)),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Editar',
                onPressed: _editar,
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
              ),
            ]),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _carregar,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(children: [
                    Expanded(child: Text('Biometria', style: AppText.bold(22))),
                    TextButton.icon(
                      onPressed: _u.ativo ? _cadastrarBiometria : null,
                      icon: const Icon(Icons.add),
                      label: const Text('Cadastrar'),
                    ),
                  ]),
                  if (!_u.ativo)
                    Text('Reative o usuário para cadastrar novas digitais.', style: AppText.regular(13, AppColors.gray)),
                  const SizedBox(height: 8),
                  ..._secaoDigitais(),
                  const SizedBox(height: 16),
                  Text('Últimos acessos', style: AppText.bold(22)),
                  const SizedBox(height: 8),
                  ..._secaoAcessos(),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: _ocupado ? null : _alternarAtivo,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      foregroundColor: _u.ativo ? AppColors.red : AppColors.green,
                      side: BorderSide(color: _u.ativo ? AppColors.red : AppColors.green),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: Icon(_u.ativo ? Icons.person_off_outlined : Icons.person_add_alt),
                    label: Text(_u.ativo ? 'Desativar usuário' : 'Reativar usuário'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _secaoDigitais() {
    if (_erro != null && _digitais == null) return [ErrorView(error: _erro!, onRetry: _carregar)];
    if (_digitais == null) return const [LoadingView()];
    if (_digitais!.isEmpty) {
      return [EmptyView('Nenhuma digital cadastrada.')];
    }
    return [
      for (final d in _digitais!)
        ListCard(
          minHeight: 64,
          child: Row(children: [
            const FigmaIcon(AppIcons.fingerprintBlue, size: 40),
            const SizedBox(width: 14),
            Expanded(child: Text('Template #${d.templateId}', style: AppText.regular(18))),
            IconButton(
              tooltip: 'Remover digital',
              onPressed: () => _removerDigital(d),
              icon: const Icon(Icons.delete_outline, color: AppColors.red),
            ),
          ]),
        ),
    ];
  }

  List<Widget> _secaoAcessos() {
    if (_acessos == null) return _erro == null ? const [LoadingView()] : const [];
    if (_acessos!.isEmpty) return [EmptyView('Nenhum acesso registrado.')];
    return [
      for (final a in _acessos!)
        ListCard(
          minHeight: 60,
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(a.dispositivoNome ?? 'Dispositivo ${a.dispositivoId}', style: AppText.regular(17)),
                Text('${formatDate(a.dataHora)} às ${formatHour(a.dataHora)}',
                    style: AppText.regular(14, AppColors.gray)),
              ]),
            ),
            Text(a.autorizado ? 'Autorizado' : 'Negado',
                style: AppText.regular(15, a.autorizado ? AppColors.green : AppColors.red)),
          ]),
        ),
    ];
  }
}
