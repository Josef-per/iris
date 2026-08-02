import 'package:flutter_test/flutter_test.dart';
import 'package:iris/core/errors/app_error_messages.dart';
import 'package:iris/features/professional/data/supabase_professional_workspace_backend.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('traduz limite de email do Supabase Auth', () {
    final message = AppErrorMessages.from(
      AuthApiException(
        'email rate limit exceeded',
        statusCode: '429',
        code: 'over_email_send_rate_limit',
      ),
    );

    expect(message, contains('Aguarde cerca de 1 minuto'));
    expect(message, isNot(contains('AuthApiException')));
  });

  test('traduz tabela ausente do Postgres', () {
    final message = AppErrorMessages.from(
      const PostgrestException(
        message: 'relation "public.profiles" does not exist',
        code: '42P01',
      ),
    );

    expect(message, contains('Aplique as migrations'));
    expect(message, isNot(contains('PostgrestException')));
  });

  test('orienta aplicar backend quando bootstrap nao existe', () {
    final message = AppErrorMessages.from(
      const PostgrestException(
        message:
            'Could not find the function public.iris_bootstrap_current_user',
        code: 'PGRST202',
      ),
    );

    expect(message, contains('0006_professional_backend.sql'));
    expect(message, isNot(contains('PGRST202')));
  });

  test('orienta aplicar migrations quando tabela nao existe no cache', () {
    final message = AppErrorMessages.from(
      const PostgrestException(
        message: "Could not find the table 'public.consultas'",
        code: 'PGRST205',
      ),
    );

    expect(message, contains('migrations pendentes'));
    expect(message, isNot(contains('PGRST205')));
  });

  test('orienta corrigir RPC de QR incompatível com schema legado', () {
    final message = AppErrorMessages.from(
      const PostgrestException(
        message: 'structure of query does not match function result type',
        code: '42804',
      ),
    );

    expect(
      message,
      contains('0007_professional_invite_legacy_text_compat.sql'),
    );
    expect(message, isNot(contains('42804')));
  });

  test('traduz falha de trigger ao criar usuario', () {
    final message = AppErrorMessages.from(
      AuthApiException(
        'Database error saving new user',
        statusCode: '500',
        code: 'unexpected_failure',
      ),
    );

    expect(message, contains('migrations do Supabase'));
    expect(message, isNot(contains('AuthApiException')));
  });

  test('traduz sessao ausente ao salvar registros', () {
    final message = AppErrorMessages.from(
      Exception('Usuario nao autenticado.'),
    );

    expect(message, contains('Entre na sua conta'));
    expect(message, isNot(contains('Exception')));
  });

  test('preserva mensagem segura do backend profissional', () {
    final message = AppErrorMessages.from(
      const ProfessionalWorkspaceException(
        'Informe uma data e um horário futuros.',
      ),
    );

    expect(message, 'Informe uma data e um horário futuros.');
  });
}
