import 'package:flutter/material.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/professional/presentation/professional_mock_data.dart';
import 'package:iris/features/professional/presentation/professional_shared_widgets.dart';

class ProfessionalNotesView extends StatefulWidget {
  const ProfessionalNotesView({super.key, required this.onOpenPatient});

  final ValueChanged<ProfessionalPatient> onOpenPatient;

  @override
  State<ProfessionalNotesView> createState() => _ProfessionalNotesViewState();
}

class _ProfessionalNotesViewState extends State<ProfessionalNotesView> {
  final _searchController = TextEditingController();

  List<_ClinicalNote> get _notes {
    final all = [
      _ClinicalNote(
        patient: ProfessionalMockData.patients[0],
        text:
            'Paciente relata melhora na rotina do café da manhã. Manter '
            'reforço positivo e revisar o sono.',
        date: 'Hoje, 11:40',
        tag: 'Evolução',
      ),
      _ClinicalNote(
        patient: ProfessionalMockData.patients[2],
        text:
            'Reavaliar episódios de compulsão no período noturno e atualizar '
            'a estratégia de prevenção de recaída.',
        date: 'Ontem, 17:10',
        tag: 'Atenção',
      ),
      _ClinicalNote(
        patient: ProfessionalMockData.patients[1],
        text:
            'Boa adesão ao plano de cuidado. Paciente conseguiu realizar '
            'refeições em companhia durante o fim de semana.',
        date: '25 jul, 15:30',
        tag: 'Evolução',
      ),
    ];
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return all;
    return all
        .where(
          (note) =>
              note.patient.name.toLowerCase().contains(query) ||
              note.text.toLowerCase().contains(query) ||
              note.tag.toLowerCase().contains(query),
        )
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: ProfessionalPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProfessionalPageHeader(
              title: 'Anotações clínicas',
              subtitle:
                  'Registre e encontre observações importantes do acompanhamento.',
              action: FilledButton.icon(
                onPressed: () => _showNewNoteDialog(context),
                icon: const Icon(Icons.note_add_outlined),
                label: const Text('Nova anotação'),
              ),
            ),
            const SizedBox(height: 28),
            ProfessionalPanel(
              padding: const EdgeInsets.all(14),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Buscar por paciente, conteúdo ou marcador...',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
            const SizedBox(height: 22),
            ..._notes.map(
              (note) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _ClinicalNoteCard(
                  note: note,
                  onOpenPatient: () => widget.onOpenPatient(note.patient),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showNewNoteDialog(BuildContext context) async {
    final controller = TextEditingController();
    var selectedPatient = ProfessionalMockData.patients.first;
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nova anotação clínica'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<ProfessionalPatient>(
                  initialValue: selectedPatient,
                  decoration: const InputDecoration(labelText: 'Paciente'),
                  items: ProfessionalMockData.patients
                      .map(
                        (patient) => DropdownMenuItem(
                          value: patient,
                          child: Text(patient.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedPatient = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  minLines: 4,
                  maxLines: 7,
                  decoration: const InputDecoration(
                    labelText: 'Anotação',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Anotação salva localmente para visualização.',
                    ),
                  ),
                );
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
  }
}

class _ClinicalNoteCard extends StatelessWidget {
  const _ClinicalNoteCard({required this.note, required this.onOpenPatient});

  final _ClinicalNote note;
  final VoidCallback onOpenPatient;

  @override
  Widget build(BuildContext context) {
    return ProfessionalPanel(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PatientAvatar(patient: note.patient, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.patient.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.deepPurple,
                      ),
                    ),
                    Text(
                      note.date,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.lavender.withValues(alpha: .32),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  note.tag,
                  style: const TextStyle(
                    color: AppColors.deepPurple,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(note.text, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onOpenPatient,
              icon: const Icon(Icons.open_in_new_rounded, size: 17),
              label: const Text('Abrir paciente'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClinicalNote {
  const _ClinicalNote({
    required this.patient,
    required this.text,
    required this.date,
    required this.tag,
  });

  final ProfessionalPatient patient;
  final String text;
  final String date;
  final String tag;
}
