import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iris/core/errors/app_error_messages.dart';
import 'package:iris/core/navigation/iris_router.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/auth/auth_service.dart';
import 'package:iris/features/professional/data/supabase_professional_workspace_backend.dart';
import 'package:iris/features/professional/presentation/professional_clinical_workspace_view.dart';
import 'package:iris/features/professional/presentation/professional_dashboard_view.dart';
import 'package:iris/features/professional/presentation/professional_frontend_store.dart';
import 'package:iris/features/professional/presentation/professional_models.dart';
import 'package:iris/features/professional/presentation/professional_patient_detail_view.dart';
import 'package:iris/features/professional/presentation/professional_patients_view.dart';
import 'package:iris/features/professional/presentation/professional_settings_view.dart';
import 'package:iris/features/professional/presentation/professional_shared_widgets.dart';
import 'package:iris/features/professional/professional_repository.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ProfessionalHomeScreen extends StatefulWidget {
  const ProfessionalHomeScreen({super.key, this.backend});

  final ProfessionalWorkspaceBackend? backend;

  @override
  State<ProfessionalHomeScreen> createState() => _ProfessionalHomeScreenState();
}

class _ProfessionalHomeScreenState extends State<ProfessionalHomeScreen>
    with WidgetsBindingObserver {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _authService = AuthService();
  final _professionalRepository = ProfessionalRepository();
  late final ProfessionalFrontendStore _store;

  ProfessionalDestination _destination = ProfessionalDestination.dashboard;
  ProfessionalPatient? _selectedPatient;
  ProfessionalPatient? _detailPatient;
  IrisRouteController? _routeController;
  String? _routePatientId;
  String _routePatientTab = 'overview';
  bool _routeNormalizationScheduled = false;
  bool _invalidPatientRouteScheduled = false;
  bool _hasUnsavedChanges = false;
  bool _discardDialogVisible = false;
  late ProfessionalSettingsDraft _lastRenderedSettings;

  bool get _credentialLocked => _store.settings.credentialStatus != 'ativo';
  int get _notificationCount => _store.alerts;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _store = ProfessionalFrontendStore.connected(
      widget.backend ?? SupabaseProfessionalWorkspaceBackend(),
    );

    if (_store.patients.isNotEmpty) {
      _selectedPatient = _store.patients[0];
    }
    _lastRenderedSettings = _store.settings;
    _store.addListener(_syncSelectedPatient);
    unawaited(_loadWorkspace());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _routeController?.clearNavigationGuard(this);
    _store.removeListener(_syncSelectedPatient);
    _store.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextRouteController = IrisRouteScope.maybeOf(context);
    if (!identical(_routeController, nextRouteController)) {
      _routeController?.clearNavigationGuard(this);
      _routeController = nextRouteController;
      _routeController?.setNavigationGuard(this, _confirmRouteChange);
    }
    final route = _routeController == null
        ? null
        : ProfessionalRouteLocation.tryParse(_routeController!.path.uri);
    if (route == null) {
      _destination = ProfessionalDestination.dashboard;
      _routePatientId = null;
      _routePatientTab = 'overview';
      _detailPatient = null;
      if (_routeController != null && !_routeNormalizationScheduled) {
        _routeNormalizationScheduled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _routeNormalizationScheduled = false;
          if (mounted) {
            Router.neglect(
              context,
              () => _routeController?.go(
                ProfessionalRouteLocation.dashboard.location,
              ),
            );
          }
        });
      }
      return;
    }

    if (_routeController!.path.location != route.location &&
        !_routeNormalizationScheduled) {
      _routeNormalizationScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _routeNormalizationScheduled = false;
        if (mounted) {
          Router.neglect(context, () => _routeController?.go(route.location));
        }
      });
    }

    _destination = route.destination;
    _routePatientId = route.patientId;
    _routePatientTab = route.patientTab;
    if (route.patientId == null) {
      _detailPatient = null;
    } else {
      final routePatient = _patientById(route.patientId!);
      _selectedPatient = routePatient ?? _selectedPatient;
      _detailPatient = route.destination == ProfessionalDestination.patients
          ? routePatient
          : null;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_loadWorkspace());
    }
  }

  Future<void> _loadWorkspace() async {
    try {
      await _store.initialize();
    } catch (_) {
      // O erro fica disponível no store e é exibido com opção de tentar de novo.
    }
  }

  void _syncSelectedPatient() {
    if (!mounted) return;
    final settingsChanged = !identical(_lastRenderedSettings, _store.settings);
    _lastRenderedSettings = _store.settings;
    if (_store.patients.isEmpty) {
      if (_selectedPatient != null ||
          _detailPatient != null ||
          settingsChanged) {
        setState(() {
          _selectedPatient = null;
          _detailPatient = null;
        });
      }
      return;
    }

    final selectedId = _routePatientId ?? _selectedPatient?.id;
    final detailId = _destination == ProfessionalDestination.patients
        ? (_routePatientId ?? _detailPatient?.id)
        : null;
    ProfessionalPatient? selected;
    ProfessionalPatient? detail;
    for (final patient in _store.patients) {
      if (patient.id == selectedId) selected = patient;
      if (patient.id == detailId) detail = patient;
    }
    if (_routePatientId != null &&
        selected == null &&
        !_store.isLoading &&
        _store.loadError == null &&
        !_invalidPatientRouteScheduled) {
      _invalidPatientRouteScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _invalidPatientRouteScheduled = false;
        if (!mounted) return;
        final fallback = _destination == ProfessionalDestination.carePlan
            ? ProfessionalRouteLocation.forDestination(
                ProfessionalDestination.carePlan,
              )
            : ProfessionalRouteLocation.patients;
        _routeController?.go(fallback.location);
      });
    }
    final nextSelected = selected ?? _store.patients[0];
    if (identical(nextSelected, _selectedPatient) &&
        identical(detail, _detailPatient) &&
        !settingsChanged) {
      return;
    }
    setState(() {
      _selectedPatient = nextSelected;
      _detailPatient = detail;
    });
  }

  void _selectDestination(ProfessionalDestination destination) {
    unawaited(_selectDestinationGuarded(destination));
  }

  void _selectClinicalDestination(ProfessionalDestination destination) {
    assert(
      destination == ProfessionalDestination.carePlan ||
          destination == ProfessionalDestination.notes,
    );
    _hideTransientFeedback();
    final route =
        destination == ProfessionalDestination.carePlan &&
            _selectedPatient != null
        ? ProfessionalRouteLocation(
            destination: destination,
            patientId: _selectedPatient!.id,
          )
        : ProfessionalRouteLocation.forDestination(destination);
    final controller = _routeController;
    if (controller != null) {
      controller.go(route.location);
      return;
    }
    setState(() {
      _destination = destination;
      _routePatientId = route.patientId;
      _detailPatient = null;
    });
  }

  Future<void> _selectDestinationGuarded(
    ProfessionalDestination destination,
  ) async {
    _hideTransientFeedback();
    final route =
        destination == ProfessionalDestination.carePlan &&
            _selectedPatient != null
        ? ProfessionalRouteLocation(
            destination: destination,
            patientId: _selectedPatient!.id,
          )
        : ProfessionalRouteLocation.forDestination(destination);
    final navigated = await _requestNavigation(
      route,
      fallback: () {
        setState(() {
          _destination = destination;
          _routePatientId = null;
          _routePatientTab = 'overview';
          _detailPatient = null;
        });
      },
    );
    if (!navigated || !mounted) return;
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  void _openPatient(ProfessionalPatient patient) {
    unawaited(_openPatientGuarded(patient));
  }

  Future<void> _openPatientGuarded(ProfessionalPatient patient) async {
    _hideTransientFeedback();
    final route = ProfessionalRouteLocation(
      destination: ProfessionalDestination.patients,
      patientId: patient.id,
    );
    final navigated = await _requestNavigation(
      route,
      fallback: () {
        setState(() {
          _selectedPatient = patient;
          _routePatientId = patient.id;
          _detailPatient = patient;
          _destination = ProfessionalDestination.patients;
        });
      },
    );
    if (navigated && mounted && _routeController != null) {
      _selectedPatient = patient;
    }
  }

  void _openCarePlan([ProfessionalPatient? patient]) {
    unawaited(_openCarePlanGuarded(patient));
  }

  Future<void> _openCarePlanGuarded([ProfessionalPatient? patient]) async {
    final targetPatient = patient ?? _selectedPatient;
    if (targetPatient != null && targetPatient.status != PatientStatus.active) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ative o acompanhamento para editar o plano de cuidado.',
          ),
        ),
      );
      return;
    }
    final selected = patient ?? _selectedPatient;
    if (selected == null) {
      await _selectDestinationGuarded(ProfessionalDestination.carePlan);
      return;
    }
    final route = ProfessionalRouteLocation(
      destination: ProfessionalDestination.carePlan,
      patientId: selected.id,
    );
    final navigated = await _requestNavigation(
      route,
      fallback: () {
        setState(() {
          _selectedPatient = selected;
          _destination = ProfessionalDestination.carePlan;
          _routePatientId = selected.id;
          _detailPatient = null;
        });
      },
    );
    if (navigated && mounted && _routeController != null) {
      _selectedPatient = selected;
    }
  }

  Future<void> _signOut() async {
    final hadUnsavedChanges = _hasUnsavedChanges;
    if (!await _confirmDiscardChanges() || !mounted) return;
    try {
      await _authService.signOut();
      if (_routeController != null && mounted) {
        Router.neglect(context, () => _routeController?.go('/'));
      }
    } catch (error) {
      if (!mounted) return;
      if (hadUnsavedChanges) {
        setState(() => _hasUnsavedChanges = true);
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMessages.from(error))));
    }
  }

  ProfessionalPatient? _patientById(String id) {
    for (final patient in _store.patients) {
      if (patient.id == id) return patient;
    }
    return null;
  }

  void _hideTransientFeedback() {
    ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
  }

  void _handleDirtyChanged(bool dirty) {
    if (!mounted || _hasUnsavedChanges == dirty) return;
    setState(() => _hasUnsavedChanges = dirty);
  }

  Future<bool> _confirmRouteChange(IrisRoutePath nextPath) {
    final nextRoute = ProfessionalRouteLocation.tryParse(nextPath.uri);
    if (_isClinicalDestination(_destination) &&
        nextRoute != null &&
        _isClinicalDestination(nextRoute.destination)) {
      return Future.value(true);
    }
    return _confirmDiscardChanges();
  }

  Future<bool> _confirmDiscardChanges() async {
    if (!_hasUnsavedChanges) return true;
    if (!mounted) return false;
    if (_store.isSaving) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Aguarde o salvamento antes de sair desta tela.'),
          ),
        );
      return false;
    }
    if (_discardDialogVisible) return false;
    _discardDialogVisible = true;
    final discard =
        await showDialog<bool>(
          context: context,
          useRootNavigator: false,
          barrierDismissible: false,
          builder: (dialogContext) => ProfessionalResponsiveDialog(
            title: 'Descartar alterações?',
            maxWidth: 440,
            content: const Text(
              'Há alterações que ainda não foram salvas. Se você sair agora, elas serão perdidas.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Continuar editando'),
              ),
              FilledButton(
                key: const Key('professional-discard-changes'),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(dialogContext).colorScheme.error,
                  foregroundColor: Theme.of(dialogContext).colorScheme.onError,
                ),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Descartar'),
              ),
            ],
          ),
        ) ??
        false;
    _discardDialogVisible = false;
    if (discard && mounted) {
      setState(() => _hasUnsavedChanges = false);
    }
    return discard;
  }

  Future<bool> _requestNavigation(
    ProfessionalRouteLocation route, {
    required VoidCallback fallback,
  }) async {
    final controller = _routeController;
    if (controller != null) {
      return controller.requestNavigation(route.location);
    }
    if (!await _confirmDiscardChanges() || !mounted) return false;
    fallback();
    return true;
  }

  Future<void> _showInvitePatient() async {
    if (_credentialLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'O QR Code será liberado quando seu cadastro profissional estiver ativo.',
          ),
        ),
      );
      return;
    }
    await showDialog<void>(
      context: context,
      useRootNavigator: false,
      builder: (context) => _ProfessionalInviteDialog(
        createInvite: _professionalRepository.createLinkInvite,
        revokeInvite: _professionalRepository.revokeLinkInvite,
      ),
    );
    if (mounted) await _loadWorkspace();
  }

  Future<void> _showNotifications() async {
    final remoteAlerts = _store.alerts;
    final clinicalAlerts = [..._store.clinicalAlerts];
    await showDialog<void>(
      context: context,
      useRootNavigator: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Notificações'),
        content: SizedBox(
          width: 440,
          child: remoteAlerts == 0
              ? const Text('Nenhum alerta no momento.')
              : clinicalAlerts.isEmpty
              ? ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.warning_amber_rounded),
                  title: Text(
                    '$remoteAlerts ${remoteAlerts == 1 ? 'alerta clínico requer' : 'alertas clínicos requerem'} revisão.',
                  ),
                  subtitle: const Text(
                    'Atualize o painel para consultar os registros.',
                  ),
                )
              : ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 420),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: clinicalAlerts.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final alert = clinicalAlerts[index];
                      final patient = _store.patientByIdOrNull(alert.patientId);
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.warning_amber_rounded),
                        title: Text(patient?.name ?? 'Paciente'),
                        subtitle: Text(
                          '${alert.summary}\n${_formatAlertDate(alert.occurredAt)}',
                        ),
                        isThreeLine: true,
                        trailing: patient == null
                            ? null
                            : const Icon(Icons.chevron_right_rounded),
                        onTap: patient == null
                            ? null
                            : () {
                                Navigator.pop(dialogContext);
                                _openPatient(patient);
                              },
                      );
                    },
                  ),
                ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  String _formatAlertDate(DateTime date) {
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year} às '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final desktop =
        MediaQuery.sizeOf(context).width >= AppBreakpoint.persistentNavigation;
    final navigation = ProfessionalNavigation(
      destination: _destination,
      showingPatientDetail: _detailPatient != null,
      onSelected: _selectDestination,
      onSignOut: _signOut,
      settings: _store.settings,
    );

    return Scaffold(
      key: _scaffoldKey,
      drawer: desktop ? null : Drawer(width: 292, child: navigation),
      body: Row(
        children: [
          if (desktop) SizedBox(width: 280, child: navigation),
          Expanded(
            child: Column(
              children: [
                if (!desktop)
                  _MobileProfessionalBar(
                    title: _pageTitle,
                    notificationCount: _notificationCount,
                    onMenuPressed: () =>
                        _scaffoldKey.currentState?.openDrawer(),
                    onNotificationsPressed: _showNotifications,
                  ),
                Expanded(
                  child: ListenableBuilder(
                    listenable: _store,
                    builder: (context, _) {
                      final error = _store.loadError;
                      late final Widget content;
                      if (_store.isLoading) {
                        content = const _ProfessionalWorkspaceLoading();
                      } else if (error != null) {
                        content = _ProfessionalWorkspaceError(
                          message: AppErrorMessages.from(error),
                          onRetry: _loadWorkspace,
                        );
                      } else {
                        content = AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          layoutBuilder: (currentChild, previousChildren) =>
                              Stack(
                                alignment: Alignment.topCenter,
                                children: [...previousChildren, ?currentChild],
                              ),
                          child: KeyedSubtree(
                            key: ValueKey(_workspaceContentKey),
                            child: _currentView,
                          ),
                        );
                      }

                      return Column(
                        children: [
                          if (!_store.isLoading &&
                              error == null &&
                              _credentialLocked)
                            _ProfessionalCredentialBanner(
                              status: _store.settings.credentialStatus,
                              onOpenSettings: () => _selectDestination(
                                ProfessionalDestination.settings,
                              ),
                            ),
                          if (_store.isSaving)
                            Semantics(
                              liveRegion: true,
                              label: 'Salvando alterações',
                              child: const LinearProgressIndicator(
                                minHeight: 3,
                              ),
                            ),
                          Expanded(child: content),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _pageTitle {
    if (_detailPatient != null) return _detailPatient!.name;
    return switch (_destination) {
      ProfessionalDestination.dashboard => 'Visão geral',
      ProfessionalDestination.patients => 'Pacientes',
      ProfessionalDestination.notes ||
      ProfessionalDestination.carePlan => 'Acompanhamento clínico',
      ProfessionalDestination.settings => 'Configurações',
    };
  }

  String get _workspaceContentKey {
    final destinationKey =
        _destination == ProfessionalDestination.notes ||
            _destination == ProfessionalDestination.carePlan
        ? 'clinical'
        : _destination.name;
    return '$destinationKey-${_detailPatient?.id ?? 'list'}';
  }

  Widget get _currentView {
    if (_store.settings.credentialStatus != 'ativo' &&
        _destination != ProfessionalDestination.settings) {
      return _ProfessionalCredentialPending(
        status: _store.settings.credentialStatus,
        onOpenSettings: () =>
            _selectDestination(ProfessionalDestination.settings),
      );
    }
    final detailPatient = _detailPatient;
    if (detailPatient != null) {
      return ProfessionalPatientDetailView(
        store: _store,
        patient: detailPatient,
        onBack: () {
          final controller = _routeController;
          if (controller == null) {
            _selectDestination(ProfessionalDestination.patients);
            return;
          }
          _hideTransientFeedback();
          Router.neglect(
            context,
            () => controller.go(ProfessionalRouteLocation.patients.location),
          );
        },
        onOpenCarePlan: () => _openCarePlan(detailPatient),
        initialTab: _routePatientTab,
        onTabChanged: (tab) {
          final controller = _routeController;
          if (controller == null) return;
          controller.go(
            ProfessionalRouteLocation(
              destination: ProfessionalDestination.patients,
              patientId: detailPatient.id,
              patientTab: tab,
            ).location,
          );
        },
      );
    }

    if (_destination == ProfessionalDestination.notes ||
        _destination == ProfessionalDestination.carePlan) {
      return ProfessionalClinicalWorkspaceView(
        store: _store,
        activeDestination: _destination,
        initialPatient: _selectedPatient,
        onDestinationChanged: _selectClinicalDestination,
        onOpenPatient: _openPatient,
        onPatientChanged: _openCarePlan,
        onDirtyChanged: _handleDirtyChanged,
      );
    }

    return switch (_destination) {
      ProfessionalDestination.dashboard => ProfessionalDashboardView(
        store: _store,
        onOpenPatients: () =>
            _selectDestination(ProfessionalDestination.patients),
        onOpenPatient: _openPatient,
        onOpenAlerts: _showNotifications,
      ),
      ProfessionalDestination.patients => ProfessionalPatientsView(
        store: _store,
        onOpenPatient: _openPatient,
        onInvitePatient: _showInvitePatient,
      ),
      ProfessionalDestination.notes || ProfessionalDestination.carePlan =>
        throw StateError('Destinos clínicos são tratados antes do switch.'),
      ProfessionalDestination.settings => ProfessionalSettingsView(
        store: _store,
        onDirtyChanged: _handleDirtyChanged,
      ),
    };
  }
}

bool _isClinicalDestination(ProfessionalDestination destination) {
  return destination == ProfessionalDestination.notes ||
      destination == ProfessionalDestination.carePlan;
}

class _ProfessionalCredentialPending extends StatelessWidget {
  const _ProfessionalCredentialPending({
    required this.status,
    required this.onOpenSettings,
  });

  final String status;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final rejected = status == 'rejeitado';
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.verified_user_outlined,
                size: 58,
                color: AppColors.purple,
              ),
              const SizedBox(height: 18),
              Text(
                rejected ? 'Cadastro requer revisão' : 'Cadastro em análise',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              Text(
                rejected
                    ? 'Revise os dados profissionais antes de solicitar uma nova análise.'
                    : 'Confirme seus dados profissionais. O painel e o QR Code serão liberados após o credenciamento.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: onOpenSettings,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Revisar cadastro'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfessionalWorkspaceLoading extends StatelessWidget {
  const _ProfessionalWorkspaceLoading();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        liveRegion: true,
        label: 'Carregando área profissional',
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Carregando área profissional...'),
          ],
        ),
      ),
    );
  }
}

class _ProfessionalCredentialBanner extends StatelessWidget {
  const _ProfessionalCredentialBanner({
    required this.status,
    required this.onOpenSettings,
  });

  final String status;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final rejected = status == 'rejeitado';
    final semanticColors = AppSemanticColors.of(context);
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: rejected ? colors.errorContainer : semanticColors.warningContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            Icon(
              rejected
                  ? Icons.error_outline_rounded
                  : Icons.pending_actions_outlined,
              color: rejected
                  ? colors.onErrorContainer
                  : semanticColors.onWarningContainer,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                rejected
                    ? 'Seu cadastro profissional precisa ser revisado. Atualize seus dados para solicitar uma nova análise.'
                    : 'Seu cadastro profissional está em análise. Pacientes e recursos clínicos serão liberados após a aprovação.',
              ),
            ),
            const SizedBox(width: 10),
            TextButton(
              onPressed: onOpenSettings,
              child: const Text('Ver perfil'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfessionalWorkspaceError extends StatelessWidget {
  const _ProfessionalWorkspaceError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 52,
                color: AppColors.danger,
              ),
              const SizedBox(height: 16),
              Text(
                'Não foi possível carregar seus dados',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton.icon(
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

class _ProfessionalInviteDialog extends StatefulWidget {
  const _ProfessionalInviteDialog({
    required this.createInvite,
    required this.revokeInvite,
  });

  final Future<ProfessionalLinkInvite> Function() createInvite;
  final Future<void> Function(String inviteId) revokeInvite;

  @override
  State<_ProfessionalInviteDialog> createState() =>
      _ProfessionalInviteDialogState();
}

class _ProfessionalInviteDialogState extends State<_ProfessionalInviteDialog> {
  late Future<ProfessionalLinkInvite> _inviteFuture;
  bool _revoking = false;

  @override
  void initState() {
    super.initState();
    _inviteFuture = widget.createInvite();
  }

  void _retry() {
    setState(() => _inviteFuture = widget.createInvite());
  }

  Future<void> _revoke(ProfessionalLinkInvite invite) async {
    if (_revoking) return;
    setState(() => _revoking = true);
    try {
      await widget.revokeInvite(invite.id);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Convite revogado.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _revoking = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMessages.from(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Vincular paciente'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380, minHeight: 260),
        child: FutureBuilder<ProfessionalLinkInvite>(
          future: _inviteFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 42,
                    color: AppColors.danger,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    AppErrorMessages.from(snapshot.error!),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  FilledButton.tonalIcon(
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Tentar novamente'),
                  ),
                ],
              );
            }

            final invite = snapshot.data!;
            final hour = invite.expiresAt.hour.toString().padLeft(2, '0');
            final minute = invite.expiresAt.minute.toString().padLeft(2, '0');
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Peça ao paciente para escanear o QR Code.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.lavender),
                  ),
                  child: QrImageView(
                    data: invite.payload,
                    size: 210,
                    backgroundColor: AppColors.white,
                    eyeStyle: const QrEyeStyle(color: AppColors.ink),
                    dataModuleStyle: const QrDataModuleStyle(
                      color: AppColors.ink,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Válido até $hour:$minute',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: invite.payload),
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Código copiado.')),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Copiar código'),
                ),
                OutlinedButton.icon(
                  onPressed: _revoking ? null : () => _revoke(invite),
                  icon: _revoking
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.block_rounded),
                  label: Text(_revoking ? 'Revogando...' : 'Revogar convite'),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: _revoking ? null : () => Navigator.pop(context),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}

class ProfessionalNavigation extends StatelessWidget {
  const ProfessionalNavigation({
    super.key,
    required this.destination,
    required this.showingPatientDetail,
    required this.onSelected,
    required this.onSignOut,
    required this.settings,
  });

  final ProfessionalDestination destination;
  final bool showingPatientDetail;
  final ValueChanged<ProfessionalDestination> onSelected;
  final VoidCallback onSignOut;
  final ProfessionalSettingsDraft settings;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.brandGradient),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: SvgPicture.asset(
                          'assets/images/Login.svg',
                          height: 92,
                          fit: BoxFit.contain,
                          semanticsLabel: 'Íris',
                        ),
                      ),
                      const SizedBox(height: 14),
                      Divider(color: AppColors.white.withValues(alpha: .2)),
                      const SizedBox(height: 22),
                      _NavigationItem(
                        icon: Icons.dashboard_outlined,
                        selectedIcon: Icons.dashboard_rounded,
                        label: 'Visão geral',
                        selected:
                            destination == ProfessionalDestination.dashboard &&
                            !showingPatientDetail,
                        onTap: () =>
                            onSelected(ProfessionalDestination.dashboard),
                      ),
                      _NavigationItem(
                        icon: Icons.people_alt_outlined,
                        selectedIcon: Icons.people_alt_rounded,
                        label: 'Pacientes',
                        selected:
                            destination == ProfessionalDestination.patients ||
                            showingPatientDetail,
                        onTap: () =>
                            onSelected(ProfessionalDestination.patients),
                      ),
                      _NavigationItem(
                        icon: Icons.medical_information_outlined,
                        selectedIcon: Icons.medical_information_rounded,
                        label: 'Acompanhamento clínico',
                        selected:
                            destination == ProfessionalDestination.notes ||
                            destination == ProfessionalDestination.carePlan,
                        onTap: () => onSelected(
                          destination == ProfessionalDestination.notes ||
                                  destination ==
                                      ProfessionalDestination.carePlan
                              ? destination
                              : ProfessionalDestination.carePlan,
                        ),
                      ),
                      _NavigationItem(
                        icon: Icons.settings_outlined,
                        selectedIcon: Icons.settings_rounded,
                        label: 'Configurações',
                        selected:
                            destination == ProfessionalDestination.settings,
                        onTap: () =>
                            onSelected(ProfessionalDestination.settings),
                      ),
                      const Spacer(),
                      Divider(color: AppColors.white.withValues(alpha: .2)),
                      const SizedBox(height: 14),
                      _ProfessionalIdentity(settings: settings),
                      const SizedBox(height: 14),
                      Divider(color: AppColors.white.withValues(alpha: .2)),
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: onSignOut,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.lavender,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                        ),
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Sair'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        excludeSemantics: true,
        child: Material(
          color: selected
              ? AppColors.white.withValues(alpha: .15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    selected ? selectedIcon : icon,
                    color: AppColors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfessionalIdentity extends StatelessWidget {
  const _ProfessionalIdentity({required this.settings});

  final ProfessionalSettingsDraft settings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.purple.withValues(alpha: .2),
            child: const Icon(
              Icons.person_outline_rounded,
              color: AppColors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  settings.name.isEmpty ? 'Profissional' : settings.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  settings.specialty.isEmpty
                      ? 'Profissional'
                      : settings.specialty,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.lavender,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileProfessionalBar extends StatelessWidget {
  const _MobileProfessionalBar({
    required this.title,
    required this.notificationCount,
    required this.onMenuPressed,
    required this.onNotificationsPressed,
  });

  final String title;
  final int notificationCount;
  final VoidCallback onMenuPressed;
  final VoidCallback onNotificationsPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const Key('professional-mobile-bar'),
      color: Theme.of(context).colorScheme.surface,
      elevation: 1,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              IconButton(
                tooltip: 'Abrir menu',
                onPressed: onMenuPressed,
                icon: const Icon(Icons.menu_rounded),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Notificações',
                onPressed: onNotificationsPressed,
                icon: Badge(
                  isLabelVisible: notificationCount > 0,
                  label: Text('$notificationCount'),
                  child: const Icon(Icons.notifications_none_rounded),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}
