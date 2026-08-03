import 'package:flutter/material.dart';
import 'package:iris/core/errors/app_error_messages.dart';
import 'package:iris/features/food/food_record_repository.dart';
import 'package:iris/widgets/app_filled_button.dart';
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

    if (!_formKey.currentState!.validate()) {
      return;
    }

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

      if (!mounted) {
        return;
      }

      navigator.pop(true);
      messenger.showSnackBar(
        const SnackBar(content: Text('Registro alimentar salvo.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = AppErrorMessages.from(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomSheet(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            const Text(
              'Registro de alimentação',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFFFFF),
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Conte como foi sua refeição',
              style: TextStyle(fontSize: 14, color: Color(0x99FFFFFF)),
            ),
            const SizedBox(height: 20),
            _WhitePanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LabeledField(
                    controller: _descriptionController,
                    label: 'O que você comeu?',
                    hint: 'Descreva a refeição',
                    maxLines: 3,
                    validator: _validateDescription,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Nível de fome: $_hungerLevel',
                    style: const TextStyle(
                      color: Color(0xFF462A7E),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Slider(
                    value: _hungerLevel.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    activeColor: const Color(0xFF7D6AC6),
                    label: _hungerLevel.toString(),
                    onChanged: _isLoading
                        ? null
                        : (value) {
                            setState(() {
                              _hungerLevel = value.round();
                            });
                          },
                  ),
                  const SizedBox(height: 10),
                  _LabeledField(
                    controller: _feelingController,
                    label: 'Como você se sentiu depois?',
                    hint: 'Opcional',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 18),
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
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Color(0xFFFFD6D6),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.bottomRight,
              child: AppFilledButton(
                text: _isLoading ? 'Salvando...' : 'Confirmar',
                backgroundColor: const Color(0xFF7D6AC6),
                textColor: const Color(0xFFFAF9F6),
                onPressed: _isLoading ? null : _submit,
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

class _WhitePanel extends StatelessWidget {
  final Widget child;

  const _WhitePanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _LabeledField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final String? Function(String?)? validator;

  const _LabeledField({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF462A7E),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFF8F8F8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
          style: const TextStyle(color: Color(0xFF2D175E), fontSize: 16),
        ),
      ],
    );
  }
}
