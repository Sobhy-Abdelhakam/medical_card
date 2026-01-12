// Basic Flutter widget test for Euro Medical Card app
import 'package:flutter_test/flutter_test.dart';
import 'package:euro_medical_card/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const EuroMedicalCardApp());

    // Verify that the app builds without errors
    await tester.pumpAndSettle();
  });
}
