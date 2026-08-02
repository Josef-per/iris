import 'package:flutter/material.dart';
import 'package:iris/core/supabase/database_tables.dart';
import 'package:iris/core/supabase/supabase_client_provider.dart';
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

    final professionalId = await _users.getOrCreateCurrentProfessionalId();
    final ownData = await Future.wait<Object?>([
      _client
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
      _client
          .from(DatabaseTables.perfis)
          .select(
            'user_id, nome_completo, nome_social, telefone, data_nascimento',
          )
          .eq('user_id', authUser.id)
          .limit(1)
          .maybeSingle(),
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

    final linkRows = _asRows(
      await _client
          .from(DatabaseTables.pacienteProfissional)
          .select(
            'id, paciente_id, status, diagnostico, humor_atual, '
            'ultimo_registro, criado_em, atualizado_em',
          )
          .eq('profissional_id', professionalId)
          .eq('autorizacao_status', 'ativo')
          .order('criado_em', ascending: false),
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
    final linkIds = linkRows
        .map((row) => _string(row['id']))
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    final nextMonth = DateTime(now.year, now.month + 1);

    final workspaceData = await Future.wait<Object?>([
      _client
          .from(DatabaseTables.pacientes)
          .select('id, user_id')
          .inFilter('id', patientIds),
      _client
          .from(DatabaseTables.consultas)
          .select(
            'id, vinculo_id, inicio_em, modalidade, status, titulo, '
            'local_ou_link',
          )
          .inFilter('vinculo_id', linkIds)
          .gte('inicio_em', now.toUtc().toIso8601String())
          .neq('status', 'cancelada')
          .order('inicio_em')
          .limit(200),
      _client
          .from(DatabaseTables.consultas)
          .select('id')
          .inFilter('vinculo_id', linkIds)
          .gte('inicio_em', monthStart.toUtc().toIso8601String())
          .lt('inicio_em', nextMonth.toUtc().toIso8601String())
          .neq('status', 'cancelada'),
      _client
          .from(DatabaseTables.anotacoesClinicas)
          .select(
            'id, vinculo_id, profissional_id, conteudo, marcador, criado_em',
          )
          .inFilter('vinculo_id', linkIds)
          .order('criado_em', ascending: false)
          .limit(500),
      _client
          .from(DatabaseTables.planosCuidado)
          .select(
            'id, vinculo_id, orientacoes, passos_crise, '
            'compartilhar_paciente, alertar_checkins_ausentes',
          )
          .inFilter('vinculo_id', linkIds),
      _client
          .from(DatabaseTables.registrosEmocionais)
          .select(
            'id, paciente_id, data_registro, diario_emocional, humor, '
            'como_sentiu, avaliacao_alimentacao',
          )
          .inFilter('paciente_id', patientIds)
          .order('data_registro', ascending: false)
          .limit(1000),
      _client
          .from(DatabaseTables.registrosAlimentares)
          .select(
            'id, paciente_id, horario_refeicao, descricao_refeicao, '
            'nivel_fome, sentimento_depois, observacoes',
          )
          .inFilter('paciente_id', patientIds)
          .order('horario_refeicao', ascending: false)
          .limit(1000),
    ]);

    final patientRows = _asRows(workspaceData[0]);
    final appointmentRows = _asRows(workspaceData[1]);
    final appointmentsThisMonth = _asRows(workspaceData[2]).length;
    final noteRows = _asRows(workspaceData[3]);
    final planRows = _asRows(workspaceData[4]);
    final emotionalRows = _asRows(workspaceData[5]);
    final foodRows = _asRows(workspaceData[6]);

    final userIds = patientRows
        .map((row) => _string(row['user_id']))
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    final planIds = planRows
        .map((row) => _string(row['id']))
        .where((id) => id.isNotEmpty)
        .toList(growable: false);

    final relatedData = await Future.wait<Object?>([
      if (userIds.isEmpty)
        Future<Object?>.value(const <Map<String, dynamic>>[])
      else
        _client
            .from(DatabaseTables.perfis)
            .select(
              'user_id, nome_completo, nome_social, telefone, data_nascimento',
            )
            .inFilter('user_id', userIds),
      if (userIds.isEmpty)
        Future<Object?>.value(const <Map<String, dynamic>>[])
      else
        _client
            .from(DatabaseTables.usuarios)
            .select('id, email')
            .inFilter('id', userIds),
      if (planIds.isEmpty)
        Future<Object?>.value(const <Map<String, dynamic>>[])
      else
        _client
            .from(DatabaseTables.metasCuidado)
            .select('id, plano_id, descricao, concluida, ordem')
            .inFilter('plano_id', planIds)
            .order('ordem'),
      if (planIds.isEmpty)
        Future<Object?>.value(const <Map<String, dynamic>>[])
      else
        _client
            .from(DatabaseTables.medicacoesPlano)
            .select('id, plano_id, nome, dose, frequencia, adesao, ordem')
            .inFilter('plano_id', planIds)
            .order('ordem'),
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
    var alerts = 0;
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
      if (recordedAt.isAfter(alertCutoff) &&
          ((moodScore != null && moodScore <= 2) ||
              (foodScore != null && foodScore <= 2))) {
        alerts++;
      }

      final diary = _string(row['diario_emocional']).trim();
      final descriptionParts = <String>[
        if (mood.isNotEmpty) 'Humor: $mood',
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
                color: const Color(0xFF7D6AC6),
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
      final hunger = _integer(row['nivel_fome']);
      final feeling = _string(row['sentimento_depois']).trim();
      final descriptionParts = <String>[
        if (meal.isNotEmpty) meal,
        if (hunger != null) 'Fome: $hunger/5',
        if (feeling.isNotEmpty) feeling,
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
                color: const Color(0xFF3D7A55),
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
      records[patient.id] = [for (final item in items.take(20)) item.record];
    }

    return ProfessionalWorkspaceSnapshot(
      patients: patients,
      appointments: appointments,
      notes: notes,
      carePlans: carePlans,
      records: records,
      settings: settings,
      appointmentsThisMonth: appointmentsThisMonth,
      alerts: alerts,
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
    return patient;
  }

  @override
  Future<ProfessionalAppointment> addAppointment(
    ProfessionalAppointment appointment,
  ) async {
    final linkId = await _requireLinkId(appointment.patient.id);
    final startsAt =
        appointment.startsAt ?? _parseAppointmentInput(appointment.time);
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
    final linkId = await _requireLinkId(note.patientId);
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
    final linkId = await _requireLinkId(patient.id);
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

    await _client.auth.updateUser(
      UserAttributes(
        email: normalizedEmail != currentEmail ? normalizedEmail : null,
        data: {...?authUser.userMetadata, 'display_name': settings.name.trim()},
      ),
    );

    final persistedCredentialStatus = _string(credentialStatus).trim();
    return settings.copyWith(
      email: normalizedEmail,
      credentialStatus: persistedCredentialStatus.isEmpty
          ? settings.credentialStatus
          : persistedCredentialStatus,
    );
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

  Future<String> _requireProfessionalId() async {
    return _professionalId ??= await _users.getOrCreateCurrentProfessionalId();
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
