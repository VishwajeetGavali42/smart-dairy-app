import 'package:flutter_test/flutter_test.dart';
import 'package:test_app/main.dart';
import 'package:test_app/services/language_service.dart';

void main() {
  testWidgets('SmartDairyApp initializes and renders successfully', (WidgetTester tester) async {
    LanguageService.setLanguage('English');
    await tester.pumpWidget(const SmartDairyApp());
    await tester.pumpAndSettle();

    // Verify app builds without crashing
    expect(find.byType(SmartDairyApp), findsOneWidget);
  });
}
