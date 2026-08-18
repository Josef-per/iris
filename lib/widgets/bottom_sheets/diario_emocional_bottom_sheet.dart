import 'package:flutter/material.dart';
import 'package:iris/core/errors/app_error_messages.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/emotional_diary/emotional_diary_repository.dart';
import 'package:iris/widgets/bottom_sheets/app_bottom_sheet.dart';

class DiarioEmocionalBottomSheet extends StatefulWidget {
  const DiarioEmocionalBottomSheet({super.key, this.repository});

  final EmotionalDiaryDataSource? repository;

  @override
  State<DiarioEmocionalBottomSheet> createState() =>
      _DiarioEmocionalBottomSheetState();
}

class _DiarioEmocionalBottomSheetState
    extends State<DiarioEmocionalBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  late final EmotionalDiaryDataSource _repository;

  bool _isLoading = false;
  bool _isLoadingTodayRecord = true;
  bool _hasSavedContent = false;
  String? _loadErrorMessage;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? EmotionalDiaryRepository();
    _loadTodayRecord();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadTodayRecord() async {
    setState(() {
      _isLoadingTodayRecord = true;
      _loadErrorMessage = null;
    });

    try {
      final record = await _repository.getTodayRecord();
      if (!mounted) return;

      final content = record?['diario_emocional']?.toString();
      setState(() {
        _hasSavedContent = content != null && content.trim().isNotEmpty;
      });
      if (content != null && content.trim().isNotEmpty) {
        _contentController.text = content;
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadErrorMessage = AppErrorMessages.from(error));
    } finally {
      if (mounted) setState(() => _isLoadingTodayRecord = false);
    }
  }

  Future<void> _submit() async {
    if (_loadErrorMessage != null || _isLoadingTodayRecord) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _repository.createDiaryEntry(content: _contentController.text);
      if (!mounted) return;

      navigator.pop(true);
      messenger.showSnackBar(
        const SnackBar(content: Text('Diário emocional salvo.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = AppErrorMessages.from(error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _clearDiary() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Limpar diário de hoje?'),
        content: const Text(
          'O texto salvo hoje será apagado. O registro do dia e os sintomas marcados são mantidos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _repository.clearDiaryEntry();
      if (!mounted) return;

      navigator.pop(true);
      messenger.showSnackBar(
        const SnackBar(content: Text('Diário emocional limpo.')),
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
                'Diário emocional',
                style: theme.textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Reserve um momento para registrar como você está se sentindo.',
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Como você está se sentindo?',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Você pode escrever livremente, do seu jeito.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  if (_isLoadingTodayRecord)
                    Semantics(
                      liveRegion: true,
                      label: 'Carregando o registro de hoje',
                      child: const SizedBox(
                        height: 180,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    )
                  else if (_loadErrorMessage != null)
                    _DiaryLoadError(
                      message: _loadErrorMessage!,
                      onRetry: _loadTodayRecord,
                    )
                  else
                    TextFormField(
                      key: const Key('emotional-diary-field'),
                      controller: _contentController,
                      minLines: 6,
                      maxLines: 10,
                      maxLength: 4000,
                      buildCounter:
                          (
                            _, {
                            required currentLength,
                            required isFocused,
                            required maxLength,
                          }) => null,
                      textCapitalization: TextCapitalization.sentences,
                      validator: _validateContent,
                      decoration: const InputDecoration(
                        hintText: 'Escreva um pouco sobre o seu dia...',
                        alignLabelWithHint: true,
                      ),
                    ),
                  if (_hasSavedContent) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        key: const Key('emotional-diary-clear'),
                        onPressed: _isLoading ? null : _clearDiary,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.danger,
                        ),
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: const Text('Limpar diário de hoje'),
                      ),
                    ),
                  ],
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
                key: const Key('emotional-diary-submit'),
                onPressed:
                    _isLoading ||
                        _isLoadingTodayRecord ||
                        _loadErrorMessage != null
                    ? null
                    : _submit,
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

  String? _validateContent(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Escreva como você está se sentindo.';
    }
    return null;
  }
}

class _DiaryLoadError extends StatelessWidget {
  const _DiaryLoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: SizedBox(
        height: 180,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_outlined,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                key: const Key('emotional-diary-load-retry'),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
