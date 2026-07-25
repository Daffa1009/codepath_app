import 'package:flutter_test/flutter_test.dart';
import 'package:codepath_app/main.dart';

void main() {
  testWidgets('App should build without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const CodePathApp());
    // Basic smoke test — verifikasi app bisa dirender tanpa crash
    expect(find.byType(CodePathApp), findsNothing);
  });
}
