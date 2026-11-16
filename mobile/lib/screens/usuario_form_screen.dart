import 'package:flutter/material.dart';

import '../core/session.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../widgets/app_header.dart';
import '../widgets/common.dart';

/// Cria (POST /usuarios) ou edita (PATCH /usuarios/{id}) um usuário.
class UsuarioFormScreen extends StatefulWidget {
  const UsuarioFormScreen({super.key, this.usuario});

  final Usuario? usuario;

  @override
  State<UsuarioFormScreen> createState() => _UsuarioFormScreenState();
}

class _UsuarioFormScreenState extends State<UsuarioFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _nome = TextEditingController(text: widget.usuario?.nome);
  late final _email = TextEditingController(text: widget.usuario?.email);
  bool _salvando = false;

  bool get _editando => widget.usuario != null;

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _salvando = true);
    final api = AppScope.read(context).api;
    try {
      final u = _editando
          ? await api.atualizarUsuario(widget.usuario!.id, nome: _nome.text.trim(), email: _email.text)
          : await api.criarUsuario(nome: _nome.text.trim(), email: _email.text);
      if (!mounted) return;
      showMessage(context, _editando ? 'Usuário atualizado.' : 'Usuário cadastrado.');
      Navigator.of(context).pop(u);
    } catch (e) {
      if (mounted) showMessage(context, errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          DetailHeader(title: _editando ? 'Editar usuário' : 'Novo usuário'),
          Expanded(
            child: Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _label('Nome completo'),
                  TextFormField(
                    controller: _nome,
                    textCapitalization: TextCapitalization.words,
                    decoration: _decoration('Ex: Ana Oliveira'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
                  ),
                  const SizedBox(height: 18),
                  _label('E-mail (opcional)'),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: _decoration('ana.oliveira@email.com'),
                    validator: (v) {
                      final t = v?.trim() ?? '';
                      if (t.isEmpty) return null;
                      return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t) ? null : 'E-mail inválido';
                    },
                  ),
                  const SizedBox(height: 10),
                  if (_editando && (widget.usuario!.email ?? '').isNotEmpty)
                    Text('Para manter o e-mail atual, deixe o campo como está.',
                        style: AppText.regular(13, AppColors.gray)),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: _salvando ? null : _salvar,
                    child: _salvando
                        ? const SizedBox(
                            width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                        : Text(_editando ? 'Salvar alterações' : 'Cadastrar usuário'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t, style: AppText.bold(15)),
      );
}

InputDecoration _decoration(String hint) => InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.card,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.blue, width: 1.5),
      ),
    );

/// Reaproveitado nos outros formulários.
InputDecoration formDecoration(String hint) => _decoration(hint);
