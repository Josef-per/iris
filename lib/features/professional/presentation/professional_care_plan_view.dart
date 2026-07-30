import 'package:flutter/material.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/professional/presentation/professional_form_dialogs.dart';
import 'package:iris/features/professional/presentation/professional_frontend_store.dart';
import 'package:iris/features/professional/presentation/professional_mock_data.dart';
import 'package:iris/features/professional/presentation/professional_shared_widgets.dart';

class ProfessionalCarePlanView extends StatefulWidget {
  const ProfessionalCarePlanView({
    super.key,
    required this.store,
    required this.initialPatient,
    required this.onOpenPatient,
  });

  final ProfessionalFrontendStore store;
  final ProfessionalPatient initialPatient;
  final ValueChanged<ProfessionalPatient> onOpenPatient;

  @override
  State<ProfessionalCarePlanView> createState() =>
      _ProfessionalCarePlanViewState();
}

class _ProfessionalCarePlanViewState extends State<ProfessionalCarePlanView> {
  late ProfessionalPatient _patient;
  final _orientationController = TextEditingController();
  var _goals = <ProfessionalGoal>[];
  var _medications = <ProfessionalMedication>[];
  var _crisisSteps = <String>[];
  bool _shareWithPatient = true;
  bool _notifyMissedCheckIns = true;

  @override
  void initState() {
    super.initState();
    _patient = widget.store.patientById(widget.initialPatient.id);
    _loadPlan();
  }

  @override
  void didUpdateWidget(covariant ProfessionalCarePlanView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialPatient.id != widget.initialPatient.id) {
      _patient = widget.store.patientById(widget.initialPatient.id);
      _loadPlan();
    }
  }

  @override
  void dispose() {
    _orientationController.dispose();
    super.dispose();
  }

  void _loadPlan() {
    final plan = widget.store.carePlanFor(_patient.id);
    _goals = [...plan.goals];
    _medications = [...plan.medications];
    _crisisSteps = [...plan.crisisSteps];
    _shareWithPatient = plan.shareWithPatient;
    _notifyMissedCheckIns = plan.notifyMissedCheckIns;
    _orientationController.text = plan.orientation;
  }

  void _save({bool showMessage = true}) {
    widget.store.updateCarePlan(
      _patient.id,
      ProfessionalCarePlanDraft(
        goals: [..._goals],
        orientation: _orientationController.text.trim(),
        medications: [..._medications],
        crisisSteps: [..._crisisSteps],
        shareWithPatient: _shareWithPatient,
        notifyMissedCheckIns: _notifyMissedCheckIns,
      ),
    );
    if (!showMessage) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Plano salvo.')));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          ProfessionalGradientHeader(
            title: 'Plano de cuidado',
            subtitle: _patient.name,
            action: FilledButton.icon(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.white,
                foregroundColor: AppColors.deepPurple,
              ),
              icon: const Icon(Icons.check_rounded),
              label: const Text('Salvar'),
            ),
          ),
          ProfessionalPage(
            paddingTop: 22,
            child: Column(
              children: [
                _PatientSelector(
                  patients: widget.store.patients,
                  patient: _patient,
                  onChanged: (patient) {
                    _save(showMessage: false);
                    setState(() {
                      _patient = patient;
                      _loadPlan();
                    });
                  },
                  onOpenPatient: () => widget.onOpenPatient(_patient),
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
                            setState(
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
                            setState(
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
                            setState(
                              () => _goals[index] = goal.copyWith(text: text),
                            );
                          },
                          onDelete: (goal) =>
                              setState(() => _goals.remove(goal)),
                        ),
                        const SizedBox(height: 20),
                        _OrientationsPanel(controller: _orientationController),
                      ],
                    );
                    final right = Column(
                      children: [
                        _PlanMedicationPanel(
                          medications: _medications,
                          onAdd: () => _editMedication(),
                          onEdit: (index) => _editMedication(index: index),
                          onDelete: (index) =>
                              setState(() => _medications.removeAt(index)),
                        ),
                        const SizedBox(height: 20),
                        _FollowUpPanel(
                          shareWithPatient: _shareWithPatient,
                          notifyMissedCheckIns: _notifyMissedCheckIns,
                          onShareChanged: (value) =>
                              setState(() => _shareWithPatient = value),
                          onNotifyChanged: (value) =>
                              setState(() => _notifyMissedCheckIns = value),
                        ),
                        const SizedBox(height: 20),
                        _CrisisPlanPanel(
                          steps: _crisisSteps,
                          onAdd: () => _editCrisisStep(),
                          onEdit: (index) => _editCrisisStep(index: index),
                          onDelete: (index) =>
                              setState(() => _crisisSteps.removeAt(index)),
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
    setState(() {
      if (index == null) {
        _medications.add(result);
      } else {
        _medications[index] = result;
      }
    });
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
    setState(() {
      if (index == null) {
        _crisisSteps.add(result);
      } else {
        _crisisSteps[index] = result;
      }
    });
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
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Nenhuma meta.'),
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
                      activeColor: AppColors.deepPurple,
                      title: Text(
                        goal.text,
                        style: TextStyle(
                          color: goal.completed
                              ? AppColors.text
                              : AppColors.muted,
                          fontWeight: FontWeight.w600,
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
  const _OrientationsPanel({required this.controller});

  final TextEditingController controller;

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
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Nenhuma medicação.'),
            )
          else
            ...medications.asMap().entries.map(
              (entry) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.lavender.withValues(alpha: .35),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.medication_outlined,
                    color: AppColors.deepPurple,
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
    return ProfessionalPanel(
      borderColor: AppColors.danger.withValues(alpha: .35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.health_and_safety_outlined,
                  color: AppColors.danger,
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
            const Text('Nenhuma orientação.')
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
