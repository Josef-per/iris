import 'package:flutter/material.dart';
import 'package:iris/core/errors/app_error_messages.dart';
import 'package:iris/features/emotional_diary/emotional_diary_repository.dart';
import 'package:iris/widgets/app_filled_button.dart';
import 'package:iris/widgets/bottom_sheets/app_bottom_sheet.dart';

class DiarioEmocionalBottomSheet extends StatefulWidget {
  const DiarioEmocionalBottomSheet({super.key});

  @override
  State<DiarioEmocionalBottomSheet> createState() =>
      _DiarioEmocionalBottomSheetState();
}

class _DiarioEmocionalBottomSheetState
    extends State<DiarioEmocionalBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  final _repository = EmotionalDiaryRepository();

  bool _isLoading = false;
  bool _isLoadingTodayRecord = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTodayRecord();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadTodayRecord() async {
    try {
      final record = await _repository.getTodayRecord();

      if (!mounted) {
        return;
      }

      final content = record?['diario_emocional']?.toString();

      if (content != null && content.trim().isNotEmpty) {
        _contentController.text = content;
      }
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
          _isLoadingTodayRecord = false;
        });
      }
    }
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
      await _repository.createDiaryEntry(content: _contentController.text);

      if (!mounted) {
        return;
      }

      navigator.pop(true);
      messenger.showSnackBar(
        const SnackBar(content: Text('Diário emocional salvo.')),
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
              'Diário emocional',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFFFFF),
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Registre suas emoções e sintomas',
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
                  const Text(
                    'Como você está se sentindo?',
                    style: TextStyle(
                      color: Color(0xFF462A7E),
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.format_quote_rounded,
                          size: 42,
                          color: Color(0xFF2D175E),
                        ),
                        const SizedBox(height: 10),
                        if (_isLoadingTodayRecord)
                          const Center(child: CircularProgressIndicator())
                        else
                          TextFormField(
                            controller: _contentController,
                            maxLines: 4,
                            validator: _validateContent,
                            decoration: const InputDecoration(
                              hintText: 'Escreva um pouco sobre seu dia',
                              hintStyle: TextStyle(
                                color: Color(0xFF2D175E),
                                fontSize: 16,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            style: const TextStyle(
                              color: Color(0xFF2D175E),
                              fontSize: 16,
                            ),
                          ),
                      ],
                    ),
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
            const SizedBox(height: 33),
            Align(
              alignment: Alignment.bottomRight,
              child: AppFilledButton(
                text: _isLoading ? 'Salvando...' : 'Confirmar',
                backgroundColor: const Color(0xFF7D6AC6),
                textColor: const Color(0xFFFAF9F6),
                onPressed: _isLoading || _isLoadingTodayRecord ? null : _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _validateContent(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Escreva como você está se sentindo.';
    }

    return null;
  }
}
