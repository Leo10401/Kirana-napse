import 'package:flutter_test/flutter_test.dart';
import 'package:kirananapse/main.dart';

void main() {
  testWidgets('App renders login screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const KiranaNapseApp());
    expect(find.text('Sign In'), findsWidgets);
    expect(find.text('Kirana-Napse'), findsWidgets);
  });
}
