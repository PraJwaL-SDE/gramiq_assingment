import 'package:flutter_test/flutter_test.dart';
import 'package:gramiq_clone/main.dart';
import 'dart:io';

void main() {
  setUpAll(() async {
    // Create a temporary .env file if it doesn't exist for the test
    final envFile = File('.env');
    if (!envFile.existsSync()) {
      envFile.writeAsStringSync('GEMINI_API_KEY=dummy_key');
    }
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const GramiqCloneApp());

    // Basic check to see if the app starts
    expect(find.byType(GramiqCloneApp), findsOneWidget);

    
    await tester.pump(const Duration(seconds: 5));
  });
}
