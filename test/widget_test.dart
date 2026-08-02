import 'package:flutter_test/flutter_test.dart';
import 'package:iris/main.dart';
import 'package:iris/screens/login_screen.dart';

void main() {
  testWidgets('abre o login depois da splash sem configuracao do Supabase', (
    tester,
  ) async {
    await tester.pumpWidget(const IrisApp());

    await tester.pump(const Duration(milliseconds: 1250));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Ainda não tem uma conta?'), findsOneWidget);
  });
}
