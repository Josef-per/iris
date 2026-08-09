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
  final _busyNoteIds = <String>{};

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
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Buscar por paciente, marcador ou conteúdo',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpar busca',
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
            const SizedBox(height: 22),
            if (_notes.isEmpty)
              ProfessionalEmptyState(
                icon: Icons.note_alt_outlined,
                title: _searchController.text.trim().isNotEmpty
                    ? 'Nenhuma anotação encontrada'
                    : widget.store.patients.isEmpty
                    ? 'Nenhum paciente vinculado'
                    : _eligiblePatients.isEmpty
                    ? 'Nenhum acompanhamento ativo'
                    : 'Ainda não há anotações',
                message: _searchController.text.trim().isNotEmpty
                    ? 'Revise o termo ou limpe a busca para ver todos os registros.'
                    : widget.store.patients.isEmpty
                    ? 'Vincule um paciente antes de criar uma anotação clínica.'
                    : _eligiblePatients.isEmpty
                    ? 'Ative o acompanhamento de um paciente para registrar sua evolução.'
                    : 'Crie a primeira anotação para manter o histórico clínico organizado.',
                action: _searchController.text.trim().isNotEmpty
                    ? FilledButton.icon(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.search_off_rounded),
                        label: const Text('Limpar busca'),
                      )
                    : _eligiblePatients.isNotEmpty
                    ? FilledButton.icon(
                        onPressed: () => _showNewNoteDialog(context),
                        icon: const Icon(Icons.note_add_outlined),
                        label: const Text('Criar primeira anotação'),
                      )
                    : null,
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 820;
                  return ProfessionalListSurface(
                    children: [
                      if (wide) const _ClinicalNotesHeader(),
                      ..._notes.map((note) {
                        final patient = widget.store.patientByIdOrNull(
                          note.patientId,
                        )!;
                        return _ClinicalNoteRow(
                          note: note,
                          patient: patient,
                          compact: !wide,
                          busy: _busyNoteIds.contains(note.id),
                          canEdit:
                              !widget.store.isConnected ||
                              patient.status == PatientStatus.active,
                          onOpenPatient: () => widget.onOpenPatient(patient),
                          onEdit: () => _showNoteDialog(context, note: note),
                          onDelete: () => _deleteNote(note, patient),
                        );
                      }),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showNewNoteDialog(BuildContext context) async {
    final saved = await _showNoteDialog(context);
    if (!saved || !context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Anotação adicionada.')));
  }

  Future<bool> _showNoteDialog(
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
      return false;
    }

    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController(text: note?.text);
    var selectedPatient = note == null
        ? eligiblePatients[0]
        : widget.store.patientById(note.patientId);
    var tag = note?.tag ?? 'Evolução';
    var saving = false;
    final saved =
        await showDialog<bool>(
          context: context,
          useRootNavigator: false,
          barrierDismissible: false,
          builder: (context) => StatefulBuilder(
            builder: (context, setDialogState) => ProfessionalResponsiveDialog(
              title: note == null ? 'Nova anotação' : 'Editar anotação',
              maxWidth: 520,
              canClose: !saving,
              content: Form(
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
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Digite uma anotação'
                          : null,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () => Navigator.pop(context, false),
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
                            if (context.mounted) Navigator.pop(context, true);
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
        ) ??
        false;
    await Future<void>.delayed(const Duration(milliseconds: 250));
    controller.dispose();
    if (saved && note != null && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Anotação atualizada.')));
    }
    return saved;
  }

  Future<void> _deleteNote(
    ProfessionalClinicalNote note,
    ProfessionalPatient patient,
  ) async {
    if (_busyNoteIds.contains(note.id)) return;
    final confirmed = await showProfessionalDeleteConfirmation(
      context,
      item: 'Anotação de ${patient.name}',
    );
    if (!confirmed || !mounted) return;
    setState(() => _busyNoteIds.add(note.id));
    try {
      await widget.store.removeNote(note.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Anotação removida.')));
    } catch (error) {
      if (mounted) showProfessionalOperationError(context, error);
    } finally {
      if (mounted) setState(() => _busyNoteIds.remove(note.id));
    }
  }
}

class _ClinicalNotesHeader extends StatelessWidget {
  const _ClinicalNotesHeader();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium;
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            Expanded(flex: 3, child: Text('Paciente', style: style)),
            const SizedBox(width: 16),
            SizedBox(width: 118, child: Text('Registro', style: style)),
            const SizedBox(width: 16),
            Expanded(flex: 5, child: Text('Anotação', style: style)),
            const SizedBox(width: 156),
          ],
        ),
      ),
    );
  }
}

class _ClinicalNoteRow extends StatelessWidget {
  const _ClinicalNoteRow({
    required this.note,
    required this.patient,
    required this.compact,
    required this.busy,
    required this.onOpenPatient,
    required this.canEdit,
    required this.onEdit,
    required this.onDelete,
  });

  final ProfessionalClinicalNote note;
  final ProfessionalPatient patient;
  final bool compact;
  final bool busy;
  final VoidCallback onOpenPatient;
  final bool canEdit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final patientInfo = Row(
      children: [
        PatientAvatar(patient: patient, size: compact ? 44 : 40),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            patient.name,
            style: theme.textTheme.titleMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton.icon(
          onPressed: busy ? null : onOpenPatient,
          icon: const Icon(Icons.open_in_new_rounded, size: 18),
          label: const Text('Paciente'),
        ),
        if (busy)
          const SizedBox.square(
            dimension: 44,
            child: Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else
          PopupMenuButton<String>(
            enabled: canEdit,
            tooltip: canEdit ? 'Ações' : 'Ative o acompanhamento para alterar',
            onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Editar')),
              PopupMenuItem(value: 'delete', child: Text('Remover')),
            ],
          ),
      ],
    );

    final content = compact
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: patientInfo),
                  const SizedBox(width: 12),
                  _NoteTag(tag: note.tag),
                ],
              ),
              const SizedBox(height: 12),
              Text(note.date, style: theme.textTheme.bodySmall),
              const SizedBox(height: 8),
              Text(note.text, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerRight, child: actions),
            ],
          )
        : Row(
            children: [
              Expanded(flex: 3, child: patientInfo),
              const SizedBox(width: 16),
              SizedBox(
                width: 118,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _NoteTag(tag: note.tag),
                    const SizedBox(height: 6),
                    Text(note.date, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 5,
                child: Text(
                  note.text,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              actions,
            ],
          );

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 16 : 24,
        vertical: 16,
      ),
      child: content,
    );
  }
}

class _NoteTag extends StatelessWidget {
  const _NoteTag({required this.tag});

  final String tag;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final semantic = AppSemanticColors.of(context);
    final (background, foreground) = switch (tag) {
      'Atenção' => (semantic.warningContainer, semantic.onWarningContainer),
      'Consulta' => (semantic.infoContainer, semantic.onInfoContainer),
      _ => (colors.primaryContainer, colors.onPrimaryContainer),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        tag,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
