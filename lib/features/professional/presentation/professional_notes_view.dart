import 'package:flutter/material.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/professional/presentation/professional_form_dialogs.dart';
import 'package:iris/features/professional/presentation/professional_frontend_store.dart';
import 'package:iris/features/professional/presentation/professional_models.dart';
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

  List<ProfessionalPatient> get _eligiblePatients {
    if (!widget.store.isConnected) return widget.store.patients;
    return widget.store.patients
        .where((patient) => patient.status == PatientStatus.active)
        .toList();
  }

  List<ProfessionalClinicalNote> get _notes {
    final query = _searchController.text.trim().toLowerCase();
    return widget.store.notes.where((note) {
      final patient = widget.store.patientByIdOrNull(note.patientId);
      if (patient == null) return false;
      if (widget.store.isConnected && patient.status != PatientStatus.active) {
        return false;
      }
      if (query.isEmpty) return true;
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
                onPressed: _eligiblePatients.isEmpty
                    ? null
                    : () => _showNewNoteDialog(context),
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
            if (_notes.isEmpty)
              ProfessionalPanel(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 34),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.note_alt_outlined,
                          size: 44,
                          color: AppColors.purple,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.store.patients.isEmpty
                              ? 'Vincule um paciente para criar anotações.'
                              : _eligiblePatients.isEmpty
                              ? 'Ative o acompanhamento para criar anotações.'
                              : 'Nenhuma anotação encontrada.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ..._notes.map((note) {
                final patient = widget.store.patientByIdOrNull(note.patientId)!;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _ClinicalNoteCard(
                    note: note,
                    patient: patient,
                    canEdit:
                        !widget.store.isConnected ||
                        patient.status == PatientStatus.active,
                    onOpenPatient: () => widget.onOpenPatient(patient),
                    onEdit: () => _showNoteDialog(context, note: note),
                    onDelete: () async {
                      final confirmed =
                          await showProfessionalDeleteConfirmation(
                            context,
                            item: 'Anotação de ${patient.name}',
                          );
                      if (!confirmed) return;
                      try {
                        await widget.store.removeNote(note.id);
                      } catch (error) {
                        if (context.mounted) {
                          showProfessionalOperationError(context, error);
                        }
                      }
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
    final eligiblePatients = _eligiblePatients;
    final notePatient = note == null
        ? null
        : widget.store.patientByIdOrNull(note.patientId);
    if (eligiblePatients.isEmpty ||
        (notePatient != null &&
            widget.store.isConnected &&
            notePatient.status != PatientStatus.active)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.store.patients.isEmpty
                ? 'Vincule um paciente antes de continuar.'
                : 'Ative o acompanhamento para alterar anotações.',
          ),
        ),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController(text: note?.text);
    var selectedPatient = note == null
        ? eligiblePatients[0]
        : widget.store.patientById(note.patientId);
    var tag = note?.tag ?? 'Evolução';
    var saving = false;
    await showDialog<void>(
      context: context,
      useRootNavigator: false,
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
                    items: eligiblePatients
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
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      final text = controller.text.trim();
                      setDialogState(() => saving = true);
                      try {
                        if (note == null) {
                          await widget.store.addNote(
                            ProfessionalClinicalNote(
                              id: 'note-${DateTime.now().microsecondsSinceEpoch}',
                              patientId: selectedPatient.id,
                              text: text,
                              date: 'Agora',
                              tag: tag,
                            ),
                          );
                        } else {
                          await widget.store.updateNote(
                            note.copyWith(text: text, tag: tag),
                          );
                        }
                        if (context.mounted) Navigator.pop(context);
                      } catch (error) {
                        if (!context.mounted) return;
                        setDialogState(() => saving = false);
                        showProfessionalOperationError(context, error);
                      }
                    },
              child: Text(saving ? 'Salvando...' : 'Salvar'),
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
    required this.canEdit,
    required this.onEdit,
    required this.onDelete,
  });

  final ProfessionalClinicalNote note;
  final ProfessionalPatient patient;
  final VoidCallback onOpenPatient;
  final bool canEdit;
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
                    enabled: canEdit,
                    tooltip: canEdit
                        ? 'Ações'
                        : 'Ative o acompanhamento para alterar',
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
