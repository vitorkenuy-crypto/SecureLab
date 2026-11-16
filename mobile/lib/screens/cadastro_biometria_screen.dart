import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/session.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../widgets/app_header.dart';
import '../widgets/common.dart';
import '../widgets/figma_icon.dart';
import 'usuario_form_screen.dart' show formDecoration;

/// Tela "Cadastro" (Cadastrar Biometria) do Figma, em 3 etapas.
///
/// A captura da digital acontece no sensor do ESP32, que grava o template na
/// memória e informa um número (template_id). A API não tem rota para iniciar a
/// captura remotamente, então aqui o admin informa esse número e o app faz o
/// vínculo com o usuário via POST /digitais.
class CadastroBiometriaScreen extends StatefulWidget {
  const CadastroBiometriaScreen({super.key, this.usuario});

  /// Se null, a primeira etapa pede para escolher o usuário.
  final Usuario? usuario;

  @override
  State<CadastroBiometriaScreen> createState() => _CadastroBiometriaScreenState();
}

class _CadastroBiometriaScreenState extends State<CadastroBiometriaScreen> {
  int _etapa = 0; // 0 Captura, 1 Validação, 2 Conclusão
  final _template = TextEditingController();
  Usuario? _usuario;
  List<Usuario> _usuariosAtivos = [];
  Set<int> _templatesUsados = {};
  bool _carregando = true;
  bool _enviando = false;
  String? _erroEnvio;

  @override
  void initState() {
    super.initState();
    _usuario = widget.usuario;
    _carregar();
  }

  @override
  void dispose() {
    _template.dispose();
    super.dispose();
  }

  /// Busca as digitais existentes para sugerir o próximo template livre.
  Future<void> _carregar() async {
    final api = AppScope.read(context).api;
    try {
      final r = await Future.wait([
        api.digitais(),
        if (widget.usuario == null) api.usuarios(),
      ]);
      final digitais = r[0] as List<Digital>;
      _templatesUsados = digitais.map((d) => d.templateId).toSet();
      var proximo = 1;
      while (_templatesUsados.contains(proximo)) {
        proximo++;
      }
      _template.text = '$proximo';
      if (r.length > 1) {
        _usuariosAtivos = (r[1] as List<Usuario>).where((u) => u.ativo).toList()
          ..sort((a, b) => a.nome.compareTo(b.nome));
      }
    } catch (e) {
      if (mounted) showMessage(context, errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  int? get _templateId => int.tryParse(_template.text.trim());

  double get _progresso {
    var p = 0.0;
    if (_usuario != null) p += 0.35;
    if (_templateId != null) p += 0.35;
    return switch (_etapa) { 0 => p, 1 => 0.85, _ => 1.0 };
  }

  void _continuar() {
    if (_usuario == null) {
      showMessage(context, 'Escolha o usuário.', error: true);
      return;
    }
    final t = _templateId;
    if (t == null || t < 0) {
      showMessage(context, 'Informe o número do template gravado pelo sensor.', error: true);
      return;
    }
    if (_templatesUsados.contains(t)) {
      showMessage(context, 'O template #$t já está vinculado a outro usuário.', error: true);
      return;
    }
    setState(() {
      _erroEnvio = null;
      _etapa = 1;
    });
  }

  Future<void> _confirmar() async {
    setState(() {
      _enviando = true;
      _erroEnvio = null;
    });
    try {
      await AppScope.read(context).api.cadastrarDigital(usuarioId: _usuario!.id, templateId: _templateId!);
      if (mounted) setState(() => _etapa = 2);
    } catch (e) {
      if (mounted) setState(() => _erroEnvio = errorText(e));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          DetailHeader(
            title: 'Cadastrar Biometria',
            onBack: () => Navigator.of(context).pop(_etapa == 2),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              children: [
                _Stepper(etapa: _etapa),
                const SizedBox(height: 28),
                if (_carregando) const LoadingView() else _conteudo(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _conteudo() {
    switch (_etapa) {
      case 0:
        return _captura();
      case 1:
        return _validacao();
      default:
        return _conclusao();
    }
  }

  // ---------- Etapa 1: Captura ----------
  Widget _captura() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _FingerprintRing(),
        const SizedBox(height: 18),
        Text('Posicione o dedo no sensor', textAlign: TextAlign.center, style: AppText.bold(23)),
        const SizedBox(height: 8),
        Text(
          'Cadastre a digital no sensor do ambiente e informe abaixo o número do template que ele gravou.',
          textAlign: TextAlign.center,
          style: AppText.bold(16, AppColors.gray),
        ),
        const SizedBox(height: 18),
        _BarraProgresso(valor: _progresso),
        const SizedBox(height: 18),
        if (widget.usuario == null) ...[
          Text('Usuário', style: AppText.bold(15)),
          const SizedBox(height: 6),
          DropdownButtonFormField<int>(
            value: _usuario?.id,
            isExpanded: true,
            decoration: formDecoration('Escolha o usuário'),
            items: [
              for (final u in _usuariosAtivos) DropdownMenuItem(value: u.id, child: Text(u.nome)),
            ],
            onChanged: (id) => setState(() => _usuario = _usuariosAtivos.firstWhere((u) => u.id == id)),
          ),
          const SizedBox(height: 14),
        ] else ...[
          Text('Usuário: ${widget.usuario!.nome}', style: AppText.bold(16)),
          const SizedBox(height: 14),
        ],
        Text('Número do template (ID no sensor)', style: AppText.bold(15)),
        const SizedBox(height: 6),
        TextField(
          controller: _template,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => setState(() {}),
          decoration: formDecoration('Ex: 10'),
        ),
        const SizedBox(height: 4),
        Text('Sugerimos o próximo número livre.', style: AppText.regular(12, AppColors.gray)),
        const SizedBox(height: 18),
        const _Dicas(),
        const SizedBox(height: 22),
        ElevatedButton(onPressed: _continuar, child: const Text('Continuar')),
        const SizedBox(height: 12),
        _BotaoCancelar(onTap: () => Navigator.of(context).pop(false)),
      ],
    );
  }

  // ---------- Etapa 2: Validação ----------
  Widget _validacao() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: FigmaIcon(AppIcons.fingerprintBlue, size: 100)),
        const SizedBox(height: 18),
        Text('Confira os dados', textAlign: TextAlign.center, style: AppText.bold(23)),
        const SizedBox(height: 18),
        ListCard(
          minHeight: 0,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _linha('Usuário', _usuario!.nome),
            _linha('E-mail', _usuario!.email ?? '—'),
            _linha('Template no sensor', '#$_templateId'),
          ]),
        ),
        if (_erroEnvio != null) ...[
          const SizedBox(height: 8),
          Text(_erroEnvio!, textAlign: TextAlign.center, style: AppText.bold(15, AppColors.red)),
        ],
        const SizedBox(height: 22),
        ElevatedButton(
          onPressed: _enviando ? null : _confirmar,
          child: _enviando
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
              : const Text('Confirmar cadastro'),
        ),
        const SizedBox(height: 12),
        _BotaoCancelar(label: 'Voltar', onTap: () => setState(() => _etapa = 0)),
      ],
    );
  }

  Widget _linha(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Expanded(child: Text(k, style: AppText.regular(15, AppColors.gray))),
          Flexible(child: Text(v, textAlign: TextAlign.right, style: AppText.bold(16))),
        ]),
      );

  // ---------- Etapa 3: Conclusão ----------
  Widget _conclusao() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(color: AppColors.tint(AppColors.green), shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, size: 72, color: AppColors.green),
          ),
        ),
        const SizedBox(height: 20),
        Text('Biometria cadastrada!', textAlign: TextAlign.center, style: AppText.bold(23)),
        const SizedBox(height: 8),
        Text(
          '${_usuario!.nome} já pode acessar os ambientes ativos usando a digital #$_templateId.',
          textAlign: TextAlign.center,
          style: AppText.bold(16, AppColors.gray),
        ),
        const SizedBox(height: 18),
        _BarraProgresso(valor: 1),
        const SizedBox(height: 28),
        ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Concluir')),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.etapa});

  final int etapa;

  static const _nomes = ['Captura', 'Validação', 'Conclusão'];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Linha cinza ligando os círculos
        Positioned(
          left: 40,
          right: 40,
          top: 24,
          child: Container(height: 3, color: const Color(0xFFAAAAAA)),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < 3; i++)
              SizedBox(
                width: 100,
                child: Column(children: [
                  Container(
                    width: 50,
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i <= etapa ? AppColors.blue : const Color(0xFFAAAAAA),
                    ),
                    child: Text('${i + 1}', style: AppText.bold(23, i <= etapa ? Colors.white : AppColors.gray)),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(_nomes[i], style: AppText.bold(20, i == etapa ? AppColors.blue : AppColors.gray)),
                  ),
                ]),
              ),
          ],
        ),
      ],
    );
  }
}

/// Digital com o anel tracejado girando em volta.
class _FingerprintRing extends StatefulWidget {
  const _FingerprintRing();

  @override
  State<_FingerprintRing> createState() => _FingerprintRingState();
}

class _FingerprintRingState extends State<_FingerprintRing> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          RotationTransition(turns: _c, child: const FigmaIcon(AppIcons.loadingRing, size: 150)),
          const FigmaIcon(AppIcons.fingerprintBlue, size: 100),
        ],
      ),
    );
  }
}

class _BarraProgresso extends StatelessWidget {
  const _BarraProgresso({required this.valor});

  final double valor;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: Container(
          height: 12,
          decoration: const BoxDecoration(color: Color(0x4D666666), boxShadow: AppColors.shadow),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: valor.clamp(0.0, 1.0),
            child: Container(color: AppColors.blue),
          ),
        ),
      ),
      const SizedBox(width: 10),
      Text('${(valor * 100).round()}%', style: AppText.bold(15, AppColors.blue)),
    ]);
  }
}

class _Dicas extends StatelessWidget {
  const _Dicas();

  @override
  Widget build(BuildContext context) {
    Widget item(String t) => Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Row(children: [
            Container(width: 5, height: 5, decoration: const BoxDecoration(color: AppColors.blue, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Expanded(child: Text(t, style: AppText.bold(12))),
          ]),
        );
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
      decoration: BoxDecoration(
        color: AppColors.tint(AppColors.blue),
        borderRadius: BorderRadius.circular(10),
        boxShadow: AppColors.shadow,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Dicas:', style: AppText.bold(15)),
        item('Use o mesmo dedo que será utilizado no acesso.'),
        item('Mantenha o dedo limpo e seco.'),
        item('Pressione firmemente no sensor.'),
      ]),
    );
  }
}

class _BotaoCancelar extends StatelessWidget {
  const _BotaoCancelar({required this.onTap, this.label = 'Cancelar'});

  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), boxShadow: AppColors.shadow),
      child: Material(
        color: const Color(0xFFBBD3E0), // azul 20% sobre o fundo cinza, opaco para a sombra
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: SizedBox(
            height: 44,
            child: Center(child: Text(label, style: AppText.bold(20, AppColors.blue))),
          ),
        ),
      ),
    );
  }
}
