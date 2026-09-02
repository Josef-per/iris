import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris/core/navigation/iris_router.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/widgets/patient_bottom_navigation_bar.dart';

void main() {
  group('IrisRoutePath', () {
    test('interpreta rota comum e hash route da web da mesma forma', () {
      final pathRoute = IrisRoutePath.parse(
        Uri.parse('/professional/patients/paciente-1?tab=history'),
      );
      final hashRoute = IrisRoutePath.parse(
        Uri.parse('/#/professional/patients/paciente-1?tab=history'),
      );

      expect(
        pathRoute.location,
        '/professional/patients/paciente-1?tab=history',
      );
      expect(hashRoute.location, pathRoute.location);
    });

    test('parser restaura exatamente path e query normalizados', () async {
      const parser = IrisRouteInformationParser();
      final parsed = await parser.parseRouteInformation(
        RouteInformation(
          uri: Uri.parse('/#/professional/patients/paciente%2042?tab=notes'),
        ),
      );

      final restored = parser.restoreRouteInformation(parsed);

      expect(
        restored.uri.toString(),
        '/professional/patients/paciente%2042?tab=notes',
      );
    });

    test('controller notifica apenas quando a localização muda', () {
      final controller = IrisRouteController(
        IrisRoutePath(Uri(path: '/professional')),
      );
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.go('/professional');
      controller.go('/professional/notes');
      controller.restore(IrisRoutePath(Uri(path: '/professional/notes')));
      controller.restore(IrisRoutePath(Uri(path: '/professional/settings')));

      expect(notifications, 2);
      expect(controller.path.location, '/professional/settings');
    });

    test('guard impede e depois libera uma navegação solicitada', () async {
      final controller = IrisRouteController(
        IrisRoutePath(Uri(path: '/professional/settings')),
      );
      addTearDown(controller.dispose);
      var allowNavigation = false;
      var guardCalls = 0;
      final owner = Object();
      controller.setNavigationGuard(owner, (_) async {
        guardCalls++;
        return allowNavigation;
      });

      expect(
        await controller.requestNavigation('/professional/notes'),
        isFalse,
      );
      expect(controller.path.location, '/professional/settings');

      allowNavigation = true;
      expect(await controller.requestNavigation('/professional/notes'), isTrue);
      expect(controller.path.location, '/professional/notes');
      expect(guardCalls, 2);

      controller.clearNavigationGuard(owner);
      expect(await controller.requestNavigation('/professional'), isTrue);
      expect(guardCalls, 2);
    });

    test(
      'voltar sai do paciente para a lista e do destino para o dashboard',
      () async {
        final controller = IrisRouteController(
          IrisRoutePath(
            Uri.parse('/professional/patients/paciente-1?tab=notes'),
          ),
        );
        final delegate = IrisRouterDelegate(
          controller: controller,
          rootBuilder: (_) => const SizedBox.shrink(),
        );
        addTearDown(delegate.dispose);
        addTearDown(controller.dispose);

        expect(await delegate.popRoute(), isTrue);
        expect(controller.path.location, '/professional/patients');

        controller.go('/professional/settings');
        expect(await delegate.popRoute(), isTrue);
        expect(controller.path.location, '/professional');

        controller.go('/professional/patients/paciente-1/care-plan');
        expect(await delegate.popRoute(), isTrue);
        expect(controller.path.location, '/professional/patients');

        controller.go('/patient/reminders');
        expect(await delegate.popRoute(), isTrue);
        expect(controller.path.location, '/patient');

        controller.go('/patient/care-plan');
        expect(await delegate.popRoute(), isTrue);
        expect(controller.path.location, '/patient');

        controller.go('/patient/history');
        expect(await delegate.popRoute(), isTrue);
        expect(controller.path.location, '/patient');

        controller.go('/patient/profile');
        expect(await delegate.popRoute(), isTrue);
        expect(controller.path.location, '/patient');
      },
    );
  });

  group('PatientRouteLocation', () {
    test('faz parse e restore de todos os destinos do paciente', () {
      const expectations = <String, PatientDestination>{
        '/patient': PatientDestination.home,
        '/patient/reminders': PatientDestination.reminders,
        '/patient/history': PatientDestination.history,
        '/patient/care-plan': PatientDestination.carePlan,
        '/patient/support-suggestions': PatientDestination.supportSuggestions,
        '/patient/profile': PatientDestination.profile,
      };

      for (final entry in expectations.entries) {
        final route = PatientRouteLocation.tryParse(Uri.parse(entry.key));
        expect(route, isNotNull, reason: entry.key);
        expect(route!.destination, entry.value, reason: entry.key);
        expect(route.location, entry.key, reason: entry.key);

        final hashRoute = PatientRouteLocation.tryParse(
          Uri.parse('/#${entry.key}'),
        );
        expect(hashRoute, isNotNull, reason: 'hash ${entry.key}');
        expect(
          hashRoute!.destination,
          entry.value,
          reason: 'hash ${entry.key}',
        );
      }
    });

    test('normaliza subrota desconhecida para a home do paciente', () {
      final route = PatientRouteLocation.tryParse(
        Uri.parse('/patient/desconhecida'),
      );

      expect(route, isNotNull);
      expect(route!.destination, PatientDestination.home);
      expect(route.location, '/patient');
    });

    test('não interpreta workspace profissional como rota do paciente', () {
      expect(
        PatientRouteLocation.tryParse(Uri.parse('/professional/patients')),
        isNull,
      );
    });
  });

  group('PatientBottomNavigationBar', () {
    testWidgets(
      'exibe quatro destinos principais com áreas de toque adequadas',
      (tester) async {
        tester.view.physicalSize = const Size(320, 160);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        PatientDestination? selected;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              bottomNavigationBar: PatientBottomNavigationBar(
                selectedDestination: PatientDestination.carePlan,
                onDestinationSelected: (destination) {
                  selected = destination;
                },
              ),
            ),
          ),
        );

        for (final destination in const [
          PatientDestination.home,
          PatientDestination.history,
          PatientDestination.carePlan,
          PatientDestination.profile,
        ]) {
          final button = find.byKey(Key('patient-nav-${destination.name}'));
          expect(button, findsOneWidget);
          expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
        }
        expect(find.byIcon(Icons.assignment_rounded), findsOneWidget);
        expect(
          find.byKey(const Key('patient-floating-navigation')),
          findsOneWidget,
        );

        final selectedItem = tester.widget<AnimatedPhysicalModel>(
          find
              .ancestor(
                of: find.byKey(const Key('patient-nav-carePlan')),
                matching: find.byType(AnimatedPhysicalModel),
              )
              .first,
        );
        final unselectedItem = tester.widget<AnimatedPhysicalModel>(
          find
              .ancestor(
                of: find.byKey(const Key('patient-nav-home')),
                matching: find.byType(AnimatedPhysicalModel),
              )
              .first,
        );
        expect(selectedItem.color, AppTheme.light.colorScheme.primaryContainer);
        expect(selectedItem.elevation, greaterThan(0));
        expect(unselectedItem.color, Colors.transparent);
        expect(unselectedItem.elevation, 0);

        await tester.tap(find.byKey(const Key('patient-nav-profile')));
        expect(selected, PatientDestination.profile);

        await tester.tap(find.byKey(const Key('patient-nav-home')));
        expect(selected, PatientDestination.home);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('rotas de apoio e lembretes mantêm Hoje selecionado', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            bottomNavigationBar: PatientBottomNavigationBar(
              selectedDestination: PatientDestination.supportSuggestions,
              onDestinationSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.home_rounded), findsOneWidget);
      expect(find.byKey(const Key('patient-nav-reminders')), findsNothing);
    });
  });

  group('ProfessionalRouteLocation', () {
    test('faz parse e restore de todos os destinos principais', () {
      const expectations = <String, ProfessionalDestination>{
        '/professional': ProfessionalDestination.dashboard,
        '/professional/dashboard': ProfessionalDestination.dashboard,
        '/professional-preview': ProfessionalDestination.dashboard,
        '/professional/patients': ProfessionalDestination.patients,
        '/professional/notes': ProfessionalDestination.notes,
        '/professional/care-plan': ProfessionalDestination.carePlan,
        '/professional/settings': ProfessionalDestination.settings,
      };

      for (final entry in expectations.entries) {
        final route = ProfessionalRouteLocation.tryParse(Uri.parse(entry.key));

        expect(route, isNotNull, reason: entry.key);
        expect(route!.destination, entry.value, reason: entry.key);
        expect(route.patientId, isNull, reason: entry.key);
      }

      for (final destination in ProfessionalDestination.values) {
        final route = ProfessionalRouteLocation.forDestination(destination);
        final restored = ProfessionalRouteLocation.tryParse(
          Uri.parse(route.location),
        );

        expect(restored, isNotNull, reason: destination.name);
        expect(restored!.destination, destination, reason: destination.name);
      }
    });

    test('preserva paciente e abas suportadas', () {
      for (final tab in ['overview', 'history', 'notes']) {
        final route = ProfessionalRouteLocation(
          destination: ProfessionalDestination.patients,
          patientId: 'paciente 42',
          patientTab: tab,
        );

        final restored = ProfessionalRouteLocation.tryParse(
          Uri.parse(route.location),
        );

        expect(restored, isNotNull);
        expect(restored!.destination, ProfessionalDestination.patients);
        expect(restored.patientId, 'paciente 42');
        expect(restored.patientTab, tab);
        if (tab == 'overview') {
          expect(route.location, '/professional/patients/paciente%2042');
        } else {
          expect(route.location, contains('?tab=$tab'));
        }
      }
    });

    test('normaliza aba desconhecida para visão geral', () {
      final route = ProfessionalRouteLocation.tryParse(
        Uri.parse('/professional/patients/paciente-1?tab=unexpected'),
      );

      expect(route, isNotNull);
      expect(route!.patientTab, 'overview');
    });

    test('preserva rota de plano de cuidado vinculada ao paciente', () {
      const route = ProfessionalRouteLocation(
        destination: ProfessionalDestination.carePlan,
        patientId: 'paciente 42',
      );

      expect(route.location, '/professional/patients/paciente%2042/care-plan');

      final restored = ProfessionalRouteLocation.tryParse(
        Uri.parse(route.location),
      );
      expect(restored, isNotNull);
      expect(restored!.destination, ProfessionalDestination.carePlan);
      expect(restored.patientId, 'paciente 42');
    });

    test('não interpreta rotas do paciente como workspace profissional', () {
      expect(
        ProfessionalRouteLocation.tryParse(Uri.parse('/patient/reminders')),
        isNull,
      );
    });
  });
}
