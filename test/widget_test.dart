import 'package:flutter_test/flutter_test.dart';
import 'package:amlak_panah/main.dart';

void main() {
  testWidgets('sign-in screen shows Amlak Panah and login controls', (tester) async {
    await tester.pumpWidget(const AmlakPanahApp());
    await tester.pumpAndSettle();

    expect(find.text('املاک پناه'), findsOneWidget);
    expect(find.text('ورود به حساب کاربری'), findsOneWidget);
    expect(find.text('ایمیل'), findsOneWidget);
    expect(find.text('رمز عبور'), findsOneWidget);
    expect(find.text('ورود'), findsOneWidget);
  });
}
