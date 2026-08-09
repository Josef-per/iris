import 'package:flutter/material.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/professional/presentation/professional_form_dialogs.dart';
import 'package:iris/features/professional/presentation/professional_frontend_store.dart';
import 'package:iris/features/professional/presentation/professional_models.dart';
import 'package:iris/features/professional/presentation/professional_shared_widgets.dart';

class ProfessionalCarePlanView extends StatefulWidget {
  const ProfessionalCarePlanView({
    super.key,
    required this.store,
    required this.initialPatient,
    required this.onOpenPatient,
    this.onPatientChanged,
    this.onDirtyChanged,
  });

  final ProfessionalFrontendStore store;
  final ProfessionalPatient? initialPatient;
  final ValueChanged<ProfessionalPatient> onOpenPatient;
  final ValueChanged<ProfessionalPatient>? onPatientChanged;
  final ValueChanged<bool>? onDirtyChanged;

  @override
  State<ProfessionalCarePlanView> createState() =>
      _ProfessionalCarePlanViewState();
}

class _ProfessionalCarePlanViewState extends State<ProfessionalCarePlanView> {
  ProfessionalPatient? _patient;
  final _orientationController = TextEditingController();
  var _goals = <ProfessionalGoal>[];
  var _medications = <ProfessionalMedication>[];
  var _crisisSteps = <String>[];
  bool _shareWithPatient = true;
  bool _notifyMissedCheckIns = true;
  bool _saving = false;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _resolvePatient();
  }

  @override
  void didUpdateWidget(covariant ProfessionalCarePlanView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialPatient?.id != widget.initialPatient?.id) {
      _resolvePatient();
    }
  }

  @override
  void dispose() {
    _orientationController.dispose();
    super.dispose();
  }

  void _resolvePatient() {
    final initialId = widget.initialPatient?.id;
    _patient = initialId == null
        ? (widget.store.patients.isEmpty ? null : widget.store.patients[0])
        : widget.store.patientByIdOrNull(initialId);
    if (_patient != null) _loadPlan();
  }

  void _loadPlan() {
    final patient = _patient;
    if (patient == null) return;
    final plan = widget.store.carePlanFor(patient.id);
    _goals = [...plan.goals];
    _medications = [...plan.medications];
    _crisisSteps = [...plan.crisisSteps];
    _shareWithPatient = plan.shareWithPatient;
    _notifyMissedCheckIns = plan.notifyMissedCheckIns;
    _orientationController.text = plan.orientation;
    _dirty = false;
  }

  Future<bool> _save({bool showMessage = true}) async {
    final patient = _patient;
    if (patient == null || _saving) return false;
    if (!_dirty) return true;
    setState(() => _saving = true);
    try {
      await widget.store.updateCarePlan(
        patient.id,
        ProfessionalCarePlanDraft(
          goals: [..._goals],
          orientation: _orientationController.text.trim(),
          medications: [..._medications],
          crisisSteps: [..._crisisSteps],
          shareWithPatient: _shareWithPatient,
          notifyMissedCheckIns: _notifyMissedCheckIns,
        ),
      );
      if (!mounted) return true;
      setState(() => _dirty = false);
      widget.onDirtyChanged?.call(false);
      if (showMessage) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                widget.store.isConnected
                    ? 'Plano salvo.'
                    : 'Plano salvo nesta sessão.',
              ),
            ),
          );
      }
      return true;
    } catch (error) {
      if (mounted) showProfessionalOperationError(context, error);
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _change(VoidCallback change) {
    final wasDirty = _dirty;
    setState(() {
      change();
      _dirty = true;
    });
    if (!wasDirty) widget.onDirtyChanged?.call(true);
  }

  @override
  Widget build(BuildContext context) {
    final patient = _patient;
    if (patient == null) {
      return SingleChildScrollView(
        child: Column(
          children: [
            ProfessionalGradientHeader(
              title: 'Plano de cuidado',
              subtitle: 'Nenhum paciente selecionado',
              action: FilledButton.icon(
                onPressed: null,
                style: AppButtonStyles.onBrandFilled,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Salvar'),
              ),
            ),
            const ProfessionalPage(
              paddingTop: 22,
              child: ProfessionalEmptyState(
                icon: Icons.health_and_safety_outlined,
                title: 'Nenhum paciente vinculado',
                message:
                    'Vincule um paciente para criar e compartilhar um plano de cuidado.',
              ),
            ),
          ],
        ),
      );
    }
    if (widget.store.isConnected && patient.status != PatientStatus.active) {
      return SingleChildScrollView(
        child: Column(
          children: [
            ProfessionalGradientHeader(
              title: 'Plano de cuidado',
              subtitle: patient.name,
              action: FilledButton.icon(
                onPressed: null,
                style: AppButtonStyles.onBrandFilled,
                icon: const Icon(Icons.lock_outline_rounded),
                label: const Text('Acompanhamento inativo'),
              ),
            ),
            ProfessionalPage(
              paddingTop: 22,
              child: ProfessionalEmptyState(
                icon: Icons.pause_circle_outline_rounded,
                title: 'Acompanhamento inativo',
                message:
                    'Ative o acompanhamento para editar o plano de cuidado.',
                action: OutlinedButton.icon(
                  onPressed: () => widget.onOpenPatient(patient),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Abrir paciente'),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          ProfessionalGradientHeader(
            title: 'Plano de cuidado',
            subtitle: patient.name,
            action: FilledButton.icon(
              onPressed: _saving || !_dirty ? null : () => _save(),
              style: AppButtonStyles.onBrandFilled,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(
                _saving
                    ? 'Salvando...'
                    : _dirty
                    ? 'Salvar alterações'
                    : 'Salvo',
              ),
            ),
          ),
          AbsorbPointer(
            absorbing: _saving,
            child: ProfessionalPage(
              paddingTop: 22,
              child: Column(
                children: [
                  _PatientSelector(
                    patients: widget.store.patients,
                    patient: patient,
                    onChanged: _selectPatient,
                    onOpenPatient: () => widget.onOpenPatient(patient),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: _dirty
                        ? Padding(
                            key: const ValueKey('care-plan-dirty'),
                            padding: const EdgeInsets.only(top: 12),
                            child: Semantics(
                              liveRegion: true,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Alterações não salvas',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 22),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 940;
                      final left = Column(
                        children: [
                          _GoalsPanel(
                            goals: _goals,
                            onChanged: (goal, value) {
                              final index = _goals.indexWhere(
                                (item) => item.id == goal.id,
                              );
                              _change(
                                () => _goals[index] = goal.copyWith(
                                  completed: value,
                                ),
                              );
                            },
                            onAdd: () async {
                              final text = await showProfessionalTextItemForm(
                                context,
                                title: 'Nova meta',
                                label: 'Meta',
                              );
                              if (text == null) return;
                              _change(
                                () => _goals.add(
                                  ProfessionalGoal(
                                    id: 'goal-${DateTime.now().microsecondsSinceEpoch}',
                                    text: text,
                                  ),
                                ),
                              );
                            },
                            onEdit: (goal) async {
                              final text = await showProfessionalTextItemForm(
                                context,
                                title: 'Editar meta',
                                label: 'Meta',
                                initialValue: goal.text,
                              );
                              if (text == null) return;
                              final index = _goals.indexWhere(
                                (item) => item.id == goal.id,
                              );
                              _change(
                                () => _goals[index] = goal.copyWith(text: text),
                              );
                            },
                            onDelete: _deleteGoal,
                          ),
                          const SizedBox(height: 20),
                          _OrientationsPanel(
                            controller: _orientationController,
                            onChanged: (_) => _change(() {}),
                          ),
                        ],
                      );
                      final right = Column(
                        children: [
                          _PlanMedicationPanel(
                            medications: _medications,
                            onAdd: () => _editMedication(),
                            onEdit: (index) => _editMedication(index: index),
                            onDelete: _deleteMedication,
                          ),
                          const SizedBox(height: 20),
                          _FollowUpPanel(
                            shareWithPatient: _shareWithPatient,
                            notifyMissedCheckIns: _notifyMissedCheckIns,
                            onShareChanged: (value) =>
                                _change(() => _shareWithPatient = value),
                            onNotifyChanged: (value) =>
                                _change(() => _notifyMissedCheckIns = value),
                          ),
                          const SizedBox(height: 20),
                          _CrisisPlanPanel(
                            steps: _crisisSteps,
                            onAdd: () => _editCrisisStep(),
                            onEdit: (index) => _editCrisisStep(index: index),
                            onDelete: _deleteCrisisStep,
                          ),
                        ],
                      );
                      if (!wide) {
                        return Column(
                          children: [left, const SizedBox(height: 20), right],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 11, child: left),
                          const SizedBox(width: 20),
                          Expanded(flex: 9, child: right),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editMedication({int? index}) async {
    final result = await showProfessionalMedicationForm(
      context,
      medication: index == null ? null : _medications[index],
    );
    if (result == null) return;
    _change(() {
      if (index == null) {
        _medications.add(result);
      } else {
        _medications[index] = result;
      }
    });
  }

  Future<void> _selectPatient(ProfessionalPatient nextPatient) async {
    if (nextPatient.id == _patient?.id) return;
    final onPatientChanged = widget.onPatientChanged;
    if (onPatientChanged != null) {
      onPatientChanged(nextPatient);
      return;
    }

    if (_dirty) {
      final discard =
          await showDialog<bool>(
            context: context,
            useRootNavigator: false,
            barrierDismissible: false,
            builder: (dialogContext) => ProfessionalResponsiveDialog(
              title: 'Descartar alterações?',
              maxWidth: 440,
              content: const Text(
                'O plano atual tem alterações não salvas. Elas serão perdidas ao trocar de paciente.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Continuar editando'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(dialogContext).colorScheme.error,
                    foregroundColor: Theme.of(
                      dialogContext,
                    ).colorScheme.onError,
                  ),
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Descartar'),
                ),
              ],
            ),
          ) ??
          false;
      if (!discard || !mounted) return;
    }

    setState(() {
      _patient = nextPatient;
      _loadPlan();
    });
    widget.onDirtyChanged?.call(false);
  }

  Future<void> _editCrisisStep({int? index}) async {
    final result = await showProfessionalTextItemForm(
      context,
      title: index == null ? 'Nova orientação' : 'Editar orientação',
      label: 'Orientação',
      initialValue: index == null ? null : _crisisSteps[index],
      maxLines: 3,
    );
    if (result == null) return;
    _change(() {
      if (index == null) {
        _crisisSteps.add(result);
      } else {
        _crisisSteps[index] = result;
      }
    });
  }

  Future<void> _deleteGoal(ProfessionalGoal goal) async {
    final confirmed = await showProfessionalDeleteConfirmation(
      context,
      item: 'Meta: ${goal.text}',
    );
    if (!confirmed || !mounted) return;
    _change(() => _goals.remove(goal));
  }

  Future<void> _deleteMedication(int index) async {
    final medication = _medications[index];
    final confirmed = await showProfessionalDeleteConfirmation(
      context,
      item: 'Medicação: ${medication.name}',
    );
    if (!confirmed || !mounted) return;
    _change(() => _medications.removeAt(index));
  }

  Future<void> _deleteCrisisStep(int index) async {
    final confirmed = await showProfessionalDeleteConfirmation(
      context,
      item: _crisisSteps[index],
    );
    if (!confirmed || !mounted) return;
    _change(() => _crisisSteps.removeAt(index));
  }
}

class _PatientSelector extends StatelessWidget {
  const _PatientSelector({
    required this.patients,
    required this.patient,
    required this.onChanged,
    required this.onOpenPatient,
  });

  final List<ProfessionalPatient> patients;
  final ProfessionalPatient patient;
  final ValueChanged<ProfessionalPatient> onChanged;
  final VoidCallback onOpenPatient;

  @override
  Widget build(BuildContext context) {
    return ProfessionalPanel(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final info = Row(
            children: [
              PatientAvatar(patient: patient, size: 58),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonHideUnderline(
                      child: DropdownButton<ProfessionalPatient>(
                        value: patient,
                        isExpanded: true,
                        borderRadius: BorderRadius.circular(16),
                        items: patients
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(
                                  item.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) onChanged(value);
                        },
                      ),
                    ),
                    Text(
                      patient.diagnosis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                info,
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: onOpenPatient,
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Abrir paciente'),
                ),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: info),
              const SizedBox(width: 24),
              OutlinedButton.icon(
                onPressed: onOpenPatient,
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Abrir paciente'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GoalsPanel extends StatelessWidget {
  const _GoalsPanel({
    required this.goals,
    required this.onChanged,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final List<ProfessionalGoal> goals;
  final void Function(ProfessionalGoal goal, bool value) onChanged;
  final VoidCallback onAdd;
  final ValueChanged<ProfessionalGoal> onEdit;
  final ValueChanged<ProfessionalGoal> onDelete;

  @override
  Widget build(BuildContext context) {
    final completed = goals.where((goal) => goal.completed).length;
    final colors = Theme.of(context).colorScheme;
    return ProfessionalPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfessionalSectionTitle(
            title: 'Metas',
            subtitle: '$completed de ${goals.length} concluídas',
            trailing: IconButton.filledTonal(
              tooltip: 'Adicionar meta',
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
            ),
          ),
          const SizedBox(height: 14),
          if (goals.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Adicionar a primeira meta'),
                ),
              ),
            )
          else
            ...goals.map(
              (goal) => Row(
                children: [
                  Expanded(
                    child: CheckboxListTile(
                      value: goal.completed,
                      onChanged: (value) => onChanged(goal, value ?? false),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: colors.primary,
                      title: Text(
                        goal.text,
                        style: TextStyle(
                          color: goal.completed
                              ? colors.onSurfaceVariant
                              : colors.onSurface,
                          fontWeight: FontWeight.w600,
                          decoration: goal.completed
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Ações da meta',
                    onSelected: (value) =>
                        value == 'edit' ? onEdit(goal) : onDelete(goal),
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Editar')),
                      PopupMenuItem(value: 'delete', child: Text('Remover')),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _OrientationsPanel extends StatelessWidget {
  const _OrientationsPanel({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return ProfessionalPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ProfessionalSectionTitle(title: 'Orientações'),
          const SizedBox(height: 18),
          TextField(
            controller: controller,
            onChanged: onChanged,
            minLines: 6,
            maxLines: 10,
            decoration: const InputDecoration(
              hintText: 'Adicione orientações individualizadas...',
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanMedicationPanel extends StatelessWidget {
  const _PlanMedicationPanel({
    required this.medications,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final List<ProfessionalMedication> medications;
  final VoidCallback onAdd;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ProfessionalPanel(
      child: Column(
        children: [
          ProfessionalSectionTitle(
            title: 'Medicações',
            subtitle: '${medications.length} itens',
            trailing: IconButton.filledTonal(
              tooltip: 'Adicionar medicação',
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
            ),
          ),
          const SizedBox(height: 12),
          if (medications.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Adicionar a primeira medicação'),
                ),
              ),
            )
          else
            ...medications.asMap().entries.map(
              (entry) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: AppRadius.small,
                  ),
                  child: Icon(
                    Icons.medication_outlined,
                    color: colors.onPrimaryContainer,
                  ),
                ),
                title: Text('${entry.value.name} · ${entry.value.dose}'),
                subtitle: Text(entry.value.frequency),
                trailing: PopupMenuButton<String>(
                  tooltip: 'Ações da medicação',
                  onSelected: (value) =>
                      value == 'edit' ? onEdit(entry.key) : onDelete(entry.key),
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Editar')),
                    PopupMenuItem(value: 'delete', child: Text('Remover')),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FollowUpPanel extends StatelessWidget {
  const _FollowUpPanel({
    required this.shareWithPatient,
    required this.notifyMissedCheckIns,
    required this.onShareChanged,
    required this.onNotifyChanged,
  });

  final bool shareWithPatient;
  final bool notifyMissedCheckIns;
  final ValueChanged<bool> onShareChanged;
  final ValueChanged<bool> onNotifyChanged;

  @override
  Widget build(BuildContext context) {
    return ProfessionalPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ProfessionalSectionTitle(title: 'Acompanhamento'),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: shareWithPatient,
            onChanged: onShareChanged,
            title: const Text('Compartilhar com o paciente'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: notifyMissedCheckIns,
            onChanged: onNotifyChanged,
            title: const Text('Alertar check-ins ausentes'),
          ),
        ],
      ),
    );
  }
}

class _CrisisPlanPanel extends StatelessWidget {
  const _CrisisPlanPanel({
    required this.steps,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final List<String> steps;
  final VoidCallback onAdd;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ProfessionalPanel(
      borderColor: colors.error.withValues(alpha: .55),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.errorContainer,
                  borderRadius: AppRadius.small,
                ),
                child: Icon(
                  Icons.health_and_safety_outlined,
                  color: colors.onErrorContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Plano para momentos de crise',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (steps.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Inclua orientações objetivas para momentos de crise.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else
            ...steps.asMap().entries.map(
              (entry) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 14,
                  child: Text('${entry.key + 1}'),
                ),
                title: Text(entry.value),
                trailing: PopupMenuButton<String>(
                  tooltip: 'Ações da orientação',
                  onSelected: (value) =>
                      value == 'edit' ? onEdit(entry.key) : onDelete(entry.key),
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Editar')),
                    PopupMenuItem(value: 'delete', child: Text('Remover')),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Adicionar orientação'),
          ),
        ],
      ),
    );
  }
}
