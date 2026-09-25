import 'package:flutter_test/flutter_test.dart';
import 'package:simpan_nota/main.dart';

void main() {
  testWidgets('App starts on AuthScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    expect(find.text('SimpanNota'), findsWidgets);
  });
}
