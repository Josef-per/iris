import 'package:iris/core/supabase/database_tables.dart';
import 'package:iris/core/supabase/supabase_client_provider.dart';
import 'package:iris/features/users/user_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PatientProfessionalRepository {
  SupabaseClient get _client => SupabaseClientProvider.client;
  final _users = UserRepository();

  Future<bool> hasActiveProfessionalLink() async {
    final pacienteId = await _users.findCurrentPatientId();

    if (pacienteId == null) {
      return false;
    }

    final link = await _client
        .from(DatabaseTables.pacienteProfissional)
        .select('id')
        .eq('paciente_id', pacienteId)
        .eq('status', PatientProfessionalStatus.ativo)
        .limit(1)
        .maybeSingle();

    return link != null;
  }

  Future<void> linkCurrentPatientToProfessional(String profissionalId) async {
    final normalizedId = profissionalId.trim().toLowerCase();

    if (normalizedId.isEmpty) {
      throw Exception('Codigo QR invalido.');
    }

    final pacienteId = await _users.getOrCreateCurrentPatientId();

    final profissional = await _client
        .from(DatabaseTables.profissionais)
        .select('id')
        .eq('id', normalizedId)
        .limit(1)
        .maybeSingle();

    if (profissional == null) {
      throw Exception('Profissional nao encontrado.');
    }

    final existing = await _client
        .from(DatabaseTables.pacienteProfissional)
        .select('id, status')
        .eq('paciente_id', pacienteId)
        .eq('profissional_id', normalizedId)
        .limit(1)
        .maybeSingle();

    if (existing != null) {
      if (existing['status'] == PatientProfessionalStatus.ativo) {
        return;
      }

      await _client
          .from(DatabaseTables.pacienteProfissional)
          .update({'status': PatientProfessionalStatus.ativo})
          .eq('id', existing['id'] as String);

      return;
    }

    await _client.from(DatabaseTables.pacienteProfissional).insert({
      'paciente_id': pacienteId,
      'profissional_id': normalizedId,
      'status': PatientProfessionalStatus.ativo,
    });
  }
}
