import 'package:iris/core/supabase/database_tables.dart';
import 'package:iris/core/supabase/supabase_client_provider.dart';
import 'package:iris/features/emergency_contact/emergency_contact.dart';
import 'package:iris/features/users/user_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class EmergencyContactDataSource {
  Future<EmergencyContact?> load();
  Future<void> save(EmergencyContact contact);
  Future<void> delete();
}

class EmergencyContactRepository implements EmergencyContactDataSource {
  EmergencyContactRepository({SupabaseClient? client})
    : _clientOverride = client;

  final SupabaseClient? _clientOverride;

  SupabaseClient get _client =>
      _clientOverride ?? SupabaseClientProvider.client;

  Future<String> _patientId() async =>
      UserRepository(client: _client).getOrCreateCurrentPatientId();

  @override
  Future<EmergencyContact?> load() async {
    if (_client.auth.currentUser == null) return null;
    final patientId = await _patientId();
    final row = await _client
        .from(DatabaseTables.contatosEmergencia)
        .select('nome, telefone')
        .eq('paciente_id', patientId)
        .maybeSingle();
    return row == null ? null : EmergencyContact.fromMap(row);
  }

  @override
  Future<void> save(EmergencyContact contact) async {
    final name = contact.name.trim();
    final phone = EmergencyContact.normalizePhone(contact.phone);
    if (name.isEmpty || name.length > 100 || phone == null) {
      throw const FormatException('Contato de emergência inválido.');
    }
    final patientId = await _patientId();
    await _client.from(DatabaseTables.contatosEmergencia).upsert({
      'paciente_id': patientId,
      'nome': name,
      'telefone': phone,
      'atualizado_em': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'paciente_id');
  }

  @override
  Future<void> delete() async {
    final patientId = await _patientId();
    await _client
        .from(DatabaseTables.contatosEmergencia)
        .delete()
        .eq('paciente_id', patientId);
  }
}
