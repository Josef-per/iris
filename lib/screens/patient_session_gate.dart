import 'dart:async';

import 'package:flutter/material.dart';
import 'package:iris/core/errors/app_error_messages.dart';
import 'package:iris/core/navigation/iris_router.dart';
import 'package:iris/features/auth/auth_service.dart';
import 'package:iris/features/ai_support/data/ai_support_settings_repository.dart';
import 'package:iris/features/ai_support/data/ai_support_signal_repository.dart';
import 'package:iris/features/ai_support/data/ai_support_suggestion_repository.dart';
import 'package:iris/features/ai_support/data/ai_support_event_repository.dart';
import 'package:iris/features/ai_support/data/mock_ai_support_store.dart';
import 'package:iris/features/ai_support/data/remote_ai_recommender.dart';
import 'package:iris/features/ai_support/notifications/flutter_local_support_notification_gateway.dart';
import 'package:iris/features/ai_support/presentation/ai_support_hub_screen.dart';
import 'package:iris/features/emotional_diary/emotional_diary_repository.dart';
import 'package:iris/features/patient_professional/patient_professional_repository.dart';
import 'package:iris/screens/home_screen.dart';
import 'package:iris/screens/lembretes_screen.dart';
import 'package:iris/screens/patient_care_plan_screen.dart';
import 'package:iris/screens/patient_history_screen.dart';
import 'package:iris/screens/patient_profile_screen.dart';
import 'package:iris/screens/qr_code_screen.dart';
import 'package:iris/widgets/patient_bottom_navigation_bar.dart';

class PatientSessionGate extends StatefulWidget {
  const PatientSessionGate({super.key, this.authService, this.linkChecker});

  final AuthService? authService;
  final Future<bool> Function()? linkChecker;

  @override
  State<PatientSessionGate> createState() => _PatientSessionGateState();
}

class _PatientSessionGateState extends State<PatientSessionGate> {
  final _repository = PatientProfessionalRepository();
  late final AuthService _authService;
  late final MockAiSupportStore _aiSupportStore;
  late Future<bool> _linkCheckFuture;
  bool _isSigningOut = false;
  bool _routeNormalizationScheduled = false;
  bool _supportNotificationPending = false;
  IrisRouteController? _routeController;
  PatientDestination _localDestination = PatientDestination.home;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    final emotionalDiary = EmotionalDiaryRepository();
    _aiSupportStore = MockAiSupportStore(
      isDemonstration: false,
      signalDataSource: AiSupportSignalRepository(
        emotionalDiary: emotionalDiary,
      ),
      settingsDataSource: SupabaseAiSupportSettingsRepository(),
      eventDataSource: SupabaseAiSupportEventRepository(),
      suggestionDataSource: SupabaseAiSupportSuggestionRepository(),
      remoteRecommender: SupabaseAiSupportRemoteRecommender(),
      notificationGateway: FlutterLocalSupportNotificationGateway(),
      notificationOpenHandler: _handleSupportNotificationOpen,
    );
    _linkCheckFuture = _bootstrap();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _routeController = IrisRouteScope.maybeOf(context);
    final controller = _routeController;
    if (controller == null || _routeNormalizationScheduled) {
      return;
    }
    if (_supportNotificationPending) {
      _supportNotificationPending = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Router.neglect(
          context,
          () => controller.go(PatientRouteLocation.supportSuggestions.location),
        );
      });
      return;
    }
    final route = PatientRouteLocation.tryParse(controller.path.uri);
    final canonical = route?.location ?? PatientRouteLocation.home.location;
    if (controller.path.location == canonical) return;
    _routeNormalizationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _routeNormalizationScheduled = false;
      if (!mounted) return;
      Router.neglect(context, () => controller.go(canonical));
    });
  }

  @override
  void dispose() {
    _aiSupportStore.dispose();
    super.dispose();
  }

  Future<bool> _checkLink() =>
      widget.linkChecker?.call() ?? _repository.hasActiveProfessionalLink();

  Future<bool> _bootstrap() async {
    // Sugestões são apoio opcional e nunca podem bloquear a entrada clínica.
    unawaited(_aiSupportStore.initialize());
    return _checkLink();
  }

  void _handleSupportNotificationOpen(String _) {
    if (!mounted) return;
    final controller = _routeController;
    if (controller == null) {
      _supportNotificationPending = true;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Router.neglect(
        context,
        () => controller.go(PatientRouteLocation.supportSuggestions.location),
      );
    });
  }

  void _refreshLinkCheck() {
    setState(() {
      _linkCheckFuture = _checkLink();
    });
  }

  Future<void> _signOut() async {
    setState(() => _isSigningOut = true);
    try {
      await _performSignOut();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMessages.from(error))));
      setState(() => _isSigningOut = false);
    }
  }

  Future<void> _performSignOut() async {
    await _authService.signOut();
    if (!mounted) return;
    final controller = _routeController;
    if (controller != null) {
      Router.neglect(context, () => controller.go('/'));
    }
  }

  void _openDestination(PatientDestination destination) {
    final controller = _routeController;
    if (controller == null) {
      if (_localDestination == destination) return;
      setState(() => _localDestination = destination);
      return;
    }
    controller.go(PatientRouteLocation(destination).location);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _linkCheckFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Semantics(
                    liveRegion: true,
                    label: 'Verificando vínculo profissional',
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Verificando seu vínculo...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Não foi possível verificar seu vínculo com o profissional.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _isSigningOut ? null : _refreshLinkCheck,
                        child: const Text('Tentar novamente'),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _isSigningOut ? null : _signOut,
                        icon: _isSigningOut
                            ? const SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.logout_rounded),
                        label: Text(
                          _isSigningOut
                              ? 'Saindo...'
                              : 'Sair e trocar de conta',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        if (snapshot.data == true) {
          final controller = _routeController;
          final route = controller == null
              ? PatientRouteLocation(_localDestination)
              : PatientRouteLocation.tryParse(controller.path.uri) ??
                    PatientRouteLocation.home;
          final content = switch (route.destination) {
            PatientDestination.reminders => LembretesScreen(
              embeddedInNavigationShell: true,
            ),
            PatientDestination.history => PatientHistoryScreen(
              embeddedInNavigationShell: true,
            ),
            PatientDestination.carePlan => PatientCarePlanScreen(
              embeddedInNavigationShell: true,
            ),
            PatientDestination.supportSuggestions => AiSupportHubScreen(
              store: _aiSupportStore,
              onBack: () => _openDestination(PatientDestination.home),
            ),
            PatientDestination.profile => PatientProfileScreen(
              onSignOut: _performSignOut,
              embeddedInNavigationShell: true,
            ),
            PatientDestination.home => HomeScreen(
              aiSupportStore: _aiSupportStore,
              onOpenReminders: () =>
                  _openDestination(PatientDestination.reminders),
              onOpenSupportSuggestions: () =>
                  _openDestination(PatientDestination.supportSuggestions),
            ),
          };
          return LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 1000) {
                return Scaffold(
                  body: Row(
                    children: [
                      PatientNavigationRail(
                        selectedDestination: route.destination,
                        onDestinationSelected: _openDestination,
                      ),
                      VerticalDivider(
                        width: 1,
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      Expanded(child: content),
                    ],
                  ),
                );
              }

              return Scaffold(
                key: const Key('patient-navigation-shell'),
                body: content,
                bottomNavigationBar: SafeArea(
                  top: false,
                  minimum: const EdgeInsets.fromLTRB(12, 6, 12, 10),
                  child: Center(
                    heightFactor: 1,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: PatientBottomNavigationBar(
                        selectedDestination: route.destination,
                        onDestinationSelected: _openDestination,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }

        return QrcodeScreen(onLinked: _refreshLinkCheck);
      },
    );
  }
}
