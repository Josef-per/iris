import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'professional_destination.dart';

export 'professional_destination.dart';

/// A small, dependency-free router for the top-level application locations.
///
/// Authentication remains responsible for deciding which workspace a user can
/// see. The route only preserves where the user is inside that workspace so a
/// refresh, deep link, or browser back action does not discard their context.
class IrisRoutePath {
  const IrisRoutePath(this.uri);

  factory IrisRoutePath.parse(Uri uri) {
    final fragment = uri.fragment;
    if (fragment.startsWith('/')) {
      return IrisRoutePath(Uri.parse(fragment));
    }
    return IrisRoutePath(uri.path.isEmpty ? Uri(path: '/') : uri);
  }

  final Uri uri;

  String get location {
    final path = uri.path.isEmpty ? '/' : uri.path;
    final query = uri.hasQuery ? '?${uri.query}' : '';
    return '$path$query';
  }
}

typedef IrisNavigationGuard = Future<bool> Function(IrisRoutePath nextPath);

class IrisRouteController extends ChangeNotifier {
  IrisRouteController([IrisRoutePath? initialPath])
    : _path = initialPath ?? IrisRoutePath(Uri(path: '/'));

  IrisRoutePath _path;
  IrisNavigationGuard? _navigationGuard;
  Object? _navigationGuardOwner;

  IrisRoutePath get path => _path;

  void go(String location) {
    final next = IrisRoutePath.parse(Uri.parse(location));
    if (next.location == _path.location) return;
    _path = next;
    notifyListeners();
  }

  void setNavigationGuard(Object owner, IrisNavigationGuard guard) {
    _navigationGuardOwner = owner;
    _navigationGuard = guard;
  }

  void clearNavigationGuard(Object owner) {
    if (!identical(_navigationGuardOwner, owner)) return;
    _navigationGuardOwner = null;
    _navigationGuard = null;
  }

  Future<bool> requestNavigation(String location) async {
    final next = IrisRoutePath.parse(Uri.parse(location));
    return requestRestore(next);
  }

  Future<bool> requestRestore(IrisRoutePath path) async {
    if (path.location == _path.location) return true;
    final guard = _navigationGuard;
    if (guard != null && !await guard(path)) {
      // Reemite a configuração atual para restaurar a URL após um back/forward
      // do navegador que tenha sido cancelado pelo usuário.
      notifyListeners();
      return false;
    }
    _path = path;
    notifyListeners();
    return true;
  }

  void restore(IrisRoutePath path) {
    if (path.location == _path.location) return;
    _path = path;
    notifyListeners();
  }
}

class IrisRouteInformationParser extends RouteInformationParser<IrisRoutePath> {
  const IrisRouteInformationParser();

  @override
  Future<IrisRoutePath> parseRouteInformation(
    RouteInformation routeInformation,
  ) => SynchronousFuture(IrisRoutePath.parse(routeInformation.uri));

  @override
  RouteInformation restoreRouteInformation(IrisRoutePath configuration) {
    return RouteInformation(uri: Uri.parse(configuration.location));
  }
}

class IrisRouterDelegate extends RouterDelegate<IrisRoutePath>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<IrisRoutePath> {
  IrisRouterDelegate({required this.controller, required this.rootBuilder}) {
    controller.addListener(notifyListeners);
  }

  final IrisRouteController controller;
  final WidgetBuilder rootBuilder;

  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  IrisRoutePath get currentConfiguration => controller.path;

  @override
  Widget build(BuildContext context) {
    return IrisRouteScope(
      controller: controller,
      child: Navigator(
        key: navigatorKey,
        onGenerateRoute: (settings) =>
            MaterialPageRoute<void>(settings: settings, builder: rootBuilder),
      ),
    );
  }

  @override
  Future<void> setNewRoutePath(IrisRoutePath configuration) async {
    await controller.requestRestore(configuration);
  }

  @override
  Future<bool> popRoute() async {
    final professional = ProfessionalRouteLocation.tryParse(
      controller.path.uri,
    );
    if (professional != null) {
      if (professional.patientId != null) {
        await controller.requestNavigation(
          ProfessionalRouteLocation.patients.location,
        );
        return true;
      }
      if (professional.destination != ProfessionalDestination.dashboard) {
        await controller.requestNavigation(
          ProfessionalRouteLocation.dashboard.location,
        );
        return true;
      }
    }
    final patient = PatientRouteLocation.tryParse(controller.path.uri);
    if (patient != null && patient.destination != PatientDestination.home) {
      await controller.requestNavigation(PatientRouteLocation.home.location);
      return true;
    }
    return super.popRoute();
  }

  @override
  void dispose() {
    controller.removeListener(notifyListeners);
    super.dispose();
  }
}

class IrisRouteScope extends InheritedNotifier<IrisRouteController> {
  const IrisRouteScope({
    super.key,
    required IrisRouteController controller,
    required super.child,
  }) : super(notifier: controller);

  static IrisRouteController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<IrisRouteScope>();
    assert(scope != null, 'IrisRouteScope is missing above this context.');
    return scope!.notifier!;
  }

  static IrisRouteController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<IrisRouteScope>()
        ?.notifier;
  }
}

enum PatientDestination { home, reminders, carePlan, supportSuggestions }

class PatientRouteLocation {
  const PatientRouteLocation(this.destination);

  final PatientDestination destination;

  static const home = PatientRouteLocation(PatientDestination.home);
  static const reminders = PatientRouteLocation(PatientDestination.reminders);
  static const carePlan = PatientRouteLocation(PatientDestination.carePlan);
  static const supportSuggestions = PatientRouteLocation(
    PatientDestination.supportSuggestions,
  );

  String get location => switch (destination) {
    PatientDestination.home => '/patient',
    PatientDestination.reminders => '/patient/reminders',
    PatientDestination.carePlan => '/patient/care-plan',
    PatientDestination.supportSuggestions => '/patient/support-suggestions',
  };

  static PatientRouteLocation? tryParse(Uri rawUri) {
    final uri = IrisRoutePath.parse(rawUri).uri;
    final segments = uri.pathSegments;
    if (segments.isEmpty || segments.first != 'patient') return null;
    if (segments.length == 1) return home;
    return switch (segments[1]) {
      'reminders' => reminders,
      'care-plan' => carePlan,
      'support-suggestions' => supportSuggestions,
      _ => home,
    };
  }
}

class ProfessionalRouteLocation {
  const ProfessionalRouteLocation({
    required this.destination,
    this.patientId,
    this.patientTab = 'overview',
  });

  final ProfessionalDestination destination;
  final String? patientId;
  final String patientTab;

  static const dashboard = ProfessionalRouteLocation(
    destination: ProfessionalDestination.dashboard,
  );
  static const patients = ProfessionalRouteLocation(
    destination: ProfessionalDestination.patients,
  );

  String get location {
    if (patientId case final id?) {
      final encodedId = Uri.encodeComponent(id);
      if (destination == ProfessionalDestination.carePlan) {
        return '/professional/patients/$encodedId/care-plan';
      }
      final query = patientTab == 'overview' ? '' : '?tab=$patientTab';
      return '/professional/patients/$encodedId$query';
    }
    return switch (destination) {
      ProfessionalDestination.dashboard => '/professional',
      ProfessionalDestination.patients => '/professional/patients',
      ProfessionalDestination.notes => '/professional/notes',
      ProfessionalDestination.carePlan => '/professional/care-plan',
      ProfessionalDestination.settings => '/professional/settings',
    };
  }

  static ProfessionalRouteLocation? tryParse(Uri rawUri) {
    final uri = IrisRoutePath.parse(rawUri).uri;
    final segments = uri.pathSegments;
    if (uri.path == '/professional-preview') return dashboard;
    if (segments.isEmpty || segments.first != 'professional') return null;
    if (segments.length == 1 || segments[1] == 'dashboard') return dashboard;
    return switch (segments[1]) {
      'patients' =>
        segments.length >= 4 && segments.last == 'care-plan'
            ? ProfessionalRouteLocation(
                destination: ProfessionalDestination.carePlan,
                patientId: segments[2],
              )
            : ProfessionalRouteLocation(
                destination: ProfessionalDestination.patients,
                patientId: segments.length >= 3 ? segments[2] : null,
                patientTab: _safePatientTab(uri.queryParameters['tab']),
              ),
      'notes' => const ProfessionalRouteLocation(
        destination: ProfessionalDestination.notes,
      ),
      'care-plan' => const ProfessionalRouteLocation(
        destination: ProfessionalDestination.carePlan,
      ),
      'settings' => const ProfessionalRouteLocation(
        destination: ProfessionalDestination.settings,
      ),
      _ => dashboard,
    };
  }

  static ProfessionalRouteLocation forDestination(
    ProfessionalDestination destination,
  ) => ProfessionalRouteLocation(destination: destination);

  static String _safePatientTab(String? value) {
    if (value == 'history' || value == 'notes') return value!;
    return 'overview';
  }
}
