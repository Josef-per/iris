import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('flutter_svg carrega o logotipo com a flor vetorial', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          backgroundColor: Color(0xFF3E236D),
          body: Center(
            child: SvgPicture(
              SvgAssetLoader('assets/images/Login.svg'),
              width: 270,
              height: 130,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SvgPicture), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('asset mantém a flor em geometria SVG nativa', () async {
    final source = await rootBundle.loadString('assets/images/Login.svg');
    final flower = RegExp(
      r'<g id="iris-flower-vector"[\s\S]*?</g>',
    ).firstMatch(source);

    expect(flower, isNotNull);
    expect(RegExp(r'<path ').allMatches(flower!.group(0)!), hasLength(10));
    expect(source, contains('mask="url(#mask1_377_163)" opacity="0"'));
  });
}
