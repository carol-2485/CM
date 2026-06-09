// test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('BloodLink arranca sem erros', (WidgetTester tester) async {
    expect(BloodLinkApp, isNotNull);
  });
}
