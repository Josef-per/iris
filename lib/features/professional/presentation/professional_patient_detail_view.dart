import 'package:flutter/material.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/professional/presentation/professional_form_dialogs.dart';
import 'package:iris/features/professional/presentation/professional_frontend_store.dart';
import 'package:iris/features/professional/presentation/professional_models.dart';
import 'package:iris/features/professional/presentation/professional_shared_widgets.dart';

class ProfessionalPatientDetailView extends StatefulWidget {
  const ProfessionalPatientDetailView({
    super.key,
    required this.store,
    required this.patient,
    required this.onBack,
    required this.onOpenCarePlan,
    this.initialTab = 'overview',
    this.onTabChanged,
  });

  final ProfessionalFrontendStore store;
  final ProfessionalPatient patient;
  final VoidCallback onBack;
  final VoidCallback onOpenCarePlan;
  final String initialTab;
  final ValueChanged<String>? onTabChanged;

  @override
  State<ProfessionalPatientDetailView> createState() =>
      _ProfessionalPatientDetailViewState();
}

class _ProfessionalPatientDetailViewState
    extends State<ProfessionalPatientDetailView> {
  final _noteController = TextEditingController();
  late int _selectedTab;
  var _savingNote = false;

  @override
  void initState() {
    super.initState();
    _selectedTab = _tabIndex(widget.initialTab);
  }

  @override
  void didUpdateWidget(covariant ProfessionalPatientDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      _selectedTab = _tabIndex(widget.initialTab);
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _addNote() async {
    final patient = widget.store.patientByIdOrNull(widget.patient.id);
    if (widget.store.isConnected && patient?.status != PatientStatus.active) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ative o acompanhamento para criar anotações.'),
        ),
      );
      return;
    }
    final note = _noteController.text.trim();
    if (note.isEmpty || _savingNote) return;
    setState(() => _savingNote = true);
    try {
      await widget.store.addNote(
        ProfessionalClinicalNote(
          id: 'note-${DateTime.now().microsecondsSinceEpoch}',
          patientId: widget.patient.id,
          text: note,
          date: 'Agora',
          tag: 'Consulta',
        ),
      );
      _noteController.clear();
    } catch (error) {
      if (mounted) showProfessionalOperationError(context, error);
    } finally {
      if (mounted) setState(() => _savingNote = false);
    }
  }

  Future<void> _deleteNote(String id) async {
    final patient = widget.store.patientByIdOrNull(widget.patient.id);
    if (widget.store.isConnected && patient?.status != PatientStatus.active) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ative o acompanhamento para alterar anotações.'),
        ),
      );
      return;
    }
    try {
      await widget.store.removeNote(id);
    } catch (error) {
      if (mounted) showProfessionalOperationError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final patient = widget.store.patientById(widget.patient.id);
    final notes = widget.store.notes
        .where((note) => note.patientId == patient.id)
        .toList();
    return SingleChildScrollView(
      child: Column(
        children: [
          _PatientHero(
            patient: patient,
            onBack: widget.onBack,
            onOpenCarePlan: widget.onOpenCarePlan,
          ),
          ProfessionalPage(
            paddingTop: 22,
            child: Column(
              children: [
                _PatientTabs(
                  selectedIndex: _selectedTab,
                  onSelected: (index) {
                    setState(() => _selectedTab = index);
                    widget.onTabChanged?.call(_tabName(index));
                  },
                ),
                const SizedBox(height: 24),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: switch (_selectedTab) {
                    0 => _OverviewTab(
                      key: const ValueKey('overview'),
                      patient: patient,
                      store: widget.store,
                    ),
                    1 => _HistoryTab(
                      key: const ValueKey('history'),
                      demoMode: !widget.store.isConnected,
                    ),
                    _ => _NotesTab(
                      key: const ValueKey('notes'),
                      controller: _noteController,
                      notes: notes,
                      onAdd: _addNote,
                      onDelete: _deleteNote,
                      saving: _savingNote,
                      authorName: widget.store.settings.name,
                      canEdit:
                          !widget.store.isConnected ||
                          patient.status == PatientStatus.active,
                    ),
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

int _tabIndex(String tab) {
  return switch (tab) {
    'history' => 1,
    'notes' => 2,
    _ => 0,
  };
}

String _tabName(int index) {
  return switch (index) {
    1 => 'history',
    2 => 'notes',
    _ => 'overview',
  };
}

class _PatientHero extends StatelessWidget {
  const _PatientHero({
    required this.patient,
    required this.onBack,
    required this.onOpenCarePlan,
  });

  final ProfessionalPatient patient;
  final VoidCallback onBack;
  final VoidCallback onOpenCarePlan;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 700;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        compact ? 20 : 32,
        20,
        compact ? 20 : 32,
        compact ? 30 : 38,
      ),
      decoration: const BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.lg),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: onBack,
            style: TextButton.styleFrom(foregroundColor: AppColors.white),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Voltar para pacientes'),
          ),
          const SizedBox(height: 18),
          if (compact)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PatientHeroInfo(patient: patient),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onOpenCarePlan,
                  style: AppButtonStyles.onBrandFilled,
                  icon: const Icon(Icons.health_and_safety_outlined),
                  label: const Text('Plano de cuidado'),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(child: _PatientHeroInfo(patient: patient)),
                const SizedBox(width: 28),
                FilledButton.icon(
                  onPressed: onOpenCarePlan,
                  style: AppButtonStyles.onBrandFilled,
                  icon: const Icon(Icons.health_and_safety_outlined),
                  label: const Text('Plano de cuidado'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _PatientHeroInfo extends StatelessWidget {
  const _PatientHeroInfo({required this.patient});

  final ProfessionalPatient patient;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PatientAvatar(patient: patient, size: 76),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                patient.name,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.white,
                  fontSize: 30,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${patient.age} anos · ${patient.diagnosis}',
                style: const TextStyle(color: AppColors.white),
              ),
              const SizedBox(height: 8),
              PatientStatusBadge(status: patient.status),
            ],
          ),
        ),
      ],
    );
  }
}

class _PatientTabs extends StatelessWidget {
  const _PatientTabs({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    const labels = ['Visão geral', 'Histórico', 'Anotações'];
    return ProfessionalPanel(
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          for (var index = 0; index < labels.length; index++)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index == labels.length - 1 ? 0 : 6,
                ),
                child: Semantics(
                  button: true,
                  selected: selectedIndex == index,
                  label: labels[index],
                  excludeSemantics: true,
                  child: Material(
                    color: selectedIndex == index
                        ? AppColors.purpleAccessible
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: () => onSelected(index),
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        child: Text(
                          labels[index],
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: selectedIndex == index
                                ? AppColors.white
                                : Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({super.key, required this.patient, required this.store});

  final ProfessionalPatient patient;
  final ProfessionalFrontendStore store;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 920;
        final left = Column(
          children: [
            _PersonalInfoPanel(
              patient: patient,
              onEdit: () =>
                  showProfessionalPatientForm(context, store, patient: patient),
            ),
            const SizedBox(height: 20),
            if (store.isConnected)
              _RemoteLastCheckInPanel(patient: patient)
            else
              const _LastCheckInPanel(),
            const SizedBox(height: 20),
            if (store.isConnected)
              const _ClinicalDataEmptyPanel(
                title: 'Evolução alimentar',
                message: 'Nenhum registro alimentar disponível.',
                icon: Icons.restaurant_outlined,
              )
            else
              const _FoodEvolutionPanel(),
          ],
        );
        final right = Column(
          children: [
            _MedicationPanel(patient: patient, store: store),
            const SizedBox(height: 20),
            _RecentRecordsPanel(records: store.recordsFor(patient.id)),
          ],
        );
        if (!wide) {
          return Column(children: [left, const SizedBox(height: 20), right]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: 20),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}

class _PersonalInfoPanel extends StatelessWidget {
  const _PersonalInfoPanel({required this.patient, required this.onEdit});

  final ProfessionalPatient patient;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return ProfessionalPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfessionalSectionTitle(
            title: 'Informações pessoais',
            trailing: IconButton(
              tooltip: 'Editar paciente',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 520;
              final items = [
                ProfessionalInfoRow(
                  icon: Icons.cake_outlined,
                  label: 'Data de nascimento',
                  value: patient.birthDate,
                ),
                ProfessionalInfoRow(
                  icon: Icons.mail_outline_rounded,
                  label: 'E-mail',
                  value: patient.email,
                ),
                ProfessionalInfoRow(
                  icon: Icons.phone_outlined,
                  label: 'Telefone',
                  value: patient.phone,
                ),
                ProfessionalInfoRow(
                  icon: Icons.event_available_outlined,
                  label: 'Próxima consulta',
                  value: patient.nextAppointment,
                ),
              ];
              if (!wide) {
                return Column(
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      items[i],
                      if (i < items.length - 1) const SizedBox(height: 18),
                    ],
                  ],
                );
              }
              return Wrap(
                spacing: 22,
                runSpacing: 20,
                children: items
                    .map(
                      (item) => SizedBox(
                        width: (constraints.maxWidth - 22) / 2,
                        child: item,
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LastCheckInPanel extends StatelessWidget {
  const _LastCheckInPanel();

  @override
  Widget build(BuildContext context) {
    final semanticColors = AppSemanticColors.of(context);
    return ProfessionalPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ProfessionalSectionTitle(
            title: 'Último check-in',
            subtitle: 'Hoje, 09:20',
            trailing: _RiskBadge(),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _CheckInValue(
                icon: Icons.sentiment_satisfied_alt_rounded,
                label: 'Humor',
                value: 'Bem',
                color: semanticColors.success,
              ),
              _CheckInValue(
                icon: Icons.bedtime_outlined,
                label: 'Sono',
                value: '7h 30min',
                color: semanticColors.info,
              ),
              _CheckInValue(
                icon: Icons.psychology_alt_outlined,
                label: 'Ansiedade',
                value: 'Leve',
                color: semanticColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            '“Acordei mais disposta e consegui tomar café da manhã.”',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _RemoteLastCheckInPanel extends StatelessWidget {
  const _RemoteLastCheckInPanel({required this.patient});

  final ProfessionalPatient patient;

  @override
  Widget build(BuildContext context) {
    final hasActivity =
        patient.lastActivity.trim().isNotEmpty &&
        patient.lastActivity != 'Sem registros';
    return ProfessionalPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfessionalSectionTitle(
            title: 'Último check-in',
            subtitle: hasActivity ? patient.lastActivity : null,
          ),
          const SizedBox(height: 20),
          if (!hasActivity)
            const Text('Nenhum check-in disponível.')
          else
            _CheckInValue(
              icon: Icons.sentiment_satisfied_alt_rounded,
              label: 'Humor',
              value: patient.mood,
              color: AppSemanticColors.of(context).success,
            ),
        ],
      ),
    );
  }
}

class _ClinicalDataEmptyPanel extends StatelessWidget {
  const _ClinicalDataEmptyPanel({
    required this.title,
    required this.message,
    required this.icon,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ProfessionalPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfessionalSectionTitle(title: title),
          const SizedBox(height: 22),
          Center(
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 36,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 10),
                Text(message, textAlign: TextAlign.center),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskBadge extends StatelessWidget {
  const _RiskBadge();

  @override
  Widget build(BuildContext context) {
    final semanticColors = AppSemanticColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: semanticColors.successContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Sem alertas',
        style: TextStyle(
          color: semanticColors.onSuccessContainer,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CheckInValue extends StatelessWidget {
  const _CheckInValue({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 142),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontSize: 11),
              ),
              Text(
                value,
                style: TextStyle(color: color, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MedicationPanel extends StatelessWidget {
  const _MedicationPanel({required this.patient, required this.store});

  final ProfessionalPatient patient;
  final ProfessionalFrontendStore store;

  @override
  Widget build(BuildContext context) {
    final plan = store.carePlanFor(patient.id);
    final medications = plan.medications;
    final canEdit =
        !store.isConnected || patient.status == PatientStatus.active;

    Future<void> saveMedications(List<ProfessionalMedication> updated) async {
      try {
        await store.updateCarePlan(
          patient.id,
          plan.copyWith(medications: updated),
        );
      } catch (error) {
        if (context.mounted) {
          showProfessionalOperationError(context, error);
        }
      }
    }

    return ProfessionalPanel(
      child: Column(
        children: [
          ProfessionalSectionTitle(
            title: 'Medicações',
            subtitle: '${medications.length} itens',
            trailing: IconButton.filledTonal(
              tooltip: canEdit
                  ? 'Adicionar medicação'
                  : 'Ative o acompanhamento para alterar',
              onPressed: !canEdit
                  ? null
                  : () async {
                      final result = await showProfessionalMedicationForm(
                        context,
                      );
                      if (result == null) return;
                      await saveMedications([...medications, result]);
                    },
              icon: const Icon(Icons.add_rounded),
            ),
          ),
          const SizedBox(height: 14),
          if (medications.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Nenhuma medicação.'),
            )
          else
            ...medications.asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _MedicationRow(
                  medication: entry.value,
                  canEdit: canEdit,
                  onEdit: () async {
                    final result = await showProfessionalMedicationForm(
                      context,
                      medication: entry.value,
                    );
                    if (result == null) return;
                    final updated = [...medications];
                    updated[entry.key] = result;
                    await saveMedications(updated);
                  },
                  onDelete: () async {
                    final updated = [...medications]..removeAt(entry.key);
                    await saveMedications(updated);
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MedicationRow extends StatelessWidget {
  const _MedicationRow({
    required this.medication,
    required this.canEdit,
    required this.onEdit,
    required this.onDelete,
  });

  final ProfessionalMedication medication;
  final bool canEdit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final success = AppSemanticColors.of(context).success;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.medication_outlined, color: colors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${medication.name} · ${medication.dose}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      medication.frequency,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Text(
                '${(medication.adherence * 100).round()}%',
                style: TextStyle(color: success, fontWeight: FontWeight.w800),
              ),
              PopupMenuButton<String>(
                enabled: canEdit,
                tooltip: canEdit
                    ? 'Ações da medicação'
                    : 'Ative o acompanhamento para alterar',
                onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Editar')),
                  PopupMenuItem(value: 'delete', child: Text('Remover')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: medication.adherence,
              minHeight: 7,
              backgroundColor: colors.surfaceContainerHighest,
              color: success,
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodEvolutionPanel extends StatelessWidget {
  const _FoodEvolutionPanel();

  @override
  Widget build(BuildContext context) {
    return const ProfessionalPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfessionalSectionTitle(
            title: 'Evolução alimentar',
            subtitle: 'Acompanhamento dos últimos 7 dias',
          ),
          SizedBox(height: 22),
          _FoodProgress(
            label: 'Refeições registradas',
            value: .86,
            detail: '18 de 21',
          ),
          SizedBox(height: 18),
          _FoodProgress(
            label: 'Refeições completas',
            value: .72,
            detail: '13 de 18',
          ),
          SizedBox(height: 18),
          _FoodProgress(
            label: 'Sem episódios de crise',
            value: .94,
            detail: '6 de 7 dias',
          ),
        ],
      ),
    );
  }
}

class _FoodProgress extends StatelessWidget {
  const _FoodProgress({
    required this.label,
    required this.value,
    required this.detail,
  });

  final String label;
  final double value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text(
              detail,
              style: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 9,
            backgroundColor: colors.surfaceContainerHighest,
            color: colors.primary,
          ),
        ),
      ],
    );
  }
}

class _RecentRecordsPanel extends StatelessWidget {
  const _RecentRecordsPanel({required this.records});

  final List<ProfessionalRecord> records;

  @override
  Widget build(BuildContext context) {
    return ProfessionalPanel(
      child: Column(
        children: [
          const ProfessionalSectionTitle(title: 'Registros recentes'),
          const SizedBox(height: 14),
          if (records.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('Nenhum registro recente disponível.'),
            )
          else
            ...records.map((record) => _RecordRow(record: record)),
        ],
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({required this.record});

  final ProfessionalRecord record;

  @override
  Widget build(BuildContext context) {
    final color = _recordColor(context, record.tone);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: AppRadius.small,
            ),
            child: Icon(record.icon, color: color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        record.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      record.time,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  record.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Color _recordColor(BuildContext context, ProfessionalRecordTone tone) {
  final colors = Theme.of(context).colorScheme;
  final semanticColors = AppSemanticColors.of(context);
  return switch (tone) {
    ProfessionalRecordTone.brand => colors.primary,
    ProfessionalRecordTone.success => semanticColors.success,
    ProfessionalRecordTone.warning => semanticColors.warning,
    ProfessionalRecordTone.info => semanticColors.info,
  };
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({super.key, required this.demoMode});

  final bool demoMode;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const weeks = [
      ('21–27 jul', 'Bem', '18/21', '92%', 'Sem alertas'),
      ('14–20 jul', 'Mais ou menos', '16/21', '84%', '1 alerta leve'),
      ('07–13 jul', 'Bem', '19/21', '96%', 'Sem alertas'),
      ('30 jun–06 jul', 'Bem', '17/21', '89%', 'Sem alertas'),
    ];
    return ProfessionalPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ProfessionalSectionTitle(title: 'Histórico'),
          const SizedBox(height: 22),
          if (!demoMode)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('Nenhum histórico consolidado disponível.'),
              ),
            )
          else
            ...weeks.map(
              (week) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: AppRadius.medium,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 650;
                    final details = [
                      _HistoryValue(label: 'Humor médio', value: week.$2),
                      _HistoryValue(label: 'Refeições', value: week.$3),
                      _HistoryValue(label: 'Medicação', value: week.$4),
                      _HistoryValue(label: 'Alertas', value: week.$5),
                    ];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          week.$1,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: colors.onSurface),
                        ),
                        const SizedBox(height: 14),
                        if (compact)
                          Wrap(
                            spacing: 24,
                            runSpacing: 16,
                            children: details
                                .map(
                                  (value) => SizedBox(width: 135, child: value),
                                )
                                .toList(),
                          )
                        else
                          Row(
                            children: [
                              for (final value in details)
                                Expanded(child: value),
                            ],
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HistoryValue extends StatelessWidget {
  const _HistoryValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 3),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _NotesTab extends StatelessWidget {
  const _NotesTab({
    super.key,
    required this.controller,
    required this.notes,
    required this.onAdd,
    required this.onDelete,
    required this.saving,
    required this.authorName,
    required this.canEdit,
  });

  final TextEditingController controller;
  final List<ProfessionalClinicalNote> notes;
  final Future<void> Function() onAdd;
  final Future<void> Function(String) onDelete;
  final bool saving;
  final String authorName;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ProfessionalPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ProfessionalSectionTitle(title: 'Nova anotação'),
              const SizedBox(height: 18),
              TextField(
                controller: controller,
                minLines: 4,
                maxLines: 7,
                decoration: const InputDecoration(
                  hintText: 'Escreva uma observação...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: saving || !canEdit ? null : () => onAdd(),
                  icon: const Icon(Icons.add_comment_outlined),
                  label: Text(saving ? 'Salvando...' : 'Salvar anotação'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ProfessionalPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ProfessionalSectionTitle(title: 'Anotações anteriores'),
              const SizedBox(height: 14),
              if (notes.isEmpty) const Text('Nenhuma anotação.'),
              ...notes.asMap().entries.map(
                (entry) => Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              entry.value.text,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Remover anotação',
                            onPressed: canEdit
                                ? () => onDelete(entry.value.id)
                                : null,
                            icon: const Icon(Icons.delete_outline_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${entry.value.date} · $authorName',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
