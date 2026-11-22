import 'package:flutter_test/flutter_test.dart';
import 'package:amlak_panah/ocr_parser.dart';

void main() {
  test('normalizes Persian digits and extracts property fields', () {
    final result = PropertyOcrParser.parse('''
آپارتمان دوخوابه برای فروش
متراژ: ۸۵ متر
قیمت: ۵,۸۰۰,۰۰۰,۰۰۰
تلفن: ۰۹۱۲۳۴۵۶۷۸۹
''');
    expect(result['area'], '85');
    expect(result['price'], '5800000000');
    expect(result['phone'], '09123456789');
    expect(result['property_type'], 'آپارتمان');
    expect(result['deal_type'], 'فروش');
  });

  test('extracts rent and deposit separately', () {
    final result = PropertyOcrParser.parse('رهن: ۳۰۰,۰۰۰,۰۰۰\nاجاره: ۱۲,۰۰۰,۰۰۰');
    expect(result['deposit'], '300000000');
    expect(result['monthly_rent'], '12000000');
  });

  test('normalizes Arabic digits and reads billion price units', () {
    final result = PropertyOcrParser.parse('قیمت: ۵.۸ میلیارد تومان\nتلفن: ٠٩١٢٣٤٥٦٧٨٩');
    expect(result['price'], '5800000000');
    expect(result['phone'], '09123456789');
  });

  test('detects full deposit when no monthly rent is present', () {
    final result = PropertyOcrParser.parse('ودیعه: ۴۵۰ میلیون تومان');
    expect(result['deposit'], '450000000');
    expect(result['deal_type'], 'رهن کامل');
  });

  test('infers rent and deposit deal type across separate lines', () {
    final result = PropertyOcrParser.parse('رهن: ۳۰۰,۰۰۰,۰۰۰\nاجاره: ۱۲,۰۰۰,۰۰۰');
    expect(result['deposit'], '300000000');
    expect(result['monthly_rent'], '12000000');
    expect(result['deal_type'], 'رهن و اجاره');
  });
}
