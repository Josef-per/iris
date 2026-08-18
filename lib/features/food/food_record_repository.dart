import 'package:iris/core/supabase/database_tables.dart';
import 'package:iris/core/supabase/supabase_client_provider.dart';
import 'package:iris/features/food/meal_image_picker.dart';
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
    this.photoPath,
  });

  final String id;
  final MealType? mealType;
  final String description;
  final int? hungerLevel;
  final String? feelingAfter;
  final String? observations;
  final String? photoPath;
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
      photoPath: _nullableString(map['foto_url']),
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

class FoodRecordSaveResult {
  const FoodRecordSaveResult({this.photoIssue});

  final FoodRecordPhotoIssue? photoIssue;

  bool get hasPhotoIssue => photoIssue != null;
}

enum FoodRecordPhotoIssue { uploadFailed, previousPhotoCleanupFailed }

class FoodRecordDeleteResult {
  const FoodRecordDeleteResult({this.photoCleanupFailed = false});

  final bool photoCleanupFailed;
}

abstract interface class FoodRecordDataSource {
  Future<FoodRecordSaveResult> createRecord({
    required String description,
    required int hungerLevel,
    MealType? mealType,
    String? feelingAfter,
    String? observations,
    DateTime? mealTime,
    MealImage? photo,
  });

  Future<FoodRecordSaveResult> updateRecord({
    required String id,
    required String description,
    required int hungerLevel,
    MealType? mealType,
    String? feelingAfter,
    String? observations,
    DateTime? mealTime,
    MealImage? photo,
  });

  Future<FoodRecordDeleteResult> deleteRecord(String id);

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

  static const _photoBucket = 'registro-alimentar';

  SupabaseClient get _client =>
      _clientOverride ?? SupabaseClientProvider.client;

  @override
  Future<FoodRecordSaveResult> createRecord({
    required String description,
    required int hungerLevel,
    MealType? mealType,
    String? feelingAfter,
    String? observations,
    DateTime? mealTime,
    MealImage? photo,
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

    if (photo == null) {
      await _client.from(DatabaseTables.registrosAlimentares).insert({
        'paciente_id': pacienteId,
        ...values,
      });
      return const FoodRecordSaveResult();
    }

    final created = await _client
        .from(DatabaseTables.registrosAlimentares)
        .insert({'paciente_id': pacienteId, ...values})
        .select('id')
        .single();
    final recordId = created['id']?.toString();
    if (recordId == null || recordId.isEmpty) {
      throw const FormatException(
        'Registro alimentar salvo sem identificador.',
      );
    }

    return _savePhoto(recordId: recordId, photo: photo);
  }

  @override
  Future<FoodRecordSaveResult> updateRecord({
    required String id,
    required String description,
    required int hungerLevel,
    MealType? mealType,
    String? feelingAfter,
    String? observations,
    DateTime? mealTime,
    MealImage? photo,
  }) async {
    final values = _validatedValues(
      description: description,
      hungerLevel: hungerLevel,
      mealType: mealType,
      feelingAfter: feelingAfter,
      observations: observations,
      mealTime: mealTime,
    );

    if (photo == null) {
      await _client
          .from(DatabaseTables.registrosAlimentares)
          .update(values)
          .eq('id', id);
      return const FoodRecordSaveResult();
    }

    final existing = await _client
        .from(DatabaseTables.registrosAlimentares)
        .select('foto_url')
        .eq('id', id)
        .single();
    final previousPhotoPath = _emptyToNull(existing['foto_url']?.toString());

    await _client
        .from(DatabaseTables.registrosAlimentares)
        .update(values)
        .eq('id', id);

    final result = await _savePhoto(recordId: id, photo: photo);
    if (result.hasPhotoIssue) return result;

    if (previousPhotoPath == null) return result;
    try {
      await _client.storage.from(_photoBucket).remove([previousPhotoPath]);
      return result;
    } catch (_) {
      return const FoodRecordSaveResult(
        photoIssue: FoodRecordPhotoIssue.previousPhotoCleanupFailed,
      );
    }
  }

  @override
  Future<FoodRecordDeleteResult> deleteRecord(String id) async {
    final existing = await _client
        .from(DatabaseTables.registrosAlimentares)
        .select('foto_url')
        .eq('id', id)
        .maybeSingle();
    final photoPath = _emptyToNull(existing?['foto_url']?.toString());

    await _client
        .from(DatabaseTables.registrosAlimentares)
        .delete()
        .eq('id', id);

    if (photoPath == null) return const FoodRecordDeleteResult();

    try {
      await _client.storage.from(_photoBucket).remove([photoPath]);
      return const FoodRecordDeleteResult();
    } catch (_) {
      return const FoodRecordDeleteResult(photoCleanupFailed: true);
    }
  }

  Future<FoodRecordSaveResult> _savePhoto({
    required String recordId,
    required MealImage photo,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return const FoodRecordSaveResult(
        photoIssue: FoodRecordPhotoIssue.uploadFailed,
      );
    }

    final extension = _photoExtension(photo);
    final path =
        '$userId/$recordId/${_clock().microsecondsSinceEpoch}.$extension';
    var uploaded = false;

    try {
      await _client.storage
          .from(_photoBucket)
          .uploadBinary(
            path,
            photo.bytes,
            fileOptions: FileOptions(
              contentType: _photoContentType(photo, extension),
              upsert: false,
            ),
          );
      uploaded = true;

      await _client
          .from(DatabaseTables.registrosAlimentares)
          .update({'foto_url': path})
          .eq('id', recordId);
      return const FoodRecordSaveResult();
    } catch (_) {
      if (uploaded) {
        try {
          await _client.storage.from(_photoBucket).remove([path]);
        } catch (_) {
          // A foto sem referência será removida em uma rotina de manutenção.
        }
      }
      return const FoodRecordSaveResult(
        photoIssue: FoodRecordPhotoIssue.uploadFailed,
      );
    }
  }

  String _photoExtension(MealImage photo) {
    final fileName = photo.fileName.trim();
    final separator = fileName.lastIndexOf('.');
    if (separator >= 0 && separator < fileName.length - 1) {
      final extension = fileName.substring(separator + 1).toLowerCase();
      if (RegExp(r'^[a-z0-9]{1,10}$').hasMatch(extension)) {
        return extension;
      }
    }

    return switch (photo.mimeType) {
      'image/png' => 'png',
      'image/webp' => 'webp',
      'image/heic' => 'heic',
      _ => 'jpg',
    };
  }

  String _photoContentType(MealImage photo, String extension) {
    final mimeType = photo.mimeType;
    if (mimeType != null && mimeType.startsWith('image/')) return mimeType;

    return switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      _ => 'image/jpeg',
    };
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
      'nivel_fome, sentimento_depois, observacoes, foto_url';

  String? _emptyToNull(String? value) {
    final cleanValue = value?.trim();

    if (cleanValue == null || cleanValue.isEmpty) {
      return null;
    }

    return cleanValue;
  }
}
