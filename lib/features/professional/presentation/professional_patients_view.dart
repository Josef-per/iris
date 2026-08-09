import 'package:flutter/material.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/professional/presentation/professional_form_dialogs.dart';
import 'package:iris/features/professional/presentation/professional_frontend_store.dart';
import 'package:iris/features/professional/presentation/professional_models.dart';
import 'package:iris/features/professional/presentation/professional_shared_widgets.dart';

enum _PatientFilter { all, active, inactive }

class ProfessionalPatientsView extends StatefulWidget {
  const ProfessionalPatientsView({
    super.key,
    required this.store,
    required this.onOpenPatient,
    required this.onInvitePatient,
  });

  final ProfessionalFrontendStore store;
  final ValueChanged<ProfessionalPatient> onOpenPatient;
  final VoidCallback onInvitePatient;

  @override
  State<ProfessionalPatientsView> createState() =>
      _ProfessionalPatientsViewState();
}

class _ProfessionalPatientsViewState extends State<ProfessionalPatientsView> {
  final _searchController = TextEditingController();
  final _busyPatientIds = <String>{};
  _PatientFilter _filter = _PatientFilter.all;
  var _refreshing = false;

  bool get _canManage =>
      !widget.store.isConnected ||
      widget.store.settings.credentialStatus == 'ativo';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ProfessionalPatient> get _filteredPatients {
    final query = _searchController.text.trim().toLowerCase();
    return widget.store.patients.where((patient) {
      final matchesQuery =
          query.isEmpty ||
          patient.name.toLowerCase().contains(query) ||
          patient.diagnosis.toLowerCase().contains(query);
      final matchesStatus = switch (_filter) {
        _PatientFilter.all => true,
        _PatientFilter.active => patient.status == PatientStatus.active,
        _PatientFilter.inactive => patient.status == PatientStatus.inactive,
      };
      return matchesQuery && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final patients = _filteredPatients;
    return SingleChildScrollView(
      child: Column(
        children: [
          ProfessionalGradientHeader(
            title: 'Meus pacientes',
            subtitle: '${widget.store.patients.length} pacientes',
            action: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (widget.store.isConnected)
                  OutlinedButton.icon(
                    onPressed: _refreshing ? null : _refresh,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.white,
                      disabledForegroundColor: AppColors.white,
                      side: const BorderSide(color: AppColors.white),
                    ),
                    icon: _refreshing
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : const Icon(Icons.refresh_rounded),
                    label: Text(_refreshing ? 'Atualizando...' : 'Atualizar'),
                  ),
                if (!widget.store.isConnected)
                  OutlinedButton.icon(
                    onPressed: widget.onInvitePatient,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.white,
                      side: const BorderSide(color: AppColors.white),
                    ),
                    icon: const Icon(Icons.qr_code_rounded),
                    label: const Text('QR Code'),
                  ),
                FilledButton.icon(
                  key: const Key('professional-add-patient'),
                  onPressed: !_canManage ? null : _addPatient,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.deepPurple,
                  ),
                  icon: Icon(
                    widget.store.isConnected
                        ? Icons.qr_code_rounded
                        : Icons.add_rounded,
                  ),
                  label: Text(
                    widget.store.isConnected
                        ? 'Vincular paciente'
                        : 'Novo paciente',
                  ),
                ),
              ],
            ),
          ),
          ProfessionalPage(
            paddingTop: 22,
            child: Column(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 760;
                    final search = TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Buscar por nome ou diagnóstico',
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
                    );
                    final filters = Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        _FilterButton(
                          label: 'Todos',
                          selected: _filter == _PatientFilter.all,
                          onTap: () =>
                              setState(() => _filter = _PatientFilter.all),
                        ),
                        _FilterButton(
                          label: 'Ativos',
                          selected: _filter == _PatientFilter.active,
                          onTap: () =>
                              setState(() => _filter = _PatientFilter.active),
                        ),
                        _FilterButton(
                          label: 'Inativos',
                          selected: _filter == _PatientFilter.inactive,
                          onTap: () =>
                              setState(() => _filter = _PatientFilter.inactive),
                        ),
                      ],
                    );
                    if (!wide) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          search,
                          const SizedBox(height: AppSpacing.sm),
                          filters,
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: search),
                        const SizedBox(width: AppSpacing.md),
                        filters,
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                if (patients.isEmpty)
                  _NoPatientsFound(
                    filtered:
                        _filter != _PatientFilter.all ||
                        _searchController.text.trim().isNotEmpty,
                    canInvite:
                        widget.store.isConnected &&
                        _canManage &&
                        widget.store.patients.isEmpty &&
                        _searchController.text.trim().isEmpty,
                    canCreate:
                        !widget.store.isConnected &&
                        _canManage &&
                        widget.store.patients.isEmpty,
                    onInvite: widget.onInvitePatient,
                    onCreate: _addPatient,
                    onReset: _clearFilters,
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 820;
                      return ProfessionalListSurface(
                        children: [
                          if (wide) const _PatientListHeader(),
                          ...patients.map(
                            (patient) => _PatientRow(
                              patient: patient,
                              compact: !wide,
                              busy: _busyPatientIds.contains(patient.id),
                              onTap: () => widget.onOpenPatient(patient),
                              onEdit: () => _editPatient(patient),
                              onToggleStatus: () =>
                                  _togglePatientStatus(patient),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    try {
      await widget.store.initialize();
    } catch (error) {
      if (mounted) showProfessionalOperationError(context, error);
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() => _filter = _PatientFilter.all);
  }

  Future<void> _addPatient() async {
    if (widget.store.isConnected) {
      widget.onInvitePatient();
      return;
    }
    final saved = await showProfessionalPatientForm(context, widget.store);
    if (!saved || !mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Paciente adicionado.')));
  }

  Future<void> _editPatient(ProfessionalPatient patient) async {
    final saved = await showProfessionalPatientForm(
      context,
      widget.store,
      patient: patient,
    );
    if (!saved || !mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Paciente atualizado.')));
  }

  Future<void> _togglePatientStatus(ProfessionalPatient patient) async {
    if (_busyPatientIds.contains(patient.id)) return;
    setState(() => _busyPatientIds.add(patient.id));
    try {
      await widget.store.updatePatient(
        patient.copyWith(
          status: patient.status == PatientStatus.active
              ? PatientStatus.inactive
              : PatientStatus.active,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              patient.status == PatientStatus.active
                  ? 'Acompanhamento inativado.'
                  : 'Acompanhamento ativado.',
            ),
          ),
        );
    } catch (error) {
      if (mounted) showProfessionalOperationError(context, error);
    } finally {
      if (mounted) setState(() => _busyPatientIds.remove(patient.id));
    }
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSize.minimumTapTarget),
        child: FilterChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
          showCheckmark: false,
          backgroundColor: colors.surfaceContainerHighest,
          selectedColor: colors.primaryContainer,
          labelStyle: TextStyle(
            color: selected
                ? colors.onPrimaryContainer
                : colors.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _PatientListHeader extends StatelessWidget {
  const _PatientListHeader();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium;
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Expanded(flex: 4, child: Text('Paciente', style: style)),
            const SizedBox(width: AppSpacing.md),
            Expanded(flex: 3, child: Text('Diagnóstico', style: style)),
            const SizedBox(width: AppSpacing.md),
            Expanded(flex: 2, child: Text('Último registro', style: style)),
            const SizedBox(width: AppSpacing.md),
            SizedBox(width: 190, child: Text('Estado', style: style)),
            const SizedBox(width: AppSize.minimumTapTarget),
          ],
        ),
      ),
    );
  }
}

class _PatientRow extends StatelessWidget {
  const _PatientRow({
    required this.patient,
    required this.compact,
    required this.busy,
    required this.onTap,
    required this.onEdit,
    required this.onToggleStatus,
  });

  final ProfessionalPatient patient;
  final bool compact;
  final bool busy;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = compact
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PatientAvatar(patient: patient, size: 48),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(patient.name, style: theme.textTheme.titleMedium),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          '${patient.age} anos · ${patient.diagnosis}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  _PatientActions(
                    patient: patient,
                    busy: busy,
                    onEdit: onEdit,
                    onToggleStatus: onToggleStatus,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _MoodBadge(mood: patient.mood),
                  PatientStatusBadge(status: patient.status),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Text(
                        patient.lastActivity,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          )
        : Row(
            children: [
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    PatientAvatar(patient: patient, size: 48),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patient.name,
                            style: theme.textTheme.titleMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${patient.age} anos',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                flex: 3,
                child: Text(
                  patient.diagnosis,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                flex: 2,
                child: Text(
                  patient.lastActivity,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              SizedBox(
                width: 190,
                child: Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _MoodBadge(mood: patient.mood),
                    PatientStatusBadge(status: patient.status),
                  ],
                ),
              ),
              _PatientActions(
                patient: patient,
                busy: busy,
                onEdit: onEdit,
                onToggleStatus: onToggleStatus,
              ),
            ],
          );

    return Semantics(
      button: true,
      label: 'Abrir paciente ${patient.name}',
      child: InkWell(
        onTap: busy ? null : onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? AppSpacing.md : AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: content,
        ),
      ),
    );
  }
}

enum _PatientAction { edit, toggleStatus }

class _PatientActions extends StatelessWidget {
  const _PatientActions({
    required this.patient,
    required this.busy,
    required this.onEdit,
    required this.onToggleStatus,
  });

  final ProfessionalPatient patient;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;

  @override
  Widget build(BuildContext context) {
    if (busy) {
      return const SizedBox.square(
        dimension: AppSize.minimumTapTarget,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return PopupMenuButton<_PatientAction>(
      tooltip: 'Ações do paciente',
      onSelected: (action) {
        switch (action) {
          case _PatientAction.edit:
            onEdit();
          case _PatientAction.toggleStatus:
            onToggleStatus();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: _PatientAction.edit,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.edit_outlined),
            title: Text('Editar'),
          ),
        ),
        PopupMenuItem(
          value: _PatientAction.toggleStatus,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              patient.status == PatientStatus.active
                  ? Icons.pause_circle_outline_rounded
                  : Icons.play_circle_outline_rounded,
            ),
            title: Text(
              patient.status == PatientStatus.active ? 'Inativar' : 'Ativar',
            ),
          ),
        ),
      ],
      icon: Icon(
        Icons.more_vert_rounded,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _MoodBadge extends StatelessWidget {
  const _MoodBadge({required this.mood});

  final String mood;

  @override
  Widget build(BuildContext context) {
    final positive = mood == 'Bem' || mood == 'Muito bem';
    final colors = Theme.of(context).colorScheme;
    final semantic = AppSemanticColors.of(context);
    final background = positive
        ? semantic.successContainer
        : mood == 'Mal'
        ? colors.errorContainer
        : semantic.warningContainer;
    final foreground = positive
        ? semantic.onSuccessContainer
        : mood == 'Mal'
        ? colors.onErrorContainer
        : semantic.onWarningContainer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            positive
                ? Icons.sentiment_satisfied_alt_rounded
                : mood == 'Mal'
                ? Icons.sentiment_dissatisfied_rounded
                : Icons.sentiment_neutral_rounded,
            size: 16,
            color: foreground,
          ),
          const SizedBox(width: 5),
          Text(
            mood,
            style: TextStyle(
              color: foreground,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoPatientsFound extends StatelessWidget {
  const _NoPatientsFound({
    required this.filtered,
    required this.canInvite,
    required this.canCreate,
    required this.onInvite,
    required this.onCreate,
    required this.onReset,
  });

  final bool filtered;
  final bool canInvite;
  final bool canCreate;
  final VoidCallback onInvite;
  final VoidCallback onCreate;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return ProfessionalEmptyState(
      icon: filtered
          ? Icons.person_search_outlined
          : Icons.people_outline_rounded,
      title: filtered
          ? 'Nenhum resultado com estes filtros'
          : canInvite
          ? 'Nenhum paciente vinculado'
          : 'Nenhum paciente cadastrado',
      message: filtered
          ? 'Altere a busca ou limpe os filtros para ver todos os pacientes.'
          : canInvite
          ? 'Gere um QR Code para o paciente concluir o vínculo.'
          : canCreate
          ? 'Cadastre o primeiro paciente para iniciar o acompanhamento.'
          : 'Os pacientes disponíveis aparecerão aqui.',
      action: filtered
          ? FilledButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.filter_alt_off_outlined),
              label: const Text('Limpar filtros'),
            )
          : canInvite
          ? FilledButton.icon(
              onPressed: onInvite,
              icon: const Icon(Icons.qr_code_rounded),
              label: const Text('Gerar QR Code'),
            )
          : canCreate
          ? FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text('Novo paciente'),
            )
          : null,
    );
  }
}
