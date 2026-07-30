import 'package:flutter/material.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/professional/presentation/professional_form_dialogs.dart';
import 'package:iris/features/professional/presentation/professional_frontend_store.dart';
import 'package:iris/features/professional/presentation/professional_mock_data.dart';
import 'package:iris/features/professional/presentation/professional_shared_widgets.dart';

class ProfessionalNotesView extends StatefulWidget {
  const ProfessionalNotesView({
    super.key,
    required this.store,
    required this.onOpenPatient,
  });

  final ProfessionalFrontendStore store;
  final ValueChanged<ProfessionalPatient> onOpenPatient;

  @override
  State<ProfessionalNotesView> createState() => _ProfessionalNotesViewState();
}

class _ProfessionalNotesViewState extends State<ProfessionalNotesView> {
  final _searchController = TextEditingController();

  List<ProfessionalClinicalNote> get _notes {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return widget.store.notes;
    return widget.store.notes.where((note) {
      final patient = widget.store.patientById(note.patientId);
      return patient.name.toLowerCase().contains(query) ||
          note.text.toLowerCase().contains(query) ||
          note.tag.toLowerCase().contains(query);
    }).toList();
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
              subtitle: '${widget.store.notes.length} registros',
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
                  hintText: 'Buscar anotações...',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
            const SizedBox(height: 22),
            ..._notes.map((note) {
              final patient = widget.store.patientById(note.patientId);
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _ClinicalNoteCard(
                  note: note,
                  patient: patient,
                  onOpenPatient: () => widget.onOpenPatient(patient),
                  onEdit: () => _showNoteDialog(context, note: note),
                  onDelete: () async {
                    final confirmed = await showProfessionalDeleteConfirmation(
                      context,
                      item: 'Anotação de ${patient.name}',
                    );
                    if (confirmed) widget.store.removeNote(note.id);
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _showNewNoteDialog(BuildContext context) async {
    await _showNoteDialog(context);
  }

  Future<void> _showNoteDialog(
    BuildContext context, {
    ProfessionalClinicalNote? note,
  }) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController(text: note?.text);
    var selectedPatient = note == null
        ? widget.store.patients.first
        : widget.store.patientById(note.patientId);
    var tag = note?.tag ?? 'Evolução';
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(note == null ? 'Nova anotação' : 'Editar anotação'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<ProfessionalPatient>(
                    initialValue: selectedPatient,
                    decoration: const InputDecoration(labelText: 'Paciente'),
                    items: widget.store.patients
                        .map(
                          (patient) => DropdownMenuItem(
                            value: patient,
                            child: Text(patient.name),
                          ),
                        )
                        .toList(),
                    onChanged: note == null
                        ? (value) {
                            if (value != null) {
                              setDialogState(() => selectedPatient = value);
                            }
                          }
                        : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: tag,
                    decoration: const InputDecoration(labelText: 'Marcador'),
                    items: const [
                      DropdownMenuItem(
                        value: 'Evolução',
                        child: Text('Evolução'),
                      ),
                      DropdownMenuItem(
                        value: 'Atenção',
                        child: Text('Atenção'),
                      ),
                      DropdownMenuItem(
                        value: 'Consulta',
                        child: Text('Consulta'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) setDialogState(() => tag = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('professional-note-text'),
                    controller: controller,
                    minLines: 4,
                    maxLines: 7,
                    decoration: const InputDecoration(
                      labelText: 'Anotação',
                      alignLabelWithHint: true,
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Digite uma anotação'
                        : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                final text = controller.text.trim();
                if (note == null) {
                  widget.store.addNote(
                    ProfessionalClinicalNote(
                      id: 'note-${DateTime.now().microsecondsSinceEpoch}',
                      patientId: selectedPatient.id,
                      text: text,
                      date: 'Agora',
                      tag: tag,
                    ),
                  );
                } else {
                  widget.store.updateNote(note.copyWith(text: text, tag: tag));
                }
                Navigator.pop(context);
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 250));
    controller.dispose();
  }
}

class _ClinicalNoteCard extends StatelessWidget {
  const _ClinicalNoteCard({
    required this.note,
    required this.patient,
    required this.onOpenPatient,
    required this.onEdit,
    required this.onDelete,
  });

  final ProfessionalClinicalNote note;
  final ProfessionalPatient patient;
  final VoidCallback onOpenPatient;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ProfessionalPanel(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PatientAvatar(patient: patient, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.name,
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                  PopupMenuButton<String>(
                    tooltip: 'Ações',
                    onSelected: (value) =>
                        value == 'edit' ? onEdit() : onDelete(),
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Editar')),
                      PopupMenuItem(value: 'delete', child: Text('Remover')),
                    ],
                  ),
                ],
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
