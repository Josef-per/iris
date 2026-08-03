import 'package:iris/core/supabase/database_tables.dart';
import 'package:iris/core/supabase/supabase_client_provider.dart';
import 'package:iris/features/users/user_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class FoodRecordDataSource {
  Future<void> createRecord({
    required String description,
    required int hungerLevel,
    String? feelingAfter,
    String? observations,
    DateTime? mealTime,
  });

  Future<int> countRecordsForLocalDay(DateTime day);
}

class FoodRecordRepository implements FoodRecordDataSource {
  FoodRecordRepository({
    SupabaseClient? client,
    UserRepository? users,
    DateTime Function()? clock,
  }) : _clientOverride = client,
       _users = users ?? UserRepository(client: client),
       _clock = clock ?? DateTime.now;

  final SupabaseClient? _clientOverride;
  final UserRepository _users;
  final DateTime Function() _clock;

  SupabaseClient get _client =>
      _clientOverride ?? SupabaseClientProvider.client;

  @override
  Future<void> createRecord({
    required String description,
    required int hungerLevel,
    String? feelingAfter,
    String? observations,
    DateTime? mealTime,
  }) async {
    final cleanDescription = description.trim();
    if (cleanDescription.isEmpty) {
      throw const FormatException('Descreva a refeição.');
    }
    if (hungerLevel < 1 || hungerLevel > 10) {
      throw ArgumentError.value(hungerLevel, 'hungerLevel');
    }

    final pacienteId = await _users.getOrCreateCurrentPatientId();
    final recordedAt = mealTime ?? _clock();

    await _client.from(DatabaseTables.registrosAlimentares).insert({
      'paciente_id': pacienteId,
      'horario_refeicao': recordedAt.toUtc().toIso8601String(),
      'descricao_refeicao': cleanDescription,
      'nivel_fome': hungerLevel,
      'sentimento_depois': _emptyToNull(feelingAfter),
      'observacoes': _emptyToNull(observations),
    });
  }

  @override
  Future<int> countRecordsForLocalDay(DateTime day) async {
    final pacienteId = await _users.findCurrentPatientId();
    if (pacienteId == null) {
      return 0;
    }

    final localDay = day.toLocal();
    final localDayStart = DateTime(localDay.year, localDay.month, localDay.day);
    final localNextDay = localDayStart.add(const Duration(days: 1));
    final rows = await _client
        .from(DatabaseTables.registrosAlimentares)
        .select('id')
        .eq('paciente_id', pacienteId)
        .gte('horario_refeicao', localDayStart.toUtc().toIso8601String())
        .lt('horario_refeicao', localNextDay.toUtc().toIso8601String());

    return rows.length;
  }

  String? _emptyToNull(String? value) {
    final cleanValue = value?.trim();

    if (cleanValue == null || cleanValue.isEmpty) {
      return null;
    }

    return cleanValue;
  }
}
