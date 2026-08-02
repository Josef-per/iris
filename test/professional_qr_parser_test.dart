import 'package:flutter_test/flutter_test.dart';
import 'package:iris/core/qr/professional_qr_parser.dart';
import 'package:iris/core/qr/professional_qr_payload.dart';

void main() {
  const token =
      '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';

  test('build e parse do convite oficial sao compativeis', () {
    final payload = ProfessionalQrPayload.build(token);

    expect(payload, 'iris://vincular/profissional?v=1&token=$token');
    expect(ProfessionalQrParser.parseInviteToken(payload), token);
  });

  test('aceita token puro para entrada manual', () {
    expect(ProfessionalQrParser.parseInviteToken(token), token);
  });

  test('normaliza token em maiusculas', () {
    expect(ProfessionalQrParser.parseInviteToken(token.toUpperCase()), token);
  });

  test('rejeita uuid permanente e urls arbitrarias', () {
    const uuid = '550e8400-e29b-41d4-a716-446655440000';
    expect(ProfessionalQrParser.parseInviteToken(uuid), isNull);
    expect(
      ProfessionalQrParser.parseInviteToken(
        'https://iris.app/vincular?token=$token',
      ),
      isNull,
    );
    expect(
      ProfessionalQrParser.parseInviteToken(
        'iris://vincular/profissional/extra?v=1&token=$token',
      ),
      isNull,
    );
  });

  test('rejeita token parcial, texto embutido e payload adulterado', () {
    expect(ProfessionalQrParser.parseInviteToken(token.substring(1)), isNull);
    expect(ProfessionalQrParser.parseInviteToken('codigo-$token'), isNull);
    expect(
      ProfessionalQrParser.parseInviteToken(
        'iris://vincular/profissional?v=2&token=$token',
      ),
      isNull,
    );
    expect(ProfessionalQrParser.parseInviteToken(''), isNull);
  });

  test('build rejeita token invalido', () {
    expect(
      () => ProfessionalQrPayload.build('token-invalido'),
      throwsFormatException,
    );
    expect(
      () => ProfessionalQrPayload.build('${token}a'),
      throwsFormatException,
    );
    expect(
      () => ProfessionalQrPayload.build(token.substring(1)),
      throwsFormatException,
    );
  });

  test('rejeita parametros duplicados, extras e fragmentos', () {
    expect(
      ProfessionalQrParser.parseInviteToken(
        'iris://vincular/profissional?v=1&token=$token&token=$token',
      ),
      isNull,
    );
    expect(
      ProfessionalQrParser.parseInviteToken(
        'iris://vincular/profissional?v=1&token=$token&origem=web',
      ),
      isNull,
    );
    expect(
      ProfessionalQrParser.parseInviteToken(
        'iris://vincular/profissional?v=1&token=$token#confirmar',
      ),
      isNull,
    );
  });
}
