import 'package:flutter_test/flutter_test.dart';
import 'package:simpan_nota/app.dart';

void main() {
  testWidgets('App starts on LoginScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    expect(find.text('Masuk'), findsWidgets);
  });
}
