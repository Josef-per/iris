import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris/core/theme/app_theme.dart';

void main() {
  group('identidade e tokens do redesign', () {
    test('preserva a paleta cromática original', () {
      expect(AppColors.ink, const Color(0xFF28174E));
      expect(AppColors.deepPurple, const Color(0xFF462A7E));
      expect(AppColors.purple, const Color(0xFF7D6AC6));
      expect(AppColors.lavender, const Color(0xFFDBCFFF));
      expect(AppColors.porcelain, const Color(0xFFFAF9F6));
      expect(AppColors.success, const Color(0xFF3D7A55));
      expect(AppColors.danger, const Color(0xFFB94352));
      expect(AppColors.brandGradient.colors, [
        AppColors.purpleAccessible,
        AppColors.deepPurple,
        AppColors.ink,
      ]);
    });

    test('mantém escala pequena e reutilizável de raios e elevações', () {
      expect({AppRadius.sm, AppRadius.md, AppRadius.lg}, {12.0, 16.0, 20.0});
      expect(AppRadius.circular, 999);
      expect(AppElevation.none, 0);
      expect(AppElevation.floating, 2);
      expect(AppElevation.modal, 6);
      expect(AppSize.minimumTapTarget, 44);
      expect(AppSize.controlHeight, greaterThanOrEqualTo(44));
    });
  });

  group('contraste WCAG AA', () {
    test('pares principais do tema claro atingem contraste para texto', () {
      final colors = AppTheme.light.colorScheme;

      _expectTextContrast(colors.onPrimary, colors.primary, 'primary');
      _expectTextContrast(colors.onSecondary, colors.secondary, 'secondary');
      _expectTextContrast(colors.onSurface, colors.surface, 'surface');
      _expectTextContrast(
        colors.onSurfaceVariant,
        colors.surface,
        'surface variant',
      );
      _expectTextContrast(colors.onError, colors.error, 'error');
      _expectTextContrast(
        colors.onPrimaryContainer,
        colors.primaryContainer,
        'primary container',
      );
      _expectTextContrast(
        colors.onErrorContainer,
        colors.errorContainer,
        'error container',
      );
    });

    test('pares semânticos claros atingem contraste para texto', () {
      final colors = AppTheme.light.extension<AppSemanticColors>()!;

      _expectTextContrast(colors.onSuccess, colors.success, 'success');
      _expectTextContrast(
        colors.onSuccessContainer,
        colors.successContainer,
        'success container',
      );
      _expectTextContrast(colors.onWarning, colors.warning, 'warning');
      _expectTextContrast(
        colors.onWarningContainer,
        colors.warningContainer,
        'warning container',
      );
      _expectTextContrast(colors.onInfo, colors.info, 'info');
      _expectTextContrast(
        colors.onInfoContainer,
        colors.infoContainer,
        'info container',
      );
    });

    test('pares principais e semânticos escuros mantêm contraste', () {
      final scheme = AppTheme.dark.colorScheme;
      final semantic = AppTheme.dark.extension<AppSemanticColors>()!;

      _expectTextContrast(scheme.onPrimary, scheme.primary, 'dark primary');
      _expectTextContrast(scheme.onSurface, scheme.surface, 'dark surface');
      _expectTextContrast(
        scheme.onSurfaceVariant,
        scheme.surface,
        'dark surface variant',
      );
      _expectTextContrast(scheme.onError, scheme.error, 'dark error');
      _expectTextContrast(semantic.onSuccess, semantic.success, 'dark success');
      _expectTextContrast(
        semantic.onSuccessContainer,
        semantic.successContainer,
        'dark success container',
      );
      _expectTextContrast(semantic.onWarning, semantic.warning, 'dark warning');
      _expectTextContrast(
        semantic.onWarningContainer,
        semantic.warningContainer,
        'dark warning container',
      );
      _expectTextContrast(semantic.onInfo, semantic.info, 'dark info');
      _expectTextContrast(
        semantic.onInfoContainer,
        semantic.infoContainer,
        'dark info container',
      );
    });
  });

  testWidgets('controles globais renderizam alvos de pelo menos 44 por 44', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FilledButton(
                  key: const Key('filled'),
                  onPressed: () {},
                  child: const Text('Filled'),
                ),
                OutlinedButton(
                  key: const Key('outlined'),
                  onPressed: () {},
                  child: const Text('Outlined'),
                ),
                TextButton(
                  key: const Key('text'),
                  onPressed: () {},
                  child: const Text('Text'),
                ),
                IconButton(
                  key: const Key('icon'),
                  tooltip: 'Ação',
                  onPressed: () {},
                  icon: const Icon(Icons.add_rounded),
                ),
                const SizedBox(
                  width: 220,
                  child: TextField(
                    key: Key('field'),
                    decoration: InputDecoration(labelText: 'Campo'),
                  ),
                ),
                Switch(
                  key: const Key('switch'),
                  value: true,
                  onChanged: (_) {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final key in [
      'filled',
      'outlined',
      'text',
      'icon',
      'field',
      'switch',
    ]) {
      final size = tester.getSize(find.byKey(Key(key)));
      expect(
        size.width,
        greaterThanOrEqualTo(AppSize.minimumTapTarget),
        reason: '$key deve ter largura clicável suficiente',
      );
      expect(
        size.height,
        greaterThanOrEqualTo(AppSize.minimumTapTarget),
        reason: '$key deve ter altura clicável suficiente',
      );
    }

    expect(AppTheme.light.materialTapTargetSize, MaterialTapTargetSize.padded);
    expect(tester.takeException(), isNull);
  });
}

void _expectTextContrast(Color foreground, Color background, String role) {
  final ratio = _contrastRatio(foreground, background);
  expect(
    ratio,
    greaterThanOrEqualTo(4.5),
    reason: '$role tem contraste ${ratio.toStringAsFixed(2)}:1',
  );
}

double _contrastRatio(Color first, Color second) {
  final firstLuminance = first.computeLuminance();
  final secondLuminance = second.computeLuminance();
  final lighter = firstLuminance > secondLuminance
      ? firstLuminance
      : secondLuminance;
  final darker = firstLuminance > secondLuminance
      ? secondLuminance
      : firstLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}
