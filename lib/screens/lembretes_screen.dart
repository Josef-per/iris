import 'package:flutter/material.dart';
import 'package:iris/core/errors/app_error_messages.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/reminders/reminder_repository.dart';
import 'package:iris/widgets/app_lembretes_content.dart';
import 'package:iris/widgets/app_function_header.dart';
import 'package:iris/widgets/app_reminder_form.dart';
import 'package:iris/widgets/app_responsive.dart';

class LembretesScreen extends StatefulWidget {
  const LembretesScreen({
    super.key,
    this.dataSource,
    this.embeddedInNavigationShell = false,
  });

  final ReminderDataSource? dataSource;
  final bool embeddedInNavigationShell;

  @override
  State<LembretesScreen> createState() => _LembretesScreenState();
}

class _LembretesScreenState extends State<LembretesScreen> {
  late final ReminderDataSource _dataSource;
  late Future<List<PatientReminder>> _remindersFuture;

  bool _showForm = false;
  String? _editingId;
  PatientReminderType _newReminderType = PatientReminderType.refeicao;

  PatientReminder? _editingReminder;

  @override
  void initState() {
    super.initState();
    _dataSource = widget.dataSource ?? ReminderRepository();
    _remindersFuture = _dataSource.listCurrentUserReminders();
  }

  Future<void> _reload() async {
    setState(() {
      _remindersFuture = _dataSource.listCurrentUserReminders();
    });
    await _remindersFuture;
  }

  void _openCreate([PatientReminderType type = PatientReminderType.refeicao]) {
    setState(() {
      _showForm = true;
      _editingId = null;
      _editingReminder = null;
      _newReminderType = type;
    });
  }

  void _openEdit(PatientReminder reminder) {
    setState(() {
      _showForm = true;
      _editingId = reminder.id;
      _editingReminder = reminder;
      _newReminderType = reminder.type;
    });
  }

  void _closeForm() {
    setState(() {
      _showForm = false;
      _editingId = null;
      _editingReminder = null;
    });
  }

  Future<void> _saveReminder(AppReminderDraft draft) async {
    final messenger = ScaffoldMessenger.of(context);
    final isEditing = _editingId != null;
    final type = _toPatientType(draft.type);

    try {
      if (isEditing) {
        await _dataSource.updateReminder(
          id: _editingId!,
          type: type,
          title: draft.title,
          time: draft.time,
        );
      } else {
        await _dataSource.createReminder(
          type: type,
          title: draft.title,
          time: draft.time,
        );
      }
      if (!mounted) return;
      _closeForm();
      await _reload();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              isEditing ? 'Lembrete atualizado.' : 'Lembrete adicionado.',
            ),
          ),
        );
    } catch (error) {
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(AppErrorMessages.from(error))));
    }
  }

  Future<void> _toggleReminder(PatientReminder reminder, bool value) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _dataSource.setReminderActive(id: reminder.id, isActive: value);
      if (!mounted) return;
      await _reload();
    } catch (error) {
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(AppErrorMessages.from(error))));
    }
  }

  Future<void> _confirmDelete(PatientReminder reminder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir lembrete?'),
        content: Text('O lembrete “${reminder.title}” será removido.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _dataSource.deleteReminder(reminder.id);
      if (!mounted) return;
      await _reload();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text('Lembrete excluído.'),
            action: SnackBarAction(
              label: 'Desfazer',
              onPressed: () async {
                try {
                  await _dataSource.createReminder(
                    type: reminder.type,
                    title: reminder.title,
                    time: reminder.time,
                    isActive: reminder.isActive,
                  );
                  if (!mounted) return;
                  await _reload();
                } catch (_) {
                  // O lembrete original não pode ser recriado; a lista segue
                  // como está após a exclusão.
                }
              },
            ),
          ),
        );
    } catch (error) {
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(AppErrorMessages.from(error))));
    }
  }

  PatientReminderType _toPatientType(AppReminderType type) => switch (type) {
    AppReminderType.meal => PatientReminderType.refeicao,
    AppReminderType.medication => PatientReminderType.medicamento,
  };

  AppReminderType _toAppType(PatientReminderType type) => switch (type) {
    PatientReminderType.refeicao => AppReminderType.meal,
    PatientReminderType.medicamento => AppReminderType.medication,
  };

  @override
  Widget build(BuildContext context) {
    final content = CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: AppFunctionHeader(
            title: 'Lembretes',
            description: 'Organize horários de refeições e medicamentos.',
            footer: FilledButton.icon(
              onPressed: _showForm ? _closeForm : _openCreate,
              style: AppButtonStyles.onBrandFilled,
              icon: Icon(_showForm ? Icons.close_rounded : Icons.add_rounded),
              label: Text(
                _showForm ? 'Fechar formulário' : 'Adicionar lembrete',
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: AppResponsive(
            maxWidth: 860,
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 48),
            child: FutureBuilder<List<PatientReminder>>(
              future: _remindersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    key: const Key('reminders-loading'),
                    child: Semantics(
                      liveRegion: true,
                      label: 'Carregando lembretes',
                      child: const Padding(
                        padding: EdgeInsets.all(48),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return AppSurface(
                    key: const Key('reminders-error'),
                    child: Column(
                      children: [
                        Icon(
                          Icons.cloud_off_rounded,
                          size: 44,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Não foi possível carregar os lembretes',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppErrorMessages.from(snapshot.error!),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          key: const Key('reminders-retry'),
                          onPressed: () {
                            setState(() {
                              _remindersFuture = _dataSource
                                  .listCurrentUserReminders();
                            });
                          },
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  );
                }

                final reminders = snapshot.data ?? const <PatientReminder>[];
                final meals = reminders
                    .where((item) => item.type == PatientReminderType.refeicao)
                    .toList(growable: false);
                final medications = reminders
                    .where(
                      (item) => item.type == PatientReminderType.medicamento,
                    )
                    .toList(growable: false);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: !_showForm
                          ? const SizedBox.shrink(
                              key: ValueKey('closed-reminder-form'),
                            )
                          : Padding(
                              key: ValueKey(_editingId ?? 'new-reminder'),
                              padding: const EdgeInsets.only(bottom: 28),
                              child: AppReminderForm(
                                initialType: _toAppType(_newReminderType),
                                initialValue: _editingReminder == null
                                    ? null
                                    : AppReminderDraft(
                                        type: _toAppType(
                                          _editingReminder!.type,
                                        ),
                                        title: _editingReminder!.title,
                                        time: _editingReminder!.time,
                                      ),
                                onCancel: _closeForm,
                                onSubmit: _saveReminder,
                              ),
                            ),
                    ),
                    _ReminderSection(
                      title: 'Refeições',
                      icon: Icons.restaurant_rounded,
                      reminders: meals,
                      onAdd: () => _openCreate(PatientReminderType.refeicao),
                      onToggle: _toggleReminder,
                      onEdit: _openEdit,
                      onDelete: _confirmDelete,
                    ),
                    const SizedBox(height: 36),
                    _ReminderSection(
                      title: 'Medicamentos',
                      icon: Icons.medication_rounded,
                      reminders: medications,
                      onAdd: () => _openCreate(PatientReminderType.medicamento),
                      onToggle: _toggleReminder,
                      onEdit: _openEdit,
                      onDelete: _confirmDelete,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );

    if (widget.embeddedInNavigationShell) return content;
    return Scaffold(body: content);
  }
}

class _ReminderSection extends StatelessWidget {
  const _ReminderSection({
    required this.title,
    required this.icon,
    required this.reminders,
    required this.onAdd,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final String title;
  final IconData icon;
  final List<PatientReminder> reminders;
  final VoidCallback onAdd;
  final void Function(PatientReminder, bool) onToggle;
  final ValueChanged<PatientReminder> onEdit;
  final ValueChanged<PatientReminder> onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 24),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: theme.textTheme.titleLarge)),
            Text('${reminders.length}', style: theme.textTheme.bodyMedium),
          ],
        ),
        const SizedBox(height: 14),
        if (reminders.isEmpty)
          Container(
            key: Key('empty-${title.toLowerCase()}'),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border.all(color: theme.colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(icon, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(height: 10),
                Text(
                  'Nenhum lembrete de ${title.toLowerCase()}.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Adicionar'),
                ),
              ],
            ),
          )
        else
          ...reminders.map(
            (reminder) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppLembretesContent(
                key: ValueKey('reminder-${reminder.id}'),
                icon: reminder.type == PatientReminderType.refeicao
                    ? Icons.restaurant_rounded
                    : Icons.medication_rounded,
                categoryLabel: reminder.type.label,
                textName: reminder.title,
                textTime: reminder.time.format(context),
                isActive: reminder.isActive,
                onSwitchChanged: (value) => onToggle(reminder, value),
                onEdit: () => onEdit(reminder),
                onDelete: () => onDelete(reminder),
              ),
            ),
          ),
      ],
    );
  }
}
