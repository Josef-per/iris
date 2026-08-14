import 'package:flutter/material.dart';
import 'package:iris/core/supabase/database_tables.dart';
import 'package:iris/core/supabase/supabase_client_provider.dart';
import 'package:iris/features/emotional_diary/patient_symptoms.dart';
import 'package:iris/features/food/meal_type.dart';
import 'package:iris/features/users/user_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum PatientHistoryKind { emotional, food }

class PatientHistoryEntry {
  const PatientHistoryEntry({
    required this.kind,
    required this.moment,
    required this.title,
    required this.description,
    required this.icon,
  });

  final PatientHistoryKind kind;
  final DateTime moment;
  final String title;
  final String description;
  final IconData icon;
}

abstract interface class PatientHistoryDataSource {
  Future<List<PatientHistoryEntry>> loadHistory();
}

class PatientHistoryRepository implements PatientHistoryDataSource {
  PatientHistoryRepository({SupabaseClient? client, UserRepository? users})
    : _clientOverride = client,
      _users = users ?? UserRepository(client: client);

  final SupabaseClient? _clientOverride;
  final UserRepository _users;

  SupabaseClient get _client =>
      _clientOverride ?? SupabaseClientProvider.client;

  @override
  Future<List<PatientHistoryEntry>> loadHistory() async {
    final pacienteId = await _users.findCurrentPatientId();
    if (pacienteId == null) {
      return [];
    }

    final results = await Future.wait<Object?>([
      _client
          .from(DatabaseTables.registrosEmocionais)
          .select(
            'id, data_registro, humor, como_sentiu, avaliacao_alimentacao, '
            'sintomas_emocionais_hoje, sintomas_fisicos_hoje, diario_emocional',
          )
          .eq('paciente_id', pacienteId)
          .order('data_registro', ascending: false)
          .limit(200),
      _client
          .from(DatabaseTables.registrosAlimentares)
          .select(
            'id, horario_refeicao, tipo_refeicao, descricao_refeicao, '
            'nivel_fome, sentimento_depois, observacoes',
          )
          .eq('paciente_id', pacienteId)
          .order('horario_refeicao', ascending: false)
          .limit(200),
    ]);

    final entries = <PatientHistoryEntry>[
      for (final row in results[0] as List<dynamic>)
        if (row is Map<String, dynamic>) _emotionalEntry(row),
      for (final row in results[1] as List<dynamic>)
        if (row is Map<String, dynamic>) _foodEntry(row),
    ]..sort((a, b) => b.moment.compareTo(a.moment));

    return entries;
  }

  PatientHistoryEntry _emotionalEntry(Map<String, dynamic> row) {
    final recordedAt =
        _date(row['data_registro']) ?? DateTime.fromMillisecondsSinceEpoch(0);
    final mood = _string(row['humor']).trim();
    final moodScore = _integer(row['como_sentiu']);
    final foodScore = _integer(row['avaliacao_alimentacao']);
    final mentalSymptoms = _symptoms(
      row['sintomas_emocionais_hoje'],
      PatientSymptoms.emotional,
    );
    final physicalSymptoms = _symptoms(
      row['sintomas_fisicos_hoje'],
      PatientSymptoms.physical,
    );
    final diary = _string(row['diario_emocional']).trim();

    final descriptionParts = <String>[
      if (mood.isNotEmpty) 'Humor: $mood',
      if (moodScore != null) 'Bem-estar: $moodScore/5',
      if (foodScore != null) 'Alimentação: $foodScore/5',
      if (mentalSymptoms.isNotEmpty)
        'Emocionais: ${mentalSymptoms.map((item) => item.label).join(', ')}',
      if (physicalSymptoms.isNotEmpty)
        'Físicos: ${physicalSymptoms.map((item) => item.label).join(', ')}',
      if (diary.isNotEmpty) diary,
    ];

    return PatientHistoryEntry(
      kind: PatientHistoryKind.emotional,
      moment: recordedAt,
      title: diary.isEmpty ? 'Check-in emocional' : 'Diário emocional',
      description: descriptionParts.isEmpty
          ? 'Check-in registrado'
          : descriptionParts.join(' · '),
      icon: diary.isEmpty
          ? Icons.favorite_outline_rounded
          : Icons.auto_stories_outlined,
    );
  }

  PatientHistoryEntry _foodEntry(Map<String, dynamic> row) {
    final recordedAt =
        _date(row['horario_refeicao']) ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final meal = _string(row['descricao_refeicao']).trim();
    final hunger = _integer(row['nivel_fome']);
    final feeling = _string(row['sentimento_depois']).trim();
    final observations = _string(row['observacoes']).trim();

    final descriptionParts = <String>[
      if (meal.isNotEmpty) meal,
      if (hunger != null) 'Fome: $hunger/10',
      if (feeling.isNotEmpty) feeling,
      if (observations.isNotEmpty) 'Observações: $observations',
    ];

    return PatientHistoryEntry(
      kind: PatientHistoryKind.food,
      moment: recordedAt,
      title: MealType.labelOf(row['tipo_refeicao']),
      description: descriptionParts.isEmpty
          ? 'Refeição registrada'
          : descriptionParts.join(' · '),
      icon: Icons.restaurant_rounded,
    );
  }

  List<PatientSymptom> _symptoms(
    Object? storedValue,
    List<PatientSymptom> definitions,
  ) {
    final codes = PatientSymptoms.decode(storedValue, definitions);
    return [
      for (final symptom in definitions)
        if (codes.contains(symptom.code)) symptom,
    ];
  }

  int? _integer(Object? value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '');
  }

  DateTime? _date(Object? value) => DateTime.tryParse(value?.toString() ?? '');

  String _string(Object? value) => value?.toString() ?? '';
}
