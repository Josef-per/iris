import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String migration;
  late String qrCompatibilityMigration;
  late String clinicalIntegrityMigration;
  late String lockdown;

  setUpAll(() {
    migration = File(
      'supabase/migrations/0006_professional_backend.sql',
    ).readAsStringSync();
    qrCompatibilityMigration = File(
      'supabase/migrations/0007_professional_invite_legacy_text_compat.sql',
    ).readAsStringSync();
    clinicalIntegrityMigration = File(
      'supabase/migrations/0008_clinical_data_integrity.sql',
    ).readAsStringSync();
    lockdown = File(
      'supabase/migrations/0005_patient_professional_link_rls.sql',
    ).readAsStringSync();
  });

  test('convite armazena hash e nunca uma coluna de token puro', () {
    expect(migration, contains('token_hash text not null unique'));
    expect(migration, contains("digest(v_token, 'sha256')"));
    expect(
      RegExp(r'\btoken\s+text\b').allMatches(
        _createTableBlock(migration, 'public.convites_vinculo_profissional'),
      ),
      isEmpty,
    );
  });

  test('resgate QR e idempotente e serializado por paciente', () {
    expect(migration, contains('unique (convite_id, paciente_id)'));
    expect(migration, contains('for update;'));
    expect(migration, contains('get diagnostics v_new_redemption = row_count'));
    expect(migration, contains('iris_vinculo_autorizado_por_paciente_unique'));
  });

  test('RPCs de QR normalizam colunas varchar legadas para text', () {
    for (final sql in [migration, qrCompatibilityMigration]) {
      expect(
        RegExp(
          r"coalesce\([\s\S]*?'Profissional'[\s\S]*?\)::text",
          caseSensitive: false,
        ).allMatches(sql),
        hasLength(2),
      );
      expect(
        RegExp(
          r'profissional\.especialidade::text',
          caseSensitive: false,
        ).allMatches(sql),
        hasLength(2),
      );
    }
  });

  test('separa acompanhamento inativo de autorizacao revogada', () {
    expect(migration, contains('autorizacao_status'));
    expect(migration, contains('iris_professional_manages_link'));
    expect(
      migration,
      contains("check (autorizacao_status in ('ativo', 'revogado'))"),
    );
  });

  test('reconcilia autorizacoes legadas antes do indice unico', () {
    final reconciliation = migration.indexOf(
      'with vinculos_autorizados_ordenados as',
    );
    final uniqueIndex = migration.indexOf(
      'create unique index if not exists '
      'iris_vinculo_autorizado_por_paciente_unique',
    );

    expect(reconciliation, greaterThanOrEqualTo(0));
    expect(uniqueIndex, greaterThan(reconciliation));
    expect(migration, contains('row_number() over'));
    expect(migration, contains("set autorizacao_status = 'revogado'"));
    expect(migration, contains('and ordenado.ordem > 1'));
  });

  test('migration anterior nao permite promover papel ou criar vinculo', () {
    expect(lockdown, isNot(contains('create policy iris_usuarios_update_own')));
    expect(
      lockdown,
      isNot(contains('create policy iris_profissionais_insert_own')),
    );
    expect(
      lockdown,
      isNot(
        contains('create policy iris_paciente_profissional_insert_by_patient'),
      ),
    );
    expect(
      lockdown,
      contains('revoke insert, update, delete on public.paciente_profissional'),
    );
  });

  test('tabelas clinicas e de convite usam RLS', () {
    for (final table in [
      'consultas',
      'anotacoes_clinicas',
      'planos_cuidado',
      'metas_cuidado',
      'medicacoes_plano',
      'convites_vinculo_profissional',
      'convites_vinculo_resgates',
    ]) {
      expect(
        migration,
        contains('alter table public.$table enable row level security'),
        reason: 'RLS ausente em $table',
      );
    }
  });

  test('registro emocional diario usa chave unica e upsert atomico', () {
    expect(
      clinicalIntegrityMigration,
      contains('iris_emocionais_paciente_dia_unique'),
    );
    expect(
      clinicalIntegrityMigration,
      contains('iris_upsert_daily_emotional_record'),
    );
    expect(
      clinicalIntegrityMigration,
      contains('on conflict (paciente_id, data_local) do update'),
    );
  });

  test('sintomas, escalas e agenda possuem contratos no banco', () {
    expect(clinicalIntegrityMigration, contains("when 5 then 'desmaio'"));
    expect(
      clinicalIntegrityMigration,
      contains('nivel_fome is null or nivel_fome between 1 and 10'),
    );
    expect(
      clinicalIntegrityMigration,
      contains("modalidade in ('online', 'presencial')"),
    );
    expect(clinicalIntegrityMigration, contains('APPOINTMENT_MUST_BE_FUTURE'));
  });
}

String _createTableBlock(String sql, String table) {
  final start = sql.indexOf('create table if not exists $table');
  if (start == -1) return '';
  final end = sql.indexOf(');', start);
  return end == -1 ? sql.substring(start) : sql.substring(start, end + 2);
}
