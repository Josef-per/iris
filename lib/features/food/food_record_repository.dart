import 'package:iris/core/supabase/database_tables.dart';
import 'package:iris/core/supabase/supabase_client_provider.dart';
import 'package:iris/features/food/meal_type.dart';
import 'package:iris/features/users/user_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FoodRecord {
  const FoodRecord({
    required this.id,
    required this.description,
    required this.mealTime,
    this.mealType,
    this.hungerLevel,
    this.feelingAfter,
    this.observations,
  });

  final String id;
  final MealType? mealType;
  final String description;
  final int? hungerLevel;
  final String? feelingAfter;
  final String? observations;
  final DateTime mealTime;

  factory FoodRecord.fromMap(Map<String, dynamic> map) {
    final rawMealTime =
        map['horario_refeicao'] ?? map['data_registro'] ?? map['criado_em'];
    final mealTime = DateTime.tryParse(rawMealTime?.toString() ?? '');
    if (mealTime == null) {
      throw const FormatException('Registro alimentar sem horário válido.');
    }

    return FoodRecord(
      id: map['id'] as String,
      mealType: MealType.fromCode(map['tipo_refeicao']),
      description: (map['descricao_refeicao'] ?? '').toString(),
      hungerLevel: _integer(map['nivel_fome']),
      feelingAfter: _nullableString(map['sentimento_depois']),
      observations: _nullableString(map['observacoes']),
      mealTime: mealTime,
    );
  }

  static int? _integer(Object? value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '');
  }

  static String? _nullableString(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}

abstract interface class FoodRecordDataSource {
  Future<void> createRecord({
    required String description,
    required int hungerLevel,
    MealType? mealType,
    String? feelingAfter,
    String? observations,
    DateTime? mealTime,
  });

  Future<void> updateRecord({
    required String id,
    required String description,
    required int hungerLevel,
    MealType? mealType,
    String? feelingAfter,
    String? observations,
    DateTime? mealTime,
  });

  Future<void> deleteRecord(String id);

  Future<int> countRecordsForLocalDay(DateTime day);

  Future<List<FoodRecord>> listRecordsForLocalDay(DateTime day);
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
    MealType? mealType,
    String? feelingAfter,
    String? observations,
    DateTime? mealTime,
  }) async {
    final values = _validatedValues(
      description: description,
      hungerLevel: hungerLevel,
      mealType: mealType,
      feelingAfter: feelingAfter,
      observations: observations,
      mealTime: mealTime,
    );
    final pacienteId = await _users.getOrCreateCurrentPatientId();

    await _client.from(DatabaseTables.registrosAlimentares).insert({
      'paciente_id': pacienteId,
      ...values,
    });
  }

  @override
  Future<void> updateRecord({
    required String id,
    required String description,
    required int hungerLevel,
    MealType? mealType,
    String? feelingAfter,
    String? observations,
    DateTime? mealTime,
  }) async {
    final values = _validatedValues(
      description: description,
      hungerLevel: hungerLevel,
      mealType: mealType,
      feelingAfter: feelingAfter,
      observations: observations,
      mealTime: mealTime,
    );

    await _client
        .from(DatabaseTables.registrosAlimentares)
        .update(values)
        .eq('id', id);
  }

  @override
  Future<void> deleteRecord(String id) async {
    await _client
        .from(DatabaseTables.registrosAlimentares)
        .delete()
        .eq('id', id);
  }

  Map<String, dynamic> _validatedValues({
    required String description,
    required int hungerLevel,
    required MealType? mealType,
    required String? feelingAfter,
    required String? observations,
    required DateTime? mealTime,
  }) {
    final cleanDescription = description.trim();
    if (cleanDescription.isEmpty) {
      throw const FormatException('Descreva a refeição.');
    }
    if (hungerLevel < 1 || hungerLevel > 10) {
      throw ArgumentError.value(hungerLevel, 'hungerLevel');
    }

    final recordedAt = mealTime ?? _clock();

    return {
      'horario_refeicao': recordedAt.toUtc().toIso8601String(),
      'tipo_refeicao': mealType?.code,
      'descricao_refeicao': cleanDescription,
      'nivel_fome': hungerLevel,
      'sentimento_depois': _emptyToNull(feelingAfter),
      'observacoes': _emptyToNull(observations),
    };
  }

  @override
  Future<int> countRecordsForLocalDay(DateTime day) async {
    final rows = await _rowsForLocalDay(day, columns: 'id');
    return rows.length;
  }

  @override
  Future<List<FoodRecord>> listRecordsForLocalDay(DateTime day) async {
    final rows = await _rowsForLocalDay(day, columns: _recordColumns);
    return rows.map((row) => FoodRecord.fromMap(row)).toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> _rowsForLocalDay(
    DateTime day, {
    required String columns,
  }) async {
    final pacienteId = await _users.findCurrentPatientId();
    if (pacienteId == null) {
      return [];
    }

    final localDay = day.toLocal();
    final localDayStart = DateTime(localDay.year, localDay.month, localDay.day);
    final localNextDay = localDayStart.add(const Duration(days: 1));
    return _client
        .from(DatabaseTables.registrosAlimentares)
        .select(columns)
        .eq('paciente_id', pacienteId)
        .gte('horario_refeicao', localDayStart.toUtc().toIso8601String())
        .lt('horario_refeicao', localNextDay.toUtc().toIso8601String())
        .order('horario_refeicao', ascending: true);
  }

  static const _recordColumns =
      'id, horario_refeicao, tipo_refeicao, descricao_refeicao, '
      'nivel_fome, sentimento_depois, observacoes';

  String? _emptyToNull(String? value) {
    final cleanValue = value?.trim();

    if (cleanValue == null || cleanValue.isEmpty) {
      return null;
    }

    return cleanValue;
  }
}
