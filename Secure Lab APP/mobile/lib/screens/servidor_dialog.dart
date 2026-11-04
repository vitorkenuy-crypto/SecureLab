import 'package:flutter/material.dart';

import '../core/session.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

/// Diálogo para trocar o endereço da API (ex: http://192.168.0.10:8000).
Future<void> showServidorDialog(BuildContext context) async {
  final session = AppScope.read(context);
  final ctrl = TextEditingController(text: session.baseUrl);
  final salvar = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Servidor da API'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: const InputDecoration(labelText: 'Endereço', hintText: 'http://192.168.0.10:8000'),
          ),
          const SizedBox(height: 12),
          Text(
            'Navegador (Edge/Chrome): http://localhost:8000\n'
            'Emulador Android: http://10.0.2.2:8000\n'
            'Celular na mesma rede: http://IP-DO-PC:8000\n'
            '(suba a API com --host 0.0.0.0)',
            style: AppText.regular(12, AppColors.gray),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Salvar e testar')),
      ],
    ),
  );
  if (salvar != true) return;
  final url = ctrl.text.trim();
  if (!url.startsWith('http://') && !url.startsWith('https://')) {
    if (context.mounted) showMessage(context, 'O endereço deve começar com http:// ou https://', error: true);
    return;
  }
  await session.setBaseUrl(url);
  final ok = await session.api.ping();
  if (context.mounted) {
    showMessage(context, ok ? 'API encontrada em $url' : 'Não consegui falar com a API em $url', error: !ok);
  }
}
