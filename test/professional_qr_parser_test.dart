import 'package:flutter_test/flutter_test.dart';
import 'package:iris/core/qr/professional_qr_parser.dart';
import 'package:iris/core/qr/professional_qr_payload.dart';

void main() {
  const profissionalId = '550e8400-e29b-41d4-a716-446655440000';

  test('build e parse do payload oficial sao compativeis', () {
    final payload = ProfessionalQrPayload.build(profissionalId);

    expect(payload, 'iris://vincular/profissional/$profissionalId');
    expect(ProfessionalQrParser.parseProfissionalId(payload), profissionalId);
  });

  test('aceita uuid puro', () {
    expect(
      ProfessionalQrParser.parseProfissionalId(profissionalId),
      profissionalId,
    );
  });

  test('aceita uuid em url legada', () {
    expect(
      ProfessionalQrParser.parseProfissionalId(
        'iris://profissional/$profissionalId',
      ),
      profissionalId,
    );
  });

  test('aceita uuid em query string', () {
    expect(
      ProfessionalQrParser.parseProfissionalId(
        'https://iris.app/vincular?profissional_id=$profissionalId',
      ),
      profissionalId,
    );
  });

  test('retorna null para valor invalido', () {
    expect(ProfessionalQrParser.parseProfissionalId('codigo-invalido'), isNull);
    expect(ProfessionalQrParser.parseProfissionalId(''), isNull);
  });
}
