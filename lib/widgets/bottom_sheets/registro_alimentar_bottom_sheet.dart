import 'package:flutter/material.dart';
import 'package:iris/core/errors/app_error_messages.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/food/meal_image_picker.dart';
import 'package:iris/features/food/food_record_repository.dart';
import 'package:iris/features/food/meal_type.dart';
import 'package:iris/widgets/bottom_sheets/app_bottom_sheet.dart';

enum _FoodSheetView { list, form }

class RegistroAlimentarBottomSheet extends StatefulWidget {
  const RegistroAlimentarBottomSheet({
    super.key,
    this.repository,
    this.imagePicker,
  });

  final FoodRecordDataSource? repository;
  final MealImagePicker? imagePicker;

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
  late final MealImagePicker _imagePicker;

  _FoodSheetView _view = _FoodSheetView.list;
  List<FoodRecord> _records = const [];
  FoodRecord? _editing;

  bool _isLoading = false;
  bool _isPickingImage = false;
  bool _isLoadingTodayRecords = true;
  bool _changed = false;
  String? _loadErrorMessage;
  String? _errorMessage;
  String? _imageErrorMessage;
  MealImage? _mealImage;

  MealType? _mealType;
  int _hungerLevel = 5;
  TimeOfDay _mealTime = const TimeOfDay(hour: 12, minute: 0);

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? FoodRecordRepository();
    _imagePicker = widget.imagePicker ?? DeviceMealImagePicker();
    if (_imagePicker.isSupported) _restoreInterruptedImageCapture();
    _loadTodayRecords();
  }

  Future<void> _restoreInterruptedImageCapture() async {
    try {
      final image = await _imagePicker.retrieveLostPhoto();
      if (!mounted || image == null) return;
      setState(() => _mealImage = image);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _imageErrorMessage =
            'Não foi possível recuperar a foto tirada anteriormente.';
      });
    }
  }

  Future<void> _takeMealPhoto() async {
    await _pickMealImage(
      pickImage: _imagePicker.takePhoto,
      errorMessage:
          'Não foi possível acessar a câmera. Verifique a permissão e tente novamente.',
    );
  }

  Future<void> _chooseMealPhoto() async {
    await _pickMealImage(
      pickImage: _imagePicker.chooseFromGallery,
      errorMessage:
          'Não foi possível acessar a galeria. Verifique a permissão e tente novamente.',
    );
  }

  Future<void> _pickMealImage({
    required Future<MealImage?> Function() pickImage,
    required String errorMessage,
  }) async {
    setState(() {
      _isPickingImage = true;
      _imageErrorMessage = null;
    });

    try {
      final image = await pickImage();
      if (!mounted || image == null) return;
      setState(() => _mealImage = image);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _imageErrorMessage = errorMessage;
      });
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _feelingController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  Future<void> _loadTodayRecords() async {
    setState(() {
      _isLoadingTodayRecords = true;
      _loadErrorMessage = null;
      _errorMessage = null;
    });

    try {
      final records = await _repository.listRecordsForLocalDay(DateTime.now());
      if (!mounted) return;
      setState(() {
        _records = records;
        _isLoadingTodayRecords = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadErrorMessage = AppErrorMessages.from(error);
        _isLoadingTodayRecords = false;
      });
    }
  }

  Future<void> _refreshRecords() async {
    try {
      final records = await _repository.listRecordsForLocalDay(DateTime.now());
      if (!mounted) return;
      setState(() => _records = records);
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = AppErrorMessages.from(error));
    }
  }

  void _closeSheet() {
    final navigator = Navigator.of(context);
    if (_changed) {
      navigator.pop(true);
    } else {
      navigator.maybePop();
    }
  }

  void _openCreateForm() {
    setState(() {
      _editing = null;
      _descriptionController.clear();
      _feelingController.clear();
      _observationsController.clear();
      _mealType = null;
      _hungerLevel = 5;
      _mealTime = _nowTime();
      _errorMessage = null;
      _imageErrorMessage = null;
      _mealImage = null;
      _view = _FoodSheetView.form;
    });
  }

  void _openEditForm(FoodRecord record) {
    setState(() {
      _editing = record;
      _descriptionController.text = record.description;
      _feelingController.text = record.feelingAfter ?? '';
      _observationsController.text = record.observations ?? '';
      _mealType = record.mealType;
      _hungerLevel = record.hungerLevel ?? 5;
      _mealTime = TimeOfDay.fromDateTime(record.mealTime.toLocal());
      _errorMessage = null;
      _imageErrorMessage = null;
      _mealImage = null;
      _view = _FoodSheetView.form;
    });
  }

  void _backToList() {
    setState(() {
      _view = _FoodSheetView.list;
      _errorMessage = null;
    });
  }

  TimeOfDay _nowTime() {
    final now = DateTime.now();
    return TimeOfDay(hour: now.hour, minute: now.minute);
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _mealTime,
      helpText: 'Selecione o horário da refeição',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );

    if (selected != null && mounted) {
      setState(() => _mealTime = selected);
    }
  }

  DateTime _todayAt(TimeOfDay time) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, time.hour, time.minute);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final messenger = ScaffoldMessenger.of(context);
    final editingId = _editing?.id;
    final mealTime = _todayAt(_mealTime);
    late final FoodRecordSaveResult saveResult;

    try {
      if (editingId == null) {
        saveResult = await _repository.createRecord(
          description: _descriptionController.text,
          hungerLevel: _hungerLevel,
          mealType: _mealType,
          feelingAfter: _feelingController.text,
          observations: _observationsController.text,
          mealTime: mealTime,
          photo: _mealImage,
        );
      } else {
        saveResult = await _repository.updateRecord(
          id: editingId,
          description: _descriptionController.text,
          hungerLevel: _hungerLevel,
          mealType: _mealType,
          feelingAfter: _feelingController.text,
          observations: _observationsController.text,
          mealTime: mealTime,
          photo: _mealImage,
        );
      }

      await _refreshRecords();
      if (!mounted) return;

      setState(() {
        _changed = true;
        _view = _FoodSheetView.list;
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text(_saveMessage(editingId: editingId, result: saveResult)),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = AppErrorMessages.from(error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmDelete(FoodRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir registro?'),
        content: Text(
          'O registro “${record.description}” será excluído permanentemente.',
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
    setState(() => _isLoading = true);

    final messenger = ScaffoldMessenger.of(context);
    try {
      final deleteResult = await _repository.deleteRecord(record.id);
      await _refreshRecords();
      if (!mounted) return;
      setState(() => _changed = true);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            deleteResult.photoCleanupFailed
                ? 'Registro alimentar excluído, mas a foto não pôde ser removida.'
                : 'Registro alimentar excluído.',
          ),
        ),
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
    return AppBottomSheet(
      onClose: _closeSheet,
      child: _isLoadingTodayRecords
          ? const _SheetLoading()
          : _loadErrorMessage != null
          ? _SheetLoadError(
              message: _loadErrorMessage!,
              onRetry: _loadTodayRecords,
            )
          : _view == _FoodSheetView.list
          ? _buildList(context)
          : _buildForm(context),
    );
  }

  Widget _buildList(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
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
        const SizedBox(height: 18),
        if (_records.isEmpty)
          Container(
            key: const Key('food-sheet-empty'),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.restaurant_menu_rounded,
                  size: 40,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'Nenhuma refeição registrada hoje.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Registre o que comeu e como se sentiu para acompanhar seu dia.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          )
        else
          for (var index = 0; index < _records.length; index++) ...[
            _FoodRecordTile(
              key: ValueKey('food-record-${_records[index].id}'),
              record: _records[index],
              onEdit: () => _openEditForm(_records[index]),
              onDelete: () => _confirmDelete(_records[index]),
            ),
            if (index != _records.length - 1) const SizedBox(height: 10),
          ],
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
            key: const Key('food-record-add'),
            onPressed: _isLoading ? null : _openCreateForm,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Registrar refeição'),
          ),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = _editing != null;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Voltar',
                key: const Key('food-record-back'),
                onPressed: _isLoading || _isPickingImage ? null : _backToList,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    isEditing ? 'Editar refeição' : 'Nova refeição',
                    style: theme.textTheme.headlineMedium,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Registre o que comeu, o horário e como se sentiu.',
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
                Semantics(
                  header: true,
                  child: Text(
                    'Tipo de refeição',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final type in MealType.values)
                      ChoiceChip(
                        key: ValueKey('food-meal-type-${type.code}'),
                        label: Text(type.label),
                        selected: _mealType == type,
                        onSelected: _isLoading
                            ? null
                            : (_) {
                                setState(() => _mealType = type);
                              },
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Semantics(
                  button: true,
                  label: 'Horário da refeição',
                  value: _mealTime.format(context),
                  child: InkWell(
                    key: const Key('food-record-time-field'),
                    onTap: _isLoading ? null : _pickTime,
                    borderRadius: BorderRadius.circular(16),
                    child: Ink(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      decoration: BoxDecoration(
                        color: theme.inputDecorationTheme.fillColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _mealTime.format(context),
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
                const SizedBox(height: 20),
                if (_imagePicker.isSupported) ...[
                  Text(
                    'Foto da refeição (opcional)',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  if (_mealImage == null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilledButton.icon(
                          key: const Key('food-record-take-photo'),
                          onPressed: _isLoading || _isPickingImage
                              ? null
                              : _takeMealPhoto,
                          icon: _isPickingImage
                              ? SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                )
                              : const Icon(Icons.camera_alt_outlined),
                          label: Text(
                            _isPickingImage
                                ? 'Abrindo câmera...'
                                : 'Tirar foto',
                          ),
                        ),
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          key: const Key('food-record-choose-photo'),
                          onPressed: _isLoading || _isPickingImage
                              ? null
                              : _chooseMealPhoto,
                          style: FilledButton.styleFrom(
                            backgroundColor: theme.colorScheme.secondary,
                            foregroundColor: theme.colorScheme.onSecondary,
                          ),
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Escolher da galeria'),
                        ),
                      ],
                    )
                  else ...[
                    Semantics(
                      image: true,
                      label: 'Foto selecionada da refeição',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.memory(
                            _mealImage!.bytes,
                            key: const Key('food-record-photo-preview'),
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          key: const Key('food-record-replace-photo'),
                          onPressed: _isLoading || _isPickingImage
                              ? null
                              : _takeMealPhoto,
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: const Text('Trocar foto'),
                        ),
                        OutlinedButton.icon(
                          key: const Key(
                            'food-record-replace-photo-from-gallery',
                          ),
                          onPressed: _isLoading || _isPickingImage
                              ? null
                              : _chooseMealPhoto,
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Escolher da galeria'),
                        ),
                        TextButton.icon(
                          key: const Key('food-record-remove-photo'),
                          onPressed: _isLoading || _isPickingImage
                              ? null
                              : () => setState(() => _mealImage = null),
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: const Text('Remover'),
                        ),
                      ],
                    ),
                  ],
                  if (_imageErrorMessage != null) ...[
                    const SizedBox(height: 8),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        _imageErrorMessage!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
                _LabeledField(
                  controller: _descriptionController,
                  label: 'O que você comeu?',
                  hint: 'Descreva a refeição',
                  maxLines: 3,
                  maxLength: 1000,
                  fieldKey: const Key('food-record-description-field'),
                  validator: _validateDescription,
                ),
                const SizedBox(height: 16),
                Semantics(
                  label: 'Quanta fome você sentiu',
                  value: '$_hungerLevel de 10',
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Quanta fome você sentiu?',
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
                  key: const Key('food-record-hunger-slider'),
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
                const SizedBox(height: 8),
                _LabeledField(
                  controller: _feelingController,
                  label: 'Como você se sentiu depois da refeição?',
                  hint: 'Opcional',
                  maxLines: 2,
                  maxLength: 400,
                  fieldKey: const Key('food-record-feeling-field'),
                ),
                const SizedBox(height: 20),
                _LabeledField(
                  controller: _observationsController,
                  label: 'Observações',
                  hint: 'Opcional',
                  maxLines: 2,
                  maxLength: 1000,
                  fieldKey: const Key('food-record-observations-field'),
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
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading || _isPickingImage ? null : _backToList,
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  key: const Key('food-record-submit'),
                  onPressed: _isLoading || _isPickingImage ? null : _submit,
                  icon: _isLoading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(_isLoading ? 'Salvando...' : 'Salvar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String? _validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Descreva a refeição.';
    }
    return null;
  }

  String _saveMessage({
    required String? editingId,
    required FoodRecordSaveResult result,
  }) {
    final action = editingId == null ? 'salvo' : 'atualizado';
    return switch (result.photoIssue) {
      null => 'Registro alimentar $action.',
      FoodRecordPhotoIssue.uploadFailed =>
        'Registro alimentar $action, mas não foi possível salvar a foto.',
      FoodRecordPhotoIssue.previousPhotoCleanupFailed =>
        'Registro alimentar $action, mas a foto anterior não pôde ser removida.',
    };
  }
}

class _FoodRecordTile extends StatelessWidget {
  const _FoodRecordTile({
    super.key,
    required this.record,
    required this.onEdit,
    required this.onDelete,
  });

  final FoodRecord record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = record.mealType?.label ?? 'Refeição';
    final details = <String>[
      if (record.hungerLevel != null) 'Fome: ${record.hungerLevel}/10',
      if (record.feelingAfter != null) record.feelingAfter!,
      if (record.observations != null) record.observations!,
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.lavender.withValues(alpha: .55),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.restaurant_rounded,
              color: theme.colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _formatTime(record.mealTime.toLocal()),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(record.description, style: theme.textTheme.bodyMedium),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    details.join(' · '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<_FoodRecordAction>(
            tooltip: 'Mais ações para $title',
            constraints: const BoxConstraints(minWidth: 180),
            onSelected: (action) {
              switch (action) {
                case _FoodRecordAction.edit:
                  onEdit();
                case _FoodRecordAction.delete:
                  onDelete();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: _FoodRecordAction.edit,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Editar'),
                ),
              ),
              PopupMenuItem(
                value: _FoodRecordAction.delete,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.delete_outline_rounded,
                    color: theme.colorScheme.error,
                  ),
                  title: Text(
                    'Excluir',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              ),
            ],
            icon: const Icon(Icons.more_vert_rounded),
          ),
        ],
      ),
    );
  }
}

enum _FoodRecordAction { edit, delete }

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.maxLength,
    this.fieldKey,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final int? maxLength;
  final Key? fieldKey;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: fieldKey,
      controller: controller,
      minLines: maxLines,
      maxLines: maxLines,
      maxLength: maxLength,
      buildCounter:
          (
            _, {
            required currentLength,
            required isFocused,
            required maxLength,
          }) => null,
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

class _SheetLoading extends StatelessWidget {
  const _SheetLoading();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: 'Carregando os registros de hoje',
      child: const SizedBox(
        height: 320,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _SheetLoadError extends StatelessWidget {
  const _SheetLoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      child: SizedBox(
        height: 320,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                color: AppColors.danger,
                size: 36,
              ),
              const SizedBox(height: 14),
              Text(
                'Não foi possível carregar os registros',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                key: const Key('food-record-load-retry'),
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

String _formatTime(DateTime moment) {
  final hour = moment.hour.toString().padLeft(2, '0');
  final minute = moment.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
