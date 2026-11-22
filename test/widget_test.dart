import 'package:flutter_test/flutter_test.dart';
import 'package:amlak_panah/main.dart';

void main() {
  testWidgets('home screen shows Amlak Panah and empty state', (tester) async {
    await tester.pumpWidget(const AmlakPanahApp());
    expect(find.text('املاک پناه'), findsOneWidget);
    expect(find.text('هنوز فایلی ثبت نشده است'), findsOneWidget);
    expect(find.text('ثبت اولین فایل'), findsOneWidget);
  });
}
