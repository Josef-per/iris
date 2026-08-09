import 'package:flutter/material.dart';
import 'package:iris/core/errors/app_error_messages.dart';
import 'package:iris/core/navigation/iris_router.dart';
import 'package:iris/features/auth/auth_service.dart';
import 'package:iris/features/patient_professional/patient_professional_repository.dart';
import 'package:iris/screens/home_screen.dart';
import 'package:iris/screens/lembretes_screen.dart';
import 'package:iris/screens/patient_care_plan_screen.dart';
import 'package:iris/screens/qr_code_screen.dart';

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
  late Future<bool> _linkCheckFuture;
  bool _isSigningOut = false;
  bool _routeNormalizationScheduled = false;
  IrisRouteController? _routeController;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _linkCheckFuture = _checkLink();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _routeController = IrisRouteScope.maybeOf(context);
    final controller = _routeController;
    if (controller == null || _routeNormalizationScheduled) {
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

  Future<bool> _checkLink() =>
      widget.linkChecker?.call() ?? _repository.hasActiveProfessionalLink();

  void _refreshLinkCheck() {
    setState(() {
      _linkCheckFuture = _checkLink();
    });
  }

  Future<void> _signOut() async {
    setState(() => _isSigningOut = true);
    try {
      await _authService.signOut();
      if (mounted) {
        final controller = _routeController;
        if (controller != null) {
          Router.neglect(context, () => controller.go('/'));
        }
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMessages.from(error))));
      setState(() => _isSigningOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _linkCheckFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            body: Center(
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
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
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
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.logout_rounded),
                      label: Text(
                        _isSigningOut ? 'Saindo...' : 'Sair e trocar de conta',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (snapshot.data == true) {
          final controller = _routeController;
          final route = controller == null
              ? PatientRouteLocation.home
              : PatientRouteLocation.tryParse(controller.path.uri) ??
                    PatientRouteLocation.home;
          return switch (route.destination) {
            PatientDestination.reminders => LembretesScreen(
              onBack: controller == null
                  ? null
                  : () => Router.neglect(
                      context,
                      () => controller.go(PatientRouteLocation.home.location),
                    ),
            ),
            PatientDestination.carePlan => PatientCarePlanScreen(
              onBack: controller == null
                  ? null
                  : () => Router.neglect(
                      context,
                      () => controller.go(PatientRouteLocation.home.location),
                    ),
            ),
            PatientDestination.home => HomeScreen(
              onOpenReminders: controller == null
                  ? null
                  : () =>
                        controller.go(PatientRouteLocation.reminders.location),
              onOpenCarePlan: controller == null
                  ? null
                  : () => controller.go(PatientRouteLocation.carePlan.location),
            ),
          };
        }

        return QrcodeScreen(onLinked: _refreshLinkCheck);
      },
    );
  }
}
