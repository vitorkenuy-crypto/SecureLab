import 'package:flutter_test/flutter_test.dart';
import 'package:securelab_app/core/api_client.dart';
import 'package:securelab_app/core/theme.dart';
import 'package:securelab_app/models/models.dart';

void main() {
  test('iniciais dos nomes', () {
    expect(initialsOf('Ana Oliveira'), 'AO');
    expect(initialsOf('Fernando de Souza Fernandes'), 'FF');
    expect(initialsOf('admin'), 'AD');
    expect(initialsOf('  '), '?');
  });

  test('monta URL com filtros e ignora nulos', () {
    final c = ApiClient(baseUrl: 'http://10.0.2.2:8000/');
    final u = c.uri('/acessos', {'limit': 50, 'resultado': null, 'data_inicio': '2026-11-01'});
    expect(u.toString(), 'http://10.0.2.2:8000/acessos?limit=50&data_inicio=2026-11-01');
  });

  test('lê acesso com fuso horário da API', () {
    final a = Acesso.fromJson({
      'id': 16,
      'usuario_id': null,
      'usuario_nome': null,
      'dispositivo_id': 1,
      'dispositivo_nome': 'Porta Lab 1',
      'template_id_lido': 999,
      'data_hora': '2026-10-19T09:32:10.123456-03:00',
      'resultado': 'NEGADO',
    });
    expect(a.autorizado, isFalse);
    expect(a.dataHora.toUtc().hour, 12);
  });
}
