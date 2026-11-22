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

  test('infers rent and deposit deal type across separate lines', () {
    final result = PropertyOcrParser.parse('رهن: ۳۰۰,۰۰۰,۰۰۰\nاجاره: ۱۲,۰۰۰,۰۰۰');
    expect(result['deposit'], '300000000');
    expect(result['monthly_rent'], '12000000');
    expect(result['deal_type'], 'رهن و اجاره');
  });
}
