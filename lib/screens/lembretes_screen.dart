import 'package:flutter/material.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/widgets/app_lembretes_content.dart';
import 'package:iris/widgets/app_reminder_form.dart';
import 'package:iris/widgets/app_responsive.dart';

class LembretesScreen extends StatefulWidget {
  const LembretesScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  State<LembretesScreen> createState() => _LembretesScreenState();
}

class _LembretesScreenState extends State<LembretesScreen> {
  final List<_PatientReminder> _reminders = [
    const _PatientReminder(
      id: 1,
      type: AppReminderType.meal,
      title: 'Café da manhã',
      time: TimeOfDay(hour: 8, minute: 0),
      isActive: true,
    ),
    const _PatientReminder(
      id: 2,
      type: AppReminderType.medication,
      title: 'Vitamina D',
      time: TimeOfDay(hour: 9, minute: 0),
      isActive: true,
    ),
  ];

  bool _showForm = false;
  int? _editingId;
  int _nextId = 3;
  AppReminderType _newReminderType = AppReminderType.meal;

  _PatientReminder? get _editingReminder {
    if (_editingId == null) return null;
    for (final reminder in _reminders) {
      if (reminder.id == _editingId) return reminder;
    }
    return null;
  }

  void _openCreate([AppReminderType type = AppReminderType.meal]) {
    setState(() {
      _showForm = true;
      _editingId = null;
      _newReminderType = type;
    });
  }

  void _openEdit(_PatientReminder reminder) {
    setState(() {
      _showForm = true;
      _editingId = reminder.id;
    });
  }

  void _closeForm() {
    setState(() {
      _showForm = false;
      _editingId = null;
    });
  }

  void _saveReminder(AppReminderDraft draft) {
    final editingIndex = _editingId == null
        ? -1
        : _reminders.indexWhere((item) => item.id == _editingId);

    setState(() {
      if (editingIndex == -1) {
        _reminders.add(
          _PatientReminder(
            id: _nextId++,
            type: draft.type,
            title: draft.title,
            time: draft.time,
            isActive: true,
          ),
        );
      } else {
        final current = _reminders[editingIndex];
        _reminders[editingIndex] = current.copyWith(
          type: draft.type,
          title: draft.title,
          time: draft.time,
        );
      }
      _showForm = false;
      _editingId = null;
      _sortReminders();
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            editingIndex == -1
                ? 'Lembrete adicionado nesta sessão.'
                : 'Lembrete atualizado nesta sessão.',
          ),
        ),
      );
  }

  void _sortReminders() {
    _reminders.sort((a, b) {
      final typeOrder = a.type.index.compareTo(b.type.index);
      if (typeOrder != 0) return typeOrder;
      return _minutes(a.time).compareTo(_minutes(b.time));
    });
  }

  int _minutes(TimeOfDay time) => time.hour * 60 + time.minute;

  void _toggleReminder(_PatientReminder reminder, bool value) {
    final index = _reminders.indexWhere((item) => item.id == reminder.id);
    if (index == -1) return;
    setState(() {
      _reminders[index] = reminder.copyWith(isActive: value);
    });
  }

  Future<void> _confirmDelete(_PatientReminder reminder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir lembrete?'),
        content: Text(
          'O lembrete “${reminder.title}” será removido desta sessão.',
        ),
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
    final previousIndex = _reminders.indexOf(reminder);
    setState(() => _reminders.remove(reminder));

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Lembrete excluído.'),
          action: SnackBarAction(
            label: 'Desfazer',
            onPressed: () {
              if (!mounted) return;
              setState(() {
                final index = previousIndex.clamp(0, _reminders.length);
                _reminders.insert(index, reminder);
              });
            },
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final semanticColors = AppSemanticColors.of(context);
    final meals = _reminders
        .where((item) => item.type == AppReminderType.meal)
        .toList(growable: false);
    final medications = _reminders
        .where((item) => item.type == AppReminderType.medication)
        .toList(growable: false);
    final editing = _editingReminder;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: AppGradientHeader(
              padding: EdgeInsets.zero,
              child: SafeArea(
                bottom: false,
                child: AppResponsive(
                  maxWidth: 860,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        tooltip: 'Voltar',
                        onPressed:
                            widget.onBack ?? () => Navigator.maybePop(context),
                        style: IconButton.styleFrom(
                          minimumSize: const Size.square(48),
                          foregroundColor: AppColors.white,
                          backgroundColor: AppColors.white.withValues(
                            alpha: .12,
                          ),
                        ),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Lembretes',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(color: AppColors.white),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Organize horários de refeições e medicamentos.',
                        style: TextStyle(color: AppColors.white),
                      ),
                      const SizedBox(height: 22),
                      FilledButton.icon(
                        onPressed: _showForm ? _closeForm : _openCreate,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.white,
                          foregroundColor: AppColors.deepPurple,
                        ),
                        icon: Icon(
                          _showForm ? Icons.close_rounded : Icons.add_rounded,
                        ),
                        label: Text(
                          _showForm
                              ? 'Fechar formulário'
                              : 'Adicionar lembrete',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: AppResponsive(
              maxWidth: 860,
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: semanticColors.infoContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: semanticColors.onInfoContainer,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Nesta versão, as alterações ficam disponíveis apenas enquanto esta tela estiver aberta.',
                            style: TextStyle(
                              color: semanticColors.onInfoContainer,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: !_showForm
                        ? const SizedBox.shrink(
                            key: ValueKey('closed-reminder-form'),
                          )
                        : Padding(
                            key: ValueKey(_editingId ?? 'new-reminder'),
                            padding: const EdgeInsets.only(top: 20),
                            child: AppReminderForm(
                              initialType: _newReminderType,
                              initialValue: editing == null
                                  ? null
                                  : AppReminderDraft(
                                      type: editing.type,
                                      title: editing.title,
                                      time: editing.time,
                                    ),
                              onCancel: _closeForm,
                              onSubmit: _saveReminder,
                            ),
                          ),
                  ),
                  const SizedBox(height: 32),
                  _ReminderSection(
                    title: 'Refeições',
                    icon: Icons.restaurant_rounded,
                    reminders: meals,
                    onAdd: () => _openCreate(AppReminderType.meal),
                    onToggle: _toggleReminder,
                    onEdit: _openEdit,
                    onDelete: _confirmDelete,
                  ),
                  const SizedBox(height: 36),
                  _ReminderSection(
                    title: 'Medicamentos',
                    icon: Icons.medication_rounded,
                    reminders: medications,
                    onAdd: () => _openCreate(AppReminderType.medication),
                    onToggle: _toggleReminder,
                    onEdit: _openEdit,
                    onDelete: _confirmDelete,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
  final List<_PatientReminder> reminders;
  final VoidCallback onAdd;
  final void Function(_PatientReminder, bool) onToggle;
  final ValueChanged<_PatientReminder> onEdit;
  final ValueChanged<_PatientReminder> onDelete;

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
                icon: reminder.type.icon,
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

class _PatientReminder {
  const _PatientReminder({
    required this.id,
    required this.type,
    required this.title,
    required this.time,
    required this.isActive,
  });

  final int id;
  final AppReminderType type;
  final String title;
  final TimeOfDay time;
  final bool isActive;

  _PatientReminder copyWith({
    AppReminderType? type,
    String? title,
    TimeOfDay? time,
    bool? isActive,
  }) {
    return _PatientReminder(
      id: id,
      type: type ?? this.type,
      title: title ?? this.title,
      time: time ?? this.time,
      isActive: isActive ?? this.isActive,
    );
  }
}
