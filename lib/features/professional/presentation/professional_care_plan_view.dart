import 'package:flutter/material.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/professional/presentation/professional_mock_data.dart';
import 'package:iris/features/professional/presentation/professional_shared_widgets.dart';

class ProfessionalCarePlanView extends StatefulWidget {
  const ProfessionalCarePlanView({
    super.key,
    required this.initialPatient,
    required this.onOpenPatient,
  });

  final ProfessionalPatient initialPatient;
  final ValueChanged<ProfessionalPatient> onOpenPatient;

  @override
  State<ProfessionalCarePlanView> createState() =>
      _ProfessionalCarePlanViewState();
}

class _ProfessionalCarePlanViewState extends State<ProfessionalCarePlanView> {
  late ProfessionalPatient _patient;
  final _orientationController = TextEditingController(
    text:
        'Manter rotina de refeições estruturada, registrar emoções antes e '
        'depois das principais refeições e utilizar a rede de apoio em '
        'momentos de ansiedade intensa.',
  );
  final _goals = <String, bool>{
    'Realizar ao menos 3 refeições principais': true,
    'Registrar o humor uma vez ao dia': true,
    'Tomar a medicação nos horários combinados': true,
    'Praticar a técnica de respiração em crises': false,
  };
  bool _shareWithPatient = true;
  bool _notifyMissedCheckIns = true;

  @override
  void initState() {
    super.initState();
    _patient = widget.initialPatient;
  }

  @override
  void didUpdateWidget(covariant ProfessionalCarePlanView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialPatient.id != widget.initialPatient.id) {
      _patient = widget.initialPatient;
    }
  }

  @override
  void dispose() {
    _orientationController.dispose();
    super.dispose();
  }

  void _showSavedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Plano salvo localmente para visualização.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          ProfessionalGradientHeader(
            title: 'Plano de cuidado',
            subtitle: 'Acompanhamento e orientações individualizadas',
            action: FilledButton.icon(
              onPressed: _showSavedMessage,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.white,
                foregroundColor: AppColors.deepPurple,
              ),
              icon: const Icon(Icons.check_rounded),
              label: const Text('Salvar alterações'),
            ),
          ),
          ProfessionalPage(
            paddingTop: 22,
            child: Column(
              children: [
                _PatientSelector(
                  patient: _patient,
                  onChanged: (patient) => setState(() => _patient = patient),
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
                          onChanged: (goal, value) =>
                              setState(() => _goals[goal] = value),
                        ),
                        const SizedBox(height: 20),
                        _OrientationsPanel(controller: _orientationController),
                      ],
                    );
                    final right = Column(
                      children: [
                        const _PlanMedicationPanel(),
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
                        const _CrisisPlanPanel(),
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
}

class _PatientSelector extends StatelessWidget {
  const _PatientSelector({
    required this.patient,
    required this.onChanged,
    required this.onOpenPatient,
  });

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
                        items: ProfessionalMockData.patients
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
                  label: const Text('Ver detalhes do paciente'),
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
                label: const Text('Ver detalhes do paciente'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GoalsPanel extends StatelessWidget {
  const _GoalsPanel({required this.goals, required this.onChanged});

  final Map<String, bool> goals;
  final void Function(String goal, bool value) onChanged;

  @override
  Widget build(BuildContext context) {
    final completed = goals.values.where((value) => value).length;
    return ProfessionalPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfessionalSectionTitle(
            title: 'Metas terapêuticas',
            subtitle: '$completed de ${goals.length} metas em andamento',
            trailing: IconButton.filledTonal(
              tooltip: 'Adicionar meta',
              onPressed: () {},
              icon: const Icon(Icons.add_rounded),
            ),
          ),
          const SizedBox(height: 14),
          ...goals.entries.map(
            (entry) => CheckboxListTile(
              value: entry.value,
              onChanged: (value) => onChanged(entry.key, value ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppColors.deepPurple,
              title: Text(
                entry.key,
                style: TextStyle(
                  color: entry.value ? AppColors.text : AppColors.muted,
                  fontWeight: FontWeight.w600,
                  decoration: entry.value ? null : TextDecoration.none,
                ),
              ),
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
          const ProfessionalSectionTitle(
            title: 'Orientações do plano',
            subtitle: 'Texto compartilhado com o paciente',
          ),
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
  const _PlanMedicationPanel();

  @override
  Widget build(BuildContext context) {
    return ProfessionalPanel(
      child: Column(
        children: [
          ProfessionalSectionTitle(
            title: 'Medicações',
            subtitle: 'Prescrições do plano atual',
            trailing: IconButton(
              tooltip: 'Editar',
              onPressed: () {},
              icon: const Icon(Icons.edit_outlined),
            ),
          ),
          const SizedBox(height: 12),
          ...ProfessionalMockData.medications.map(
            (medication) => ListTile(
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
              title: Text('${medication.name} · ${medication.dose}'),
              subtitle: Text(medication.frequency),
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
          const ProfessionalSectionTitle(
            title: 'Acompanhamento',
            subtitle: 'Como o plano será monitorado',
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: shareWithPatient,
            onChanged: onShareChanged,
            title: const Text('Compartilhar com o paciente'),
            subtitle: const Text('Exibe metas e orientações no aplicativo'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: notifyMissedCheckIns,
            onChanged: onNotifyChanged,
            title: const Text('Alertar check-ins ausentes'),
            subtitle: const Text('Notificar após 48 horas sem registro'),
          ),
        ],
      ),
    );
  }
}

class _CrisisPlanPanel extends StatelessWidget {
  const _CrisisPlanPanel();

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
          Text(
            '1. Acionar contato de confiança\n'
            '2. Utilizar técnica de respiração guiada\n'
            '3. Em risco imediato, buscar atendimento de urgência',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.edit_note_rounded),
            label: const Text('Editar plano de crise'),
          ),
        ],
      ),
    );
  }
}
