import 'package:flutter/material.dart';
import 'package:iris/core/supabase/database_tables.dart';
import 'package:iris/core/supabase/supabase_client_provider.dart';
import 'package:iris/features/emotional_diary/patient_symptoms.dart';
import 'package:iris/features/food/meal_type.dart';
import 'package:iris/features/professional/presentation/professional_frontend_store.dart';
import 'package:iris/features/professional/presentation/professional_models.dart';
import 'package:iris/features/users/user_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase implementation of the professional workspace.
///
/// This adapter never seeds presentation data. An authenticated professional
/// with no links receives an empty workspace, while a professional whose
/// credential is pending receives only their own persisted settings.
class SupabaseProfessionalWorkspaceBackend
    implements ProfessionalWorkspaceBackend {
  SupabaseProfessionalWorkspaceBackend({
    SupabaseClient? client,
    UserRepository? users,
  }) : _clientOverride = client,
       _users = users ?? UserRepository(client: client);

  final SupabaseClient? _clientOverride;
  final UserRepository _users;

  final Map<String, String> _linkIdsByPatient = {};
  final Map<String, ProfessionalPatient> _patientsById = {};
  final Set<String> _activePatientIds = {};
  String? _professionalId;

  SupabaseClient get _client =>
      _clientOverride ?? SupabaseClientProvider.client;

  @override
  Future<ProfessionalWorkspaceSnapshot> loadWorkspace() async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) {
      throw const ProfessionalWorkspaceException(
        'Faça login para acessar a área profissional.',
      );
    }

    final professionalId = await _runWorkspaceQuery(
      'resolver-profissional',
      _resolveProfessionalId,
    );
    final ownData = await Future.wait<Object?>([
      _runWorkspaceQuery(
        'dados-profissionais',
        () => _client
            .from(DatabaseTables.profissionais)
            .select(
              'id, user_id, especialidade, registro_profissional, biografia, '
              'telefone, clinica, endereco_clinica, iniciais_avatar, '
              'notificacoes_consultas, alertas_crise, relatorios_automaticos, '
              'credenciamento_status',
            )
            .eq('id', professionalId)
            .limit(1)
            .maybeSingle(),
      ),
      _runWorkspaceQuery(
        'perfil-profissional',
        () => _client
            .from(DatabaseTables.perfis)
            .select(
              'user_id, nome_completo, nome_social, telefone, data_nascimento',
            )
            .eq('user_id', authUser.id)
            .limit(1)
            .maybeSingle(),
      ),
    ]);

    final professionalRow = _asNullableRow(ownData[0]);
    if (professionalRow == null) {
      throw const ProfessionalWorkspaceException(
        'Perfil profissional não encontrado.',
      );
    }
    final ownProfile = _asNullableRow(ownData[1]) ?? const <String, dynamic>{};
    final settings = _settingsFromRows(
      professionalRow: professionalRow,
      profileRow: ownProfile,
      email: authUser.email ?? '',
    );

    _professionalId = professionalId;
    _linkIdsByPatient.clear();
    _patientsById.clear();
    _activePatientIds.clear();

    if (settings.credentialStatus != 'ativo') {
      return ProfessionalWorkspaceSnapshot(
        patients: const [],
        appointments: const [],
        notes: const [],
        carePlans: const {},
        records: const {},
        settings: settings,
        appointmentsThisMonth: 0,
        alerts: 0,
      );
    }

    final linkRows = await _runWorkspaceQuery(
      'vinculos-paciente-profissional',
      () => _paginateRows(
        (from, to) async => _client
            .from(DatabaseTables.pacienteProfissional)
            .select(
              'id, paciente_id, status, diagnostico, humor_atual, '
              'ultimo_registro, criado_em, atualizado_em',
            )
            .eq('profissional_id', professionalId)
            .eq('autorizacao_status', 'ativo')
            .order('criado_em', ascending: false)
            .order('id', ascending: false)
            .range(from, to)
            .count(CountOption.exact),
      ),
    );

    if (linkRows.isEmpty) {
      return ProfessionalWorkspaceSnapshot(
        patients: const [],
        appointments: const [],
        notes: const [],
        carePlans: const {},
        records: const {},
        settings: settings,
        appointmentsThisMonth: 0,
        alerts: 0,
      );
    }

    final patientIds = linkRows
        .map((row) => _string(row['paciente_id']))
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    final activeLinkRows = linkRows
        .where((row) => _string(row['status']) != 'inativo')
        .toList(growable: false);
    final activePatientIds = activeLinkRows
        .map((row) => _string(row['paciente_id']))
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    final activeLinkIds = activeLinkRows
        .map((row) => _string(row['id']))
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    final nextMonth = DateTime(now.year, now.month + 1);

    final workspaceData = await Future.wait<Object?>([
      _runWorkspaceQuery('pacientes', () => _patientRows(patientIds)),
      _runWorkspaceQuery(
        'consultas',
        () => _appointmentRows(activeLinkIds, from: monthStart),
      ),
      _runWorkspaceQuery('anotacoes-clinicas', () => _noteRows(activeLinkIds)),
      _runWorkspaceQuery('planos-de-cuidado', () => _planRows(activeLinkIds)),
      _runWorkspaceQuery(
        'registros-emocionais',
        () => _emotionalRows(activePatientIds),
      ),
      _runWorkspaceQuery(
        'registros-alimentares',
        () => _foodRows(activePatientIds),
      ),
    ]);

    final patientRows = _asRows(workspaceData[0]);
    final allAppointmentRows = _asRows(workspaceData[1]);
    final appointmentRows = allAppointmentRows
        .where((row) {
          final startsAt = _date(row['inicio_em']);
          return startsAt != null && !startsAt.isBefore(now);
        })
        .toList(growable: false);
    final appointmentsThisMonth = allAppointmentRows.where((row) {
      final startsAt = _date(row['inicio_em']);
      return startsAt != null && startsAt.isBefore(nextMonth);
    }).length;
    final noteRows = _asRows(workspaceData[2]);
    final planRows = _asRows(workspaceData[3]);
    final emotionalRows = _asRows(workspaceData[4]);
    final foodRows = _asRows(workspaceData[5]);

    final userIds = patientRows
        .map((row) => _string(row['user_id']))
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    final planIds = planRows
        .map((row) => _string(row['id']))
        .where((id) => id.isNotEmpty)
        .toList(growable: false);

    final relatedData = await Future.wait<Object?>([
      _runWorkspaceQuery('perfis-dos-pacientes', () => _profileRows(userIds)),
      _runWorkspaceQuery('usuarios-dos-pacientes', () => _userRows(userIds)),
      _runWorkspaceQuery('metas-de-cuidado', () => _goalRows(planIds)),
      _runWorkspaceQuery('medicacoes-do-plano', () => _medicationRows(planIds)),
    ]);

    final profilesByUser = {
      for (final row in _asRows(relatedData[0])) _string(row['user_id']): row,
    };
    final usersById = {
      for (final row in _asRows(relatedData[1])) _string(row['id']): row,
    };
    final goalsByPlan = _groupBy(
      _asRows(relatedData[2]),
      (row) => _string(row['plano_id']),
    );
    final medicationsByPlan = _groupBy(
      _asRows(relatedData[3]),
      (row) => _string(row['plano_id']),
    );
    final patientRowsById = {
      for (final row in patientRows) _string(row['id']): row,
    };
    final linksByPatient = {
      for (final row in linkRows) _string(row['paciente_id']): row,
    };
    final patientIdByLink = {
      for (final row in linkRows)
        _string(row['id']): _string(row['paciente_id']),
    };

    final datedRecords = <String, List<_DatedProfessionalRecord>>{
      for (final id in patientIds) id: [],
    };
    final lastRecordByPatient = <String, DateTime>{};
    final latestMoodByPatient = <String, String>{};
    final clinicalAlerts = <ProfessionalClinicalAlert>[];
    final alertCutoff = now.subtract(const Duration(hours: 24));

    for (final row in emotionalRows) {
      final patientId = _string(row['paciente_id']);
      final recordedAt = _date(row['data_registro']);
      if (patientId.isEmpty || recordedAt == null) continue;

      lastRecordByPatient.update(
        patientId,
        (current) => current.isAfter(recordedAt) ? current : recordedAt,
        ifAbsent: () => recordedAt,
      );
      final mood = _string(row['humor']).trim();
      if (mood.isNotEmpty && !latestMoodByPatient.containsKey(patientId)) {
        latestMoodByPatient[patientId] = mood;
      }
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
      final alertReasons = <String>[
        if (moodScore != null && moodScore <= 2) 'Bem-estar $moodScore/5',
        if (foodScore != null && foodScore <= 2) 'Alimentação $foodScore/5',
        for (final symptom in [...mentalSymptoms, ...physicalSymptoms])
          if (_criticalSymptomCodes.contains(symptom.code)) symptom.label,
      ];
      if (settings.crisisAlerts &&
          recordedAt.isAfter(alertCutoff) &&
          alertReasons.isNotEmpty) {
        clinicalAlerts.add(
          ProfessionalClinicalAlert(
            id: _string(row['id']),
            patientId: patientId,
            occurredAt: recordedAt,
            reasons: alertReasons,
          ),
        );
      }

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
      datedRecords
          .putIfAbsent(patientId, () => [])
          .add(
            _DatedProfessionalRecord(
              recordedAt,
              ProfessionalRecord(
                title: diary.isEmpty
                    ? 'Check-in emocional'
                    : 'Diário emocional',
                description: descriptionParts.isEmpty
                    ? 'Check-in registrado'
                    : descriptionParts.join(' · '),
                time: _relativeDateTime(recordedAt, now),
                icon: diary.isEmpty
                    ? Icons.favorite_outline_rounded
                    : Icons.auto_stories_outlined,
                tone: ProfessionalRecordTone.brand,
              ),
            ),
          );
    }

    for (final row in foodRows) {
      final patientId = _string(row['paciente_id']);
      final recordedAt = _date(row['horario_refeicao']);
      if (patientId.isEmpty || recordedAt == null) continue;

      lastRecordByPatient.update(
        patientId,
        (current) => current.isAfter(recordedAt) ? current : recordedAt,
        ifAbsent: () => recordedAt,
      );
      final meal = _string(row['descricao_refeicao']).trim();
      final mealType = MealType.labelOf(row['tipo_refeicao']);
      final hunger = _integer(row['nivel_fome']);
      final feeling = _string(row['sentimento_depois']).trim();
      final observations = _string(row['observacoes']).trim();
      final descriptionParts = <String>[
        if (mealType != 'Refeição') mealType,
        if (meal.isNotEmpty) meal,
        if (hunger != null) 'Fome: $hunger/10',
        if (feeling.isNotEmpty) feeling,
        if (observations.isNotEmpty) 'Observações: $observations',
      ];
      datedRecords
          .putIfAbsent(patientId, () => [])
          .add(
            _DatedProfessionalRecord(
              recordedAt,
              ProfessionalRecord(
                title: 'Registro alimentar',
                description: descriptionParts.isEmpty
                    ? 'Refeição registrada'
                    : descriptionParts.join(' · '),
                time: _relativeDateTime(recordedAt, now),
                icon: Icons.restaurant_rounded,
                tone: ProfessionalRecordTone.success,
              ),
            ),
          );
    }

    final nextAppointmentByPatient = <String, DateTime>{};
    for (final row in appointmentRows) {
      final patientId = patientIdByLink[_string(row['vinculo_id'])];
      final startsAt = _date(row['inicio_em']);
      if (patientId == null || startsAt == null) continue;
      nextAppointmentByPatient.update(
        patientId,
        (current) => current.isBefore(startsAt) ? current : startsAt,
        ifAbsent: () => startsAt,
      );
    }

    final patients = <ProfessionalPatient>[];
    for (final patientId in patientIds) {
      final patientRow = patientRowsById[patientId];
      final linkRow = linksByPatient[patientId];
      if (patientRow == null || linkRow == null) continue;
      final userId = _string(patientRow['user_id']);
      final profileRow = profilesByUser[userId] ?? const <String, dynamic>{};
      final userRow = usersById[userId] ?? const <String, dynamic>{};
      final birthDate = _date(profileRow['data_nascimento']);
      final persistedLastRecord = _date(linkRow['ultimo_registro']);
      final calculatedLastRecord = lastRecordByPatient[patientId];
      final lastRecord = _latest(persistedLastRecord, calculatedLastRecord);
      final nextAppointment = nextAppointmentByPatient[patientId];
      final profileName = _firstNonEmpty([
        _string(profileRow['nome_social']),
        _string(profileRow['nome_completo']),
      ]);

      final patient = ProfessionalPatient(
        id: patientId,
        linkId: _string(linkRow['id']),
        name: profileName.isEmpty ? 'Paciente' : profileName,
        age: birthDate == null ? 0 : _ageAt(birthDate, now),
        diagnosis: _string(linkRow['diagnostico']),
        lastActivity: lastRecord == null
            ? 'Sem registros'
            : _relativeDateTime(lastRecord, now),
        status: _string(linkRow['status']) == 'inativo'
            ? PatientStatus.inactive
            : PatientStatus.active,
        mood: _firstNonEmpty([
          latestMoodByPatient[patientId] ?? '',
          _string(linkRow['humor_atual']),
        ]),
        email: _string(userRow['email']),
        phone: _string(profileRow['telefone']),
        birthDate: birthDate == null ? '' : _dateOnly(birthDate),
        nextAppointment: nextAppointment == null
            ? 'Sem consulta'
            : _appointmentDate(nextAppointment, now),
      );
      patients.add(patient);
      _patientsById[patientId] = patient;
      _linkIdsByPatient[patientId] = _string(linkRow['id']);
      if (patient.status == PatientStatus.active) {
        _activePatientIds.add(patientId);
      }
    }

    final appointments = <ProfessionalAppointment>[];
    for (final row in appointmentRows) {
      final patientId = patientIdByLink[_string(row['vinculo_id'])];
      final patient = patientId == null ? null : _patientsById[patientId];
      final startsAt = _date(row['inicio_em']);
      if (patient == null || startsAt == null) continue;
      appointments.add(
        ProfessionalAppointment(
          id: _string(row['id']),
          startsAt: startsAt,
          time: _timeOnly(startsAt),
          patient: patient,
          type: _modalityLabel(_string(row['modalidade'])),
        ),
      );
    }
    appointments.sort(
      (left, right) => left.startsAt!.compareTo(right.startsAt!),
    );

    final notes = <ProfessionalClinicalNote>[];
    for (final row in noteRows) {
      final patientId = patientIdByLink[_string(row['vinculo_id'])];
      final createdAt = _date(row['criado_em']);
      if (patientId == null ||
          !_patientsById.containsKey(patientId) ||
          createdAt == null) {
        continue;
      }
      notes.add(_noteFromRow(row, patientId: patientId, now: now));
    }

    final carePlans = <String, ProfessionalCarePlanDraft>{
      for (final patient in patients) patient.id: _emptyCarePlan,
    };
    for (final planRow in planRows) {
      final patientId = patientIdByLink[_string(planRow['vinculo_id'])];
      if (patientId == null || !_patientsById.containsKey(patientId)) continue;
      final planId = _string(planRow['id']);
      carePlans[patientId] = ProfessionalCarePlanDraft(
        goals: [
          for (final row in goalsByPlan[planId] ?? const [])
            ProfessionalGoal(
              id: _string(row['id']),
              text: _string(row['descricao']),
              completed: _boolean(row['concluida']),
            ),
        ],
        orientation: _string(planRow['orientacoes']),
        medications: [
          for (final row in medicationsByPlan[planId] ?? const [])
            ProfessionalMedication(
              name: _string(row['nome']),
              dose: _string(row['dose']),
              frequency: _string(row['frequencia']),
              adherence: _number(row['adesao']).clamp(0, 1).toDouble(),
            ),
        ],
        crisisSteps: _stringList(planRow['passos_crise']),
        shareWithPatient: _boolean(
          planRow['compartilhar_paciente'],
          fallback: true,
        ),
        notifyMissedCheckIns: _boolean(
          planRow['alertar_checkins_ausentes'],
          fallback: true,
        ),
      );
    }

    final records = <String, List<ProfessionalRecord>>{};
    for (final patient in patients) {
      final items = datedRecords[patient.id] ?? [];
      items.sort((left, right) => right.date.compareTo(left.date));
      records[patient.id] = [for (final item in items) item.record];
    }

    return ProfessionalWorkspaceSnapshot(
      patients: patients,
      appointments: appointments,
      notes: notes,
      carePlans: carePlans,
      records: records,
      settings: settings,
      appointmentsThisMonth: appointmentsThisMonth,
      alerts: clinicalAlerts.length,
      clinicalAlerts: clinicalAlerts,
    );
  }

  @override
  Future<ProfessionalPatient> updatePatient(ProfessionalPatient patient) async {
    final previous = _patientsById[patient.id];
    if (previous != null && _identityChanged(previous, patient)) {
      throw const ProfessionalWorkspaceException(
        'Dados pessoais pertencem ao paciente. Edite apenas diagnóstico, '
        'humor e status de acompanhamento.',
      );
    }

    final linkId = await _requireLinkId(patient.id);
    await _client.rpc(
      'iris_update_linked_patient',
      params: {
        'p_link_id': linkId,
        'p_diagnosis': patient.diagnosis.trim(),
        'p_follow_up_status': patient.status == PatientStatus.active
            ? 'ativo'
            : 'inativo',
        'p_current_mood': patient.mood.trim(),
      },
    );
    _patientsById[patient.id] = patient;
    if (patient.status == PatientStatus.active) {
      _activePatientIds.add(patient.id);
    } else {
      _activePatientIds.remove(patient.id);
    }
    return patient;
  }

  @override
  Future<ProfessionalAppointment> addAppointment(
    ProfessionalAppointment appointment,
  ) async {
    final linkId = await _requireActiveLinkId(appointment.patient.id);
    final startsAt =
        appointment.startsAt ?? _parseAppointmentInput(appointment.time);
    if (!startsAt.toLocal().isAfter(DateTime.now())) {
      throw const ProfessionalWorkspaceException(
        'O horário da consulta já passou. Informe uma data futura.',
      );
    }
    final row = _asRequiredRow(
      await _client
          .from(DatabaseTables.consultas)
          .insert({
            'vinculo_id': linkId,
            'inicio_em': startsAt.toUtc().toIso8601String(),
            'modalidade': _modalityValue(appointment.type),
            'status': 'agendada',
          })
          .select('id, vinculo_id, inicio_em, modalidade')
          .single(),
    );
    final persistedStart = _date(row['inicio_em']) ?? startsAt;
    return appointment.copyWith(
      id: _string(row['id']),
      startsAt: persistedStart,
      time: _timeOnly(persistedStart),
      type: _modalityLabel(_string(row['modalidade'])),
    );
  }

  @override
  Future<void> removeAppointment(ProfessionalAppointment appointment) async {
    final id = appointment.id;
    if (id == null || id.isEmpty) {
      throw const ProfessionalWorkspaceException(
        'A consulta ainda não foi salva.',
      );
    }
    await _client.from(DatabaseTables.consultas).delete().eq('id', id);
  }

  @override
  Future<ProfessionalClinicalNote> addNote(
    ProfessionalClinicalNote note,
  ) async {
    final professionalId = await _requireProfessionalId();
    final linkId = await _requireActiveLinkId(note.patientId);
    final row = _asRequiredRow(
      await _client
          .from(DatabaseTables.anotacoesClinicas)
          .insert({
            'vinculo_id': linkId,
            'profissional_id': professionalId,
            'conteudo': note.text.trim(),
            'marcador': note.tag.trim(),
          })
          .select('id, conteudo, marcador, criado_em')
          .single(),
    );
    return _noteFromRow(row, patientId: note.patientId, now: DateTime.now());
  }

  @override
  Future<ProfessionalClinicalNote> updateNote(
    ProfessionalClinicalNote note,
  ) async {
    await _requireActiveLinkId(note.patientId);
    final row = _asRequiredRow(
      await _client
          .from(DatabaseTables.anotacoesClinicas)
          .update({'conteudo': note.text.trim(), 'marcador': note.tag.trim()})
          .eq('id', note.id)
          .select('id, conteudo, marcador, criado_em')
          .single(),
    );
    return _noteFromRow(row, patientId: note.patientId, now: DateTime.now());
  }

  @override
  Future<void> removeNote(String noteId) async {
    await _client
        .from(DatabaseTables.anotacoesClinicas)
        .delete()
        .eq('id', noteId);
  }

  @override
  Future<ProfessionalCarePlanDraft> saveCarePlan(
    ProfessionalPatient patient,
    ProfessionalCarePlanDraft plan,
  ) async {
    final linkId = await _requireActiveLinkId(patient.id);
    await _client.rpc(
      'iris_save_care_plan',
      params: {
        'p_vinculo_id': linkId,
        'p_orientation': plan.orientation.trim(),
        'p_share_with_patient': plan.shareWithPatient,
        'p_notify_missed_checkins': plan.notifyMissedCheckIns,
        'p_crisis_steps': [
          for (final step in plan.crisisSteps)
            if (step.trim().isNotEmpty) step.trim(),
        ],
        'p_goals': [
          for (final goal in plan.goals)
            {'text': goal.text.trim(), 'completed': goal.completed},
        ],
        'p_medications': [
          for (final medication in plan.medications)
            {
              'name': medication.name.trim(),
              'dose': medication.dose.trim(),
              'frequency': medication.frequency.trim(),
              'adherence': medication.adherence.clamp(0, 1),
            },
        ],
      },
    );
    return plan;
  }

  @override
  Future<ProfessionalSettingsDraft> updateSettings(
    ProfessionalSettingsDraft settings,
  ) async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) {
      throw const ProfessionalWorkspaceException(
        'Faça login para salvar as configurações.',
      );
    }
    final normalizedEmail = settings.email.trim().toLowerCase();
    final currentEmail = (authUser.email ?? '').trim().toLowerCase();

    final credentialStatus = await _client.rpc(
      'iris_update_professional_settings',
      params: {
        'p_name': settings.name.trim(),
        'p_phone': settings.phone.trim(),
        'p_specialty': settings.specialty.trim(),
        'p_registration': settings.registration.trim(),
        'p_biography': settings.biography.trim(),
        'p_clinic': settings.clinic.trim(),
        'p_clinic_address': settings.clinicAddress.trim(),
        'p_avatar_initials': settings.avatarInitials.trim(),
        'p_appointment_notifications': settings.appointmentNotifications,
        'p_crisis_alerts': settings.crisisAlerts,
        'p_automatic_reports': settings.automaticReports,
      },
    );

    final persistedCredentialStatus = _string(credentialStatus).trim();
    final persistedProfileSettings = settings.copyWith(
      email: currentEmail,
      credentialStatus: persistedCredentialStatus.isEmpty
          ? settings.credentialStatus
          : persistedCredentialStatus,
    );
    late final String effectiveEmail;
    try {
      final response = await _client.auth.updateUser(
        UserAttributes(
          email: normalizedEmail != currentEmail ? normalizedEmail : null,
          data: {
            ...?authUser.userMetadata,
            'display_name': settings.name.trim(),
          },
        ),
      );
      // When e-mail confirmation is required Supabase keeps the current login
      // e-mail until the confirmation link is used. Reflect that actual state.
      effectiveEmail = _firstNonEmpty([
        response.user?.email ?? '',
        _client.auth.currentUser?.email ?? '',
        currentEmail,
      ]).toLowerCase();
    } on AuthException catch (error) {
      if (_isAuthSessionFailure(error)) rethrow;
      throw ProfessionalSettingsPartialUpdateException(
        persistedSettings: persistedProfileSettings.copyWith(
          email: (_client.auth.currentUser?.email ?? currentEmail)
              .trim()
              .toLowerCase(),
        ),
        message:
            'Os dados profissionais foram salvos, mas o e-mail de acesso não '
            'foi alterado. Verifique o e-mail informado e tente novamente.',
      );
    } catch (_) {
      throw ProfessionalSettingsPartialUpdateException(
        persistedSettings: persistedProfileSettings.copyWith(
          email: (_client.auth.currentUser?.email ?? currentEmail)
              .trim()
              .toLowerCase(),
        ),
        message:
            'Os dados profissionais foram salvos, mas o e-mail de acesso não '
            'foi alterado. Verifique o e-mail informado e tente novamente.',
      );
    }
    final persistedSettings = persistedProfileSettings.copyWith(
      email: effectiveEmail,
    );
    if (normalizedEmail != currentEmail && effectiveEmail != normalizedEmail) {
      throw ProfessionalSettingsPartialUpdateException(
        persistedSettings: persistedSettings,
        message:
            'Os dados profissionais foram salvos. Confirme a alteração no '
            'novo e-mail para concluir a troca do acesso.',
      );
    }
    return persistedSettings;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final email = _client.auth.currentUser?.email;
    if (email == null || email.isEmpty) {
      throw const ProfessionalWorkspaceException(
        'A conta atual não possui e-mail para validar a senha.',
      );
    }
    await _client.auth.signInWithPassword(
      email: email,
      password: currentPassword,
    );
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<List<Map<String, dynamic>>> _patientRows(List<String> ids) {
    return loadProfessionalWorkspaceRowsByChunks(
      ids,
      (chunk, from, to) async => _client
          .from(DatabaseTables.pacientes)
          .select('id, user_id')
          .inFilter('id', chunk)
          .order('id', ascending: true)
          .range(from, to)
          .count(CountOption.exact),
    );
  }

  Future<List<Map<String, dynamic>>> _appointmentRows(
    List<String> linkIds, {
    required DateTime from,
    DateTime? until,
  }) async {
    final rows = await loadProfessionalWorkspaceRowsByChunks(linkIds, (
      chunk,
      pageFrom,
      pageTo,
    ) async {
      var query = _client
          .from(DatabaseTables.consultas)
          .select(
            'id, vinculo_id, inicio_em, modalidade, status, titulo, '
            'local_ou_link',
          )
          .inFilter('vinculo_id', chunk)
          .gte('inicio_em', from.toUtc().toIso8601String())
          .neq('status', 'cancelada');
      if (until != null) {
        query = query.lt('inicio_em', until.toUtc().toIso8601String());
      }
      return query
          .order('inicio_em', ascending: true)
          .order('id', ascending: true)
          .range(pageFrom, pageTo)
          .count(CountOption.exact);
    });
    rows.sort((left, right) => _compareDateField(left, right, 'inicio_em'));
    return rows;
  }

  Future<List<Map<String, dynamic>>> _noteRows(List<String> linkIds) async {
    final rows = await loadProfessionalWorkspaceRowsByChunks(
      linkIds,
      (chunk, from, to) async => _client
          .from(DatabaseTables.anotacoesClinicas)
          .select(
            'id, vinculo_id, profissional_id, conteudo, marcador, criado_em',
          )
          .inFilter('vinculo_id', chunk)
          .order('criado_em', ascending: false)
          .order('id', ascending: false)
          .range(from, to)
          .count(CountOption.exact),
    );
    rows.sort(
      (left, right) =>
          _compareDateField(left, right, 'criado_em', descending: true),
    );
    return rows;
  }

  Future<List<Map<String, dynamic>>> _planRows(List<String> linkIds) {
    return loadProfessionalWorkspaceRowsByChunks(
      linkIds,
      (chunk, from, to) async => _client
          .from(DatabaseTables.planosCuidado)
          .select(
            'id, vinculo_id, orientacoes, passos_crise, '
            'compartilhar_paciente, alertar_checkins_ausentes',
          )
          .inFilter('vinculo_id', chunk)
          .order('id', ascending: true)
          .range(from, to)
          .count(CountOption.exact),
    );
  }

  Future<List<Map<String, dynamic>>> _emotionalRows(
    List<String> patientIds,
  ) async {
    final rows = await loadProfessionalWorkspaceRowsByChunks(
      patientIds,
      (chunk, from, to) async => _client
          .from(DatabaseTables.registrosEmocionais)
          .select(
            'id, paciente_id, data_registro, diario_emocional, humor, '
            'como_sentiu, avaliacao_alimentacao, '
            'sintomas_emocionais_hoje, sintomas_fisicos_hoje',
          )
          .inFilter('paciente_id', chunk)
          .order('data_registro', ascending: false)
          .order('id', ascending: false)
          .range(from, to)
          .count(CountOption.exact),
    );
    rows.sort(
      (left, right) =>
          _compareDateField(left, right, 'data_registro', descending: true),
    );
    return rows;
  }

  Future<List<Map<String, dynamic>>> _foodRows(List<String> patientIds) async {
    final rows = await loadProfessionalWorkspaceRowsByChunks(
      patientIds,
      (chunk, from, to) async => _client
          .from(DatabaseTables.registrosAlimentares)
          .select(
            'id, paciente_id, horario_refeicao, tipo_refeicao, '
            'descricao_refeicao, nivel_fome, sentimento_depois, observacoes',
          )
          .inFilter('paciente_id', chunk)
          .order('horario_refeicao', ascending: false)
          .order('id', ascending: false)
          .range(from, to)
          .count(CountOption.exact),
    );
    rows.sort(
      (left, right) =>
          _compareDateField(left, right, 'horario_refeicao', descending: true),
    );
    return rows;
  }

  Future<List<Map<String, dynamic>>> _profileRows(List<String> userIds) {
    return loadProfessionalWorkspaceRowsByChunks(
      userIds,
      (chunk, from, to) async => _client
          .from(DatabaseTables.perfis)
          .select(
            'user_id, nome_completo, nome_social, telefone, data_nascimento',
          )
          .inFilter('user_id', chunk)
          .order('user_id', ascending: true)
          .range(from, to)
          .count(CountOption.exact),
    );
  }

  Future<List<Map<String, dynamic>>> _userRows(List<String> userIds) {
    return loadProfessionalWorkspaceRowsByChunks(
      userIds,
      (chunk, from, to) async => _client
          .from(DatabaseTables.usuarios)
          .select('id, email')
          .inFilter('id', chunk)
          .order('id', ascending: true)
          .range(from, to)
          .count(CountOption.exact),
    );
  }

  Future<List<Map<String, dynamic>>> _goalRows(List<String> planIds) async {
    final rows = await loadProfessionalWorkspaceRowsByChunks(
      planIds,
      (chunk, from, to) async => _client
          .from(DatabaseTables.metasCuidado)
          .select('id, plano_id, descricao, concluida, ordem')
          .inFilter('plano_id', chunk)
          .order('ordem', ascending: true)
          .order('id', ascending: true)
          .range(from, to)
          .count(CountOption.exact),
    );
    rows.sort(_compareOrderedRows);
    return rows;
  }

  Future<List<Map<String, dynamic>>> _medicationRows(
    List<String> planIds,
  ) async {
    final rows = await loadProfessionalWorkspaceRowsByChunks(
      planIds,
      (chunk, from, to) async => _client
          .from(DatabaseTables.medicacoesPlano)
          .select('id, plano_id, nome, dose, frequencia, adesao, ordem')
          .inFilter('plano_id', chunk)
          .order('ordem', ascending: true)
          .order('id', ascending: true)
          .range(from, to)
          .count(CountOption.exact),
    );
    rows.sort(_compareOrderedRows);
    return rows;
  }

  Future<String> _requireProfessionalId() async {
    return _professionalId ??= await _resolveProfessionalId();
  }

  Future<String> _resolveProfessionalId() async {
    return await _users.findCurrentProfessionalId() ??
        _users.getOrCreateCurrentProfessionalId();
  }

  Future<String> _requireLinkId(String patientId) async {
    final cached = _linkIdsByPatient[patientId];
    if (cached != null && cached.isNotEmpty) return cached;

    final professionalId = await _requireProfessionalId();
    final row = await _client
        .from(DatabaseTables.pacienteProfissional)
        .select('id')
        .eq('paciente_id', patientId)
        .eq('profissional_id', professionalId)
        .eq('autorizacao_status', 'ativo')
        .limit(1)
        .maybeSingle();
    final id = _string(row?['id']);
    if (id.isEmpty) {
      throw const ProfessionalWorkspaceException(
        'Vínculo ativo com o paciente não encontrado.',
      );
    }
    _linkIdsByPatient[patientId] = id;
    return id;
  }

  Future<String> _requireActiveLinkId(String patientId) async {
    final cached = _linkIdsByPatient[patientId];
    if (cached != null &&
        cached.isNotEmpty &&
        _activePatientIds.contains(patientId)) {
      return cached;
    }

    final professionalId = await _requireProfessionalId();
    final row = await _client
        .from(DatabaseTables.pacienteProfissional)
        .select('id')
        .eq('paciente_id', patientId)
        .eq('profissional_id', professionalId)
        .eq('autorizacao_status', 'ativo')
        .eq('status', 'ativo')
        .limit(1)
        .maybeSingle();
    final id = _string(row?['id']);
    if (id.isEmpty) {
      throw const ProfessionalWorkspaceException(
        'Ative o acompanhamento antes de alterar dados clínicos.',
      );
    }
    _linkIdsByPatient[patientId] = id;
    _activePatientIds.add(patientId);
    return id;
  }

  ProfessionalClinicalNote _noteFromRow(
    Map<String, dynamic> row, {
    required String patientId,
    required DateTime now,
  }) {
    final createdAt = _date(row['criado_em']) ?? now;
    return ProfessionalClinicalNote(
      id: _string(row['id']),
      patientId: patientId,
      text: _string(row['conteudo']),
      date: _relativeDateTime(createdAt, now),
      tag: _string(row['marcador']),
    );
  }

  ProfessionalSettingsDraft _settingsFromRows({
    required Map<String, dynamic> professionalRow,
    required Map<String, dynamic> profileRow,
    required String email,
  }) {
    final name = _firstNonEmpty([
      _string(profileRow['nome_social']),
      _string(profileRow['nome_completo']),
    ]);
    final persistedInitials = _string(
      professionalRow['iniciais_avatar'],
    ).trim();
    return ProfessionalSettingsDraft(
      name: name,
      email: email,
      phone: _firstNonEmpty([
        _string(professionalRow['telefone']),
        _string(profileRow['telefone']),
      ]),
      specialty: _string(professionalRow['especialidade']),
      registration: _string(professionalRow['registro_profissional']),
      biography: _string(professionalRow['biografia']),
      clinic: _string(professionalRow['clinica']),
      clinicAddress: _string(professionalRow['endereco_clinica']),
      avatarInitials: persistedInitials.isEmpty
          ? _initials(name)
          : persistedInitials,
      appointmentNotifications: _boolean(
        professionalRow['notificacoes_consultas'],
        fallback: true,
      ),
      crisisAlerts: _boolean(professionalRow['alertas_crise'], fallback: true),
      automaticReports: _boolean(professionalRow['relatorios_automaticos']),
      credentialStatus: _firstNonEmpty([
        _string(professionalRow['credenciamento_status']),
        'pendente',
      ]),
    );
  }

  bool _identityChanged(
    ProfessionalPatient previous,
    ProfessionalPatient next,
  ) {
    return previous.name != next.name ||
        previous.age != next.age ||
        previous.email != next.email ||
        previous.phone != next.phone ||
        previous.birthDate != next.birthDate ||
        previous.nextAppointment != next.nextAppointment;
  }
}

class ProfessionalWorkspaceException implements Exception {
  const ProfessionalWorkspaceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class _DatedProfessionalRecord {
  const _DatedProfessionalRecord(this.date, this.record);

  final DateTime date;
  final ProfessionalRecord record;
}

const ProfessionalCarePlanDraft _emptyCarePlan = ProfessionalCarePlanDraft(
  goals: [],
  orientation: '',
  medications: [],
  crisisSteps: [],
  shareWithPatient: true,
  notifyMissedCheckIns: true,
);

const _pageSize = 500;
const _filterChunkSize = 100;
const _criticalSymptomCodes = {'vomito_autoinduzido', 'compulsao', 'desmaio'};

typedef _PageLoader =
    Future<PostgrestResponse<List<Map<String, dynamic>>>> Function(
      int from,
      int to,
    );
typedef ProfessionalWorkspaceChunkPageLoader =
    Future<PostgrestResponse<List<Map<String, dynamic>>>> Function(
      List<String> ids,
      int from,
      int to,
    );

Future<T> _runWorkspaceQuery<T>(
  String step,
  Future<T> Function() operation,
) async {
  try {
    return await operation();
  } catch (error) {
    debugPrint(
      '[ProfessionalWorkspace] etapa "$step" falhou '
      '(${error.runtimeType}): $error',
    );
    rethrow;
  }
}

Future<List<Map<String, dynamic>>> _paginateRows(_PageLoader loadPage) async {
  final rows = <Map<String, dynamic>>[];
  var from = 0;
  while (true) {
    final response = await loadPage(from, from + _pageSize - 1);
    final page = _asRows(response.data);
    if (page.isEmpty) break;
    rows.addAll(page);
    if (rows.length >= response.count) break;
    // Advance by what the server actually returned. This also remains correct
    // when a Supabase project configures a max-row cap below [_pageSize].
    from += page.length;
  }
  return rows;
}

/// Loads rows in filter-sized chunks and always returns a mutable collection.
///
/// An empty filter is a valid workspace state, such as a newly linked patient
/// without a care plan. Callers may sort the returned rows unconditionally.
Future<List<Map<String, dynamic>>> loadProfessionalWorkspaceRowsByChunks(
  List<String> ids,
  ProfessionalWorkspaceChunkPageLoader loadPage,
) async {
  if (ids.isEmpty) return <Map<String, dynamic>>[];
  final rows = <Map<String, dynamic>>[];
  final uniqueIds = ids.toSet().toList(growable: false);
  for (var start = 0; start < uniqueIds.length; start += _filterChunkSize) {
    final end = (start + _filterChunkSize).clamp(0, uniqueIds.length);
    final chunk = uniqueIds.sublist(start, end);
    rows.addAll(await _paginateRows((from, to) => loadPage(chunk, from, to)));
  }
  return rows;
}

int _compareDateField(
  Map<String, dynamic> left,
  Map<String, dynamic> right,
  String field, {
  bool descending = false,
}) {
  final leftDate = _date(left[field]);
  final rightDate = _date(right[field]);
  final comparison = switch ((leftDate, rightDate)) {
    (null, null) => _string(left['id']).compareTo(_string(right['id'])),
    (null, _) => 1,
    (_, null) => -1,
    (final a?, final b?) => a.compareTo(b),
  };
  return descending ? -comparison : comparison;
}

int _compareOrderedRows(Map<String, dynamic> left, Map<String, dynamic> right) {
  final planComparison = _string(
    left['plano_id'],
  ).compareTo(_string(right['plano_id']));
  if (planComparison != 0) return planComparison;
  final orderComparison = (_integer(left['ordem']) ?? 0).compareTo(
    _integer(right['ordem']) ?? 0,
  );
  if (orderComparison != 0) return orderComparison;
  return _string(left['id']).compareTo(_string(right['id']));
}

class _DisplayedSymptom {
  const _DisplayedSymptom(this.code, this.label);

  final String code;
  final String label;
}

List<_DisplayedSymptom> _symptoms(
  Object? value,
  List<PatientSymptom> definitions,
) {
  final codes = PatientSymptoms.decode(value, definitions);
  final definitionsByCode = {
    for (final definition in definitions) definition.code: definition,
  };
  return [
    for (final code in codes)
      _DisplayedSymptom(
        code,
        definitionsByCode[code]?.label ?? _humanizeCode(code),
      ),
  ];
}

String _humanizeCode(String code) {
  if (code.isEmpty) return 'Sintoma não identificado';
  final words = code.replaceAll('_', ' ');
  return '${words[0].toUpperCase()}${words.substring(1)}';
}

bool _isAuthSessionFailure(AuthException error) {
  final message = error.message.toLowerCase();
  return error is AuthSessionMissingException ||
      error.statusCode == '401' ||
      error.statusCode == '403' ||
      error.code == 'refresh_token_not_found' ||
      message.contains('jwt') ||
      message.contains('session missing');
}

List<Map<String, dynamic>> _asRows(Object? value) {
  if (value is! List) return const [];
  return [
    for (final item in value)
      if (item is Map) Map<String, dynamic>.from(item),
  ];
}

Map<String, dynamic>? _asNullableRow(Object? value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

Map<String, dynamic> _asRequiredRow(Object? value) {
  final row = _asNullableRow(value);
  if (row == null) {
    throw const ProfessionalWorkspaceException(
      'O servidor não retornou o registro salvo.',
    );
  }
  return row;
}

Map<String, List<Map<String, dynamic>>> _groupBy(
  List<Map<String, dynamic>> rows,
  String Function(Map<String, dynamic>) keyOf,
) {
  final result = <String, List<Map<String, dynamic>>>{};
  for (final row in rows) {
    final key = keyOf(row);
    if (key.isEmpty) continue;
    result.putIfAbsent(key, () => []).add(row);
  }
  return result;
}

String _string(Object? value) => value?.toString() ?? '';

String _firstNonEmpty(Iterable<String> values) {
  for (final value in values) {
    final normalized = value.trim();
    if (normalized.isNotEmpty) return normalized;
  }
  return '';
}

DateTime? _date(Object? value) {
  if (value is DateTime) return value.toLocal();
  final raw = value?.toString();
  if (raw == null || raw.isEmpty) return null;
  return DateTime.tryParse(raw)?.toLocal();
}

DateTime? _latest(DateTime? left, DateTime? right) {
  if (left == null) return right;
  if (right == null) return left;
  return left.isAfter(right) ? left : right;
}

int? _integer(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

double _number(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

bool _boolean(Object? value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value == null) return fallback;
  return value.toString().toLowerCase() == 'true';
}

List<String> _stringList(Object? value) {
  if (value is! List) return const [];
  return [
    for (final item in value)
      if (_string(item).trim().isNotEmpty) _string(item).trim(),
  ];
}

int _ageAt(DateTime birthDate, DateTime now) {
  var age = now.year - birthDate.year;
  final birthdayPassed =
      now.month > birthDate.month ||
      (now.month == birthDate.month && now.day >= birthDate.day);
  if (!birthdayPassed) age--;
  return age < 0 ? 0 : age;
}

String _dateOnly(DateTime date) {
  return '${_twoDigits(date.day)}/${_twoDigits(date.month)}/${date.year}';
}

String _timeOnly(DateTime date) {
  return '${_twoDigits(date.hour)}:${_twoDigits(date.minute)}';
}

String _appointmentDate(DateTime date, DateTime now) {
  if (_sameDay(date, now)) return 'Hoje, ${_timeOnly(date)}';
  final tomorrow = DateTime(now.year, now.month, now.day + 1);
  if (_sameDay(date, tomorrow)) return 'Amanhã, ${_timeOnly(date)}';
  return '${_dateOnly(date)}, ${_timeOnly(date)}';
}

String _relativeDateTime(DateTime date, DateTime now) {
  final difference = now.difference(date);
  if (!difference.isNegative && difference.inMinutes < 1) return 'Agora';
  if (!difference.isNegative && difference.inMinutes < 60) {
    return 'Há ${difference.inMinutes} min';
  }
  if (!difference.isNegative && difference.inHours < 24) {
    return 'Há ${difference.inHours} h';
  }
  final yesterday = DateTime(now.year, now.month, now.day - 1);
  if (_sameDay(date, yesterday)) return 'Ontem, ${_timeOnly(date)}';
  return '${_dateOnly(date)}, ${_timeOnly(date)}';
}

bool _sameDay(DateTime left, DateTime right) {
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .toList(growable: false);
  if (parts.isEmpty) return '';
  return parts.map((part) => part.characters.first.toUpperCase()).join();
}

String _modalityValue(String displayValue) {
  final normalized = displayValue.trim().toLowerCase();
  return normalized == 'presencial' ? 'presencial' : 'online';
}

String _modalityLabel(String databaseValue) {
  return databaseValue.trim().toLowerCase() == 'presencial'
      ? 'Presencial'
      : 'Online';
}

DateTime _parseAppointmentInput(String input) {
  final normalized = input.trim();
  final parsed = DateTime.tryParse(normalized);
  final now = DateTime.now();
  if (parsed != null) {
    final localDate = parsed.toLocal();
    if (!localDate.isAfter(now)) {
      throw const ProfessionalWorkspaceException(
        'O horário da consulta já passou. Informe uma data futura.',
      );
    }
    return localDate;
  }

  final match = RegExp(r'^([01]?\d|2[0-3]):([0-5]\d)$').firstMatch(normalized);
  if (match == null) {
    throw const ProfessionalWorkspaceException(
      'Informe o horário da consulta no formato HH:mm.',
    );
  }
  final startsAt = DateTime(
    now.year,
    now.month,
    now.day,
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
  );
  if (!startsAt.isAfter(now)) {
    throw const ProfessionalWorkspaceException(
      'Esse horário de hoje já passou. Informe um horário futuro.',
    );
  }
  return startsAt;
}
