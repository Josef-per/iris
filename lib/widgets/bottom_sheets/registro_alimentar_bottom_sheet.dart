import 'package:flutter/material.dart';
import 'package:iris/core/errors/app_error_messages.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/food/food_record_repository.dart';
import 'package:iris/widgets/bottom_sheets/app_bottom_sheet.dart';

class RegistroAlimentarBottomSheet extends StatefulWidget {
  const RegistroAlimentarBottomSheet({super.key, this.repository});

  final FoodRecordDataSource? repository;

  @override
  State<RegistroAlimentarBottomSheet> createState() =>
      _RegistroAlimentarBottomSheetState();
}

class _RegistroAlimentarBottomSheetState
    extends State<RegistroAlimentarBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _feelingController = TextEditingController();
  final _observationsController = TextEditingController();
  late final FoodRecordDataSource _repository;

  bool _isLoading = false;
  int _hungerLevel = 5;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? FoodRecordRepository();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _feelingController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _repository.createRecord(
        description: _descriptionController.text,
        hungerLevel: _hungerLevel,
        feelingAfter: _feelingController.text,
        observations: _observationsController.text,
      );
      if (!mounted) return;

      navigator.pop(true);
      messenger.showSnackBar(
        const SnackBar(content: Text('Registro alimentar salvo.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = AppErrorMessages.from(error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppBottomSheet(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                'Registro de alimentação',
                style: theme.textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Conte como foi sua refeição e como você se sentiu.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _LabeledField(
                    controller: _descriptionController,
                    label: 'O que você comeu?',
                    hint: 'Descreva a refeição',
                    maxLines: 3,
                    validator: _validateDescription,
                  ),
                  const SizedBox(height: 20),
                  Semantics(
                    label: 'Nível de fome',
                    value: '$_hungerLevel de 10',
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Nível de fome',
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.lavender.withValues(alpha: .45),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '$_hungerLevel/10',
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Slider(
                    value: _hungerLevel.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: _hungerLevel.toString(),
                    onChanged: _isLoading
                        ? null
                        : (value) {
                            setState(() => _hungerLevel = value.round());
                          },
                  ),
                  const SizedBox(height: 12),
                  _LabeledField(
                    controller: _feelingController,
                    label: 'Como você se sentiu depois?',
                    hint: 'Opcional',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),
                  _LabeledField(
                    controller: _observationsController,
                    label: 'Observações',
                    hint: 'Opcional',
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Semantics(
                liveRegion: true,
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                key: const Key('food-record-submit'),
                onPressed: _isLoading ? null : _submit,
                icon: _isLoading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(_isLoading ? 'Salvando...' : 'Confirmar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Descreva a refeição.';
    }
    return null;
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      minLines: maxLines,
      maxLines: maxLines,
      validator: validator,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: maxLines > 1,
      ),
    );
  }
}
