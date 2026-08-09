import 'package:flutter/material.dart';

enum AppReminderType { meal, medication }

extension AppReminderTypeDetails on AppReminderType {
  String get label => switch (this) {
    AppReminderType.meal => 'Refeição',
    AppReminderType.medication => 'Medicamento',
  };

  IconData get icon => switch (this) {
    AppReminderType.meal => Icons.restaurant_rounded,
    AppReminderType.medication => Icons.medication_rounded,
  };
}

class AppReminderDraft {
  const AppReminderDraft({
    required this.type,
    required this.title,
    required this.time,
  });

  final AppReminderType type;
  final String title;
  final TimeOfDay time;
}

class AppReminderForm extends StatefulWidget {
  const AppReminderForm({
    super.key,
    required this.onCancel,
    required this.onSubmit,
    this.initialValue,
    this.initialType = AppReminderType.meal,
  });

  final VoidCallback onCancel;
  final ValueChanged<AppReminderDraft> onSubmit;
  final AppReminderDraft? initialValue;
  final AppReminderType initialType;

  @override
  State<AppReminderForm> createState() => _AppReminderFormState();
}

class _AppReminderFormState extends State<AppReminderForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late AppReminderType _type;
  late TimeOfDay _time;

  bool get _isEditing => widget.initialValue != null;

  @override
  void initState() {
    super.initState();
    _setInitialValues();
    _titleController = TextEditingController(
      text: widget.initialValue?.title ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant AppReminderForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue ||
        oldWidget.initialType != widget.initialType) {
      _setInitialValues();
      _titleController.text = widget.initialValue?.title ?? '';
    }
  }

  void _setInitialValues() {
    _type = widget.initialValue?.type ?? widget.initialType;
    _time = widget.initialValue?.time ?? const TimeOfDay(hour: 8, minute: 0);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _time,
      helpText: 'Selecione o horário do lembrete',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );

    if (selected != null && mounted) {
      setState(() => _time = selected);
    }
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    widget.onSubmit(
      AppReminderDraft(
        type: _type,
        title: _titleController.text.trim(),
        time: _time,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEditing ? 'Editar lembrete' : 'Novo lembrete',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'Escolha o tipo, dê um nome e defina o horário.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 22),
            DropdownButtonFormField<AppReminderType>(
              key: const Key('reminder-type-field'),
              initialValue: _type,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: AppReminderType.values
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(type.label, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value != null) setState(() => _type = value);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('reminder-title-field'),
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              maxLength: 60,
              decoration: const InputDecoration(
                labelText: 'Título',
                hintText: 'Ex.: Café da manhã',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Informe um título para o lembrete.';
                }
                return null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 4),
            Text('Horário', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Semantics(
              button: true,
              label: 'Horário do lembrete',
              value: _time.format(context),
              child: InkWell(
                key: const Key('reminder-time-field'),
                onTap: _pickTime,
                borderRadius: BorderRadius.circular(16),
                child: Ink(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: theme.inputDecorationTheme.fillColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _time.format(context),
                        style: theme.textTheme.bodyLarge,
                      ),
                      const Spacer(),
                      Icon(
                        Icons.edit_calendar_outlined,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final cancel = OutlinedButton(
                  onPressed: widget.onCancel,
                  child: const Text('Cancelar'),
                );
                final submit = FilledButton(
                  key: const Key('reminder-submit'),
                  onPressed: _submit,
                  child: Text(_isEditing ? 'Salvar' : 'Adicionar'),
                );

                if (constraints.maxWidth < 300) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [submit, const SizedBox(height: 10), cancel],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: cancel),
                    const SizedBox(width: 12),
                    Expanded(child: submit),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
