import 'package:flutter/material.dart';

import '../core/session.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../widgets/app_header.dart';
import '../widgets/common.dart';
import '../widgets/figma_icon.dart';
import 'usuario_detalhe_screen.dart';
import 'usuario_form_screen.dart';

/// Tela "Usuários" do Figma: GET /usuarios + GET /digitais (para saber quem tem biometria).
///
/// O protótipo tem a aba "Suspensos", mas a API só conhece ativo/inativo,
/// então as abas são Todos / Ativos / Inativos.
class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key, this.filtroInicial = 0});

  final int filtroInicial;

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  late int _filtro = widget.filtroInicial;
  String _busca = '';
  List<Usuario>? _usuarios;
  Set<int> _comBiometria = {};
  Object? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final api = AppScope.read(context).api;
    try {
      final r = await Future.wait([api.usuarios(), api.digitais()]);
      if (!mounted) return;
      setState(() {
        _usuarios = (r[0] as List<Usuario>)..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
        _comBiometria = (r[1] as List<Digital>).map((d) => d.usuarioId).toSet();
        _erro = null;
      });
    } catch (e) {
      if (mounted) setState(() => _erro = e);
    }
  }

  Future<void> _novo() async {
    final criado = await Navigator.of(context).push<Usuario>(
      MaterialPageRoute(builder: (_) => const UsuarioFormScreen()),
    );
    if (criado != null) {
      _carregar();
      if (mounted) _abrir(criado);
    }
  }

  Future<void> _abrir(Usuario u) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => UsuarioDetalheScreen(usuario: u)));
    _carregar();
  }

  List<Usuario> get _visiveis {
    final q = _busca.trim().toLowerCase();
    return (_usuarios ?? []).where((u) {
      if (_filtro == 1 && !u.ativo) return false;
      if (_filtro == 2 && u.ativo) return false;
      if (q.isEmpty) return true;
      return u.nome.toLowerCase().contains(q) || (u.email ?? '').toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final todos = _usuarios ?? [];
    final ativos = todos.where((u) => u.ativo).length;
    final biometria = todos.where((u) => u.ativo && _comBiometria.contains(u.id)).length;

    return Column(
      children: [
        AppHeader(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HeaderTitle(
                title: 'Usuários',
                subtitle: '${todos.length} cadastrados . $ativos ativos',
                trailing: HeaderSquareButton(icon: AppIcons.plus, tooltip: 'Novo usuário', onTap: _novo),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  StatChip(value: '$ativos', label: 'Ativos', color: AppColors.green,
                      onTap: () => setState(() => _filtro = 1)),
                  const SizedBox(width: 12),
                  StatChip(value: '${todos.length - ativos}', label: 'Inativos', color: AppColors.yellow,
                      onTap: () => setState(() => _filtro = 2)),
                  const SizedBox(width: 12),
                  StatChip(value: '$biometria', label: 'Biometria ativa', color: AppColors.blue),
                ]),
              ),
              const SizedBox(height: 16),
              NavySearchField(hint: 'Buscar por nome ou e-mail...', onChanged: (v) => setState(() => _busca = v)),
            ],
          ),
        ),
        SegmentTabs(
          labels: const ['Todos', 'Ativos', 'Inativos'],
          selected: _filtro,
          onChanged: (i) => setState(() => _filtro = i),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _carregar,
            child: _lista(),
          ),
        ),
      ],
    );
  }

  Widget _lista() {
    if (_erro != null && _usuarios == null) {
      return ListView(children: [ErrorView(error: _erro!, onRetry: _carregar)]);
    }
    if (_usuarios == null) return ListView(children: const [LoadingView()]);
    final itens = _visiveis;
    if (itens.isEmpty) {
      return ListView(children: [
        EmptyView(_usuarios!.isEmpty ? 'Nenhum usuário cadastrado.\nToque no + para adicionar.' : 'Nenhum usuário encontrado.'),
      ]);
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
      itemCount: itens.length,
      itemBuilder: (_, i) => UsuarioCard(
        usuario: itens[i],
        temBiometria: _comBiometria.contains(itens[i].id),
        onTap: () => _abrir(itens[i]),
      ),
    );
  }
}

class UsuarioCard extends StatelessWidget {
  const UsuarioCard({super.key, required this.usuario, required this.temBiometria, this.onTap});

  final Usuario usuario;
  final bool temBiometria;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final u = usuario;
    return ListCard(
      onTap: onTap,
      child: Row(
        children: [
          InitialsBox(text: initialsOf(u.nome), color: u.ativo ? AppColors.avatarFor(u.id) : AppColors.gray),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(u.nome, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.regular(20)),
                Text(u.email ?? 'Sem e-mail', maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: AppText.regular(15, AppColors.gray)),
                const SizedBox(height: 2),
                Row(children: [
                  Text(u.ativo ? 'Ativo' : 'Inativo', style: AppText.regular(15, u.ativo ? AppColors.green : AppColors.red)),
                  const SizedBox(width: 14),
                  Text(temBiometria ? 'Biometria cadastrada' : 'Sem biometria',
                      style: AppText.regular(15, AppColors.gray)),
                ]),
              ],
            ),
          ),
          const FigmaIcon(AppIcons.forward, size: 40),
        ],
      ),
    );
  }
}
