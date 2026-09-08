import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/professional/presentation/professional_invite_dialog.dart';
import 'package:iris/features/professional/professional_repository.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  for (final size in [
    const Size(1200, 800),
    const Size(320, 568),
    const Size(568, 320),
  ]) {
    testWidgets('convite carrega e pode ser revogado em $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final pending = Completer<ProfessionalLinkInvite>();
      String? revoked;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => ProfessionalInviteDialog(
                    createInvite: () => pending.future,
                    revokeInvite: (id) async => revoked = id,
                  ),
                ),
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      pending.complete(
        ProfessionalLinkInvite(
          id: 'invite-id',
          token: 'token',
          payload: 'iris://invite/token',
          expiresAt: DateTime(2026, 9, 8, 15),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(QrImageView), findsOneWidget);
      await tester.ensureVisible(find.text('Revogar convite'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Revogar convite'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(revoked, 'invite-id');
      expect(find.byType(AlertDialog), findsNothing);
    });
  }
}
