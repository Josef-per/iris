import 'package:flutter/material.dart';
import 'package:iris/core/errors/app_error_messages.dart';
import 'package:iris/features/emotional_diary/emotional_diary_repository.dart';
import 'package:iris/widgets/app_filled_button.dart';
import 'package:iris/widgets/bottom_sheets/app_bottom_sheet.dart';

class CheckInDiarioBottomSheet extends StatefulWidget {
  const CheckInDiarioBottomSheet({super.key});

  @override
  State<CheckInDiarioBottomSheet> createState() =>
      _CheckInDiarioBottomSheetState();
}

class _CheckInDiarioBottomSheetState extends State<CheckInDiarioBottomSheet> {
  final _moodController = TextEditingController();
  final _repository = EmotionalDiaryRepository();

  bool _isLoading = false;
  int _comoSentiu = 3;
  int _avaliacaoAlimentacao = 3;
  int _sintomasEmocionais = 0;
  int _sintomasFisicos = 0;
  String? _errorMessage;

  @override
  void dispose() {
    _moodController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await _repository.createCheckIn(
        humor: _moodController.text,
        comoSentiu: _comoSentiu,
        avaliacaoAlimentacao: _avaliacaoAlimentacao,
        sintomasEmocionaisHoje: _sintomasEmocionais,
        sintomasFisicosHoje: _sintomasFisicos,
      );

      if (!mounted) {
        return;
      }

      navigator.pop(true);
      messenger.showSnackBar(
        const SnackBar(content: Text('Check-in diário salvo.')),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          const Text(
            'Check-in diário',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFFFFF),
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Registre como está seu dia',
            style: TextStyle(fontSize: 14, color: Color(0x99FFFFFF)),
          ),
          const SizedBox(height: 20),
          Container(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _moodController,
                  decoration: InputDecoration(
                    labelText: 'Humor',
                    hintText: 'Ex: calmo, ansioso, bem',
                    filled: true,
                    fillColor: const Color(0xFFF8F8F8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _MetricSlider(
                  label: 'Como se sentiu',
                  value: _comoSentiu,
                  min: 1,
                  max: 5,
                  onChanged: (value) {
                    setState(() {
                      _comoSentiu = value;
                    });
                  },
                ),
                _MetricSlider(
                  label: 'Avaliação da alimentação',
                  value: _avaliacaoAlimentacao,
                  min: 1,
                  max: 5,
                  onChanged: (value) {
                    setState(() {
                      _avaliacaoAlimentacao = value;
                    });
                  },
                ),
                _MetricSlider(
                  label: 'Sintomas emocionais hoje',
                  value: _sintomasEmocionais,
                  min: 0,
                  max: 6,
                  onChanged: (value) {
                    setState(() {
                      _sintomasEmocionais = value;
                    });
                  },
                ),
                _MetricSlider(
                  label: 'Sintomas físicos hoje',
                  value: _sintomasFisicos,
                  min: 0,
                  max: 10,
                  onChanged: (value) {
                    setState(() {
                      _sintomasFisicos = value;
                    });
                  },
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
    );
  }
}

class _MetricSlider extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _MetricSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: $value',
          style: const TextStyle(
            color: Color(0xFF462A7E),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Slider(
          value: value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          activeColor: const Color(0xFF7D6AC6),
          label: value.toString(),
          onChanged: (nextValue) => onChanged(nextValue.round()),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
