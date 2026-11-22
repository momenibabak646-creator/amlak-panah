import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:amlak_panah/main.dart';
import 'package:amlak_panah/brand_logo.dart';

void main() {
  testWidgets('sign-in screen shows Amlak Panah and login controls', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: SignInPage(),
        ),
      ),
    );

    expect(find.byType(BrandLogo), findsOneWidget);
    expect(find.text('ورود به حساب کاربری'), findsOneWidget);
    expect(find.text('ایمیل'), findsOneWidget);
    expect(find.text('رمز عبور'), findsOneWidget);
    expect(find.text('ورود'), findsOneWidget);
  });
}
