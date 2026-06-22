import 'package:iris/core/supabase/database_tables.dart';
import 'package:iris/core/supabase/supabase_client_provider.dart';
import 'package:iris/features/users/user_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FoodRecordRepository {
  SupabaseClient get _client => SupabaseClientProvider.client;
  final _users = UserRepository();

  Future<void> createRecord({
    required String description,
    required int hungerLevel,
    String? feelingAfter,
    String? observations,
    DateTime? mealTime,
  }) async {
    final pacienteId = await _users.getOrCreateCurrentPatientId();

    await _client.from(DatabaseTables.registrosAlimentares).insert({
      'paciente_id': pacienteId,
      'horario_refeicao': (mealTime ?? DateTime.now()).toIso8601String(),
      'descricao_refeicao': description.trim(),
      'nivel_fome': hungerLevel,
      'sentimento_depois': _emptyToNull(feelingAfter),
      'observacoes': _emptyToNull(observations),
    });
  }

  String? _emptyToNull(String? value) {
    final cleanValue = value?.trim();

    if (cleanValue == null || cleanValue.isEmpty) {
      return null;
    }

    return cleanValue;
  }
}
