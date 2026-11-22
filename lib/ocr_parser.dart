class PropertyOcrParser {
  static String normalizeDigits(String input) {
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    final out = StringBuffer();
    for (final rune in input.runes) {
      final ch = String.fromCharCode(rune);
      final pi = persian.indexOf(ch);
      final ai = arabic.indexOf(ch);
      if (pi >= 0) {
        out.write(pi);
      } else if (ai >= 0) {
        out.write(ai);
      } else {
        out.write(ch);
      }
    }
    return out.toString().replaceAll('ك', 'ک').replaceAll('ي', 'ی');
  }

  static String? _number(String line) {
    final match = RegExp(r'\d[\d,٬،٫.]*').firstMatch(line);
    if (match == null) return null;
    final raw = match.group(0)!.replaceAll(RegExp(r'[,٬،]'), '').replaceAll('٫', '.');
    var number = double.tryParse(raw);
    if (number == null) return raw;
    if (line.contains('میلیارد')) number *= 1000000000;
    else if (line.contains('میلیون')) number *= 1000000;
    else if (line.contains('هزار')) number *= 1000;
    return number.round().toString();
  }

  static Map<String, String> parse(String rawText) {
    final text = normalizeDigits(rawText);
    final lines = text.split(RegExp(r'[\r\n]+')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final result = <String, String>{};
    if (lines.isNotEmpty) result['title'] = lines.first.length > 80 ? lines.first.substring(0, 80) : lines.first;

    for (final line in lines) {
      final lower = line.toLowerCase();
      final value = _number(line);
      if (value != null) {
        if ((lower.contains('متراژ') || lower.contains('مساحت') || lower.contains('زیربنا') || lower.contains('متر مربع')) && !result.containsKey('area')) {
          result['area'] = value;
        } else if ((lower.contains('ودیعه') || lower.contains('رهن')) && !result.containsKey('deposit')) {
          result['deposit'] = value;
        } else if (lower.contains('اجاره') && !result.containsKey('monthly_rent')) {
          result['monthly_rent'] = value;
        } else if ((lower.contains('سن بنا') || lower.contains('سال ساخت') || lower.contains('قدمت')) && !result.containsKey('building_age')) {
          result['building_age'] = value;
        } else if ((lower.contains('خواب') || lower.contains('اتاق')) && !result.containsKey('bedrooms')) {
          result['bedrooms'] = value;
        } else if ((lower.contains('قیمت') || lower.contains('فروش')) && !lower.contains('هر متر') && !result.containsKey('price')) {
          result['price'] = value;
        }
      }
      final phone = RegExp(r'(?:09|9)\d{9}').firstMatch(line.replaceAll(RegExp(r'[^0-9]'), ''));
      if (phone != null && !result.containsKey('phone')) result['phone'] = phone.group(0)!;
      if (!result.containsKey('property_type')) {
        if (line.contains('آپارتمان')) result['property_type'] = 'آپارتمان';
        else if (line.contains('ویلا') || line.contains('خانه')) result['property_type'] = 'خانه و ویلا';
        else if (line.contains('زمین')) result['property_type'] = 'زمین';
        else if (line.contains('مغازه')) result['property_type'] = 'مغازه';
        else if (line.contains('دفتر')) result['property_type'] = 'دفتر کار';
      }
      if (!result.containsKey('deal_type')) {
        if (line.contains('رهن کامل')) result['deal_type'] = 'رهن کامل';
        else if (line.contains('رهن') && line.contains('اجاره')) result['deal_type'] = 'رهن و اجاره';
        else if (line.contains('اجاره')) result['deal_type'] = 'اجاره';
        else if (line.contains('فروش')) result['deal_type'] = 'فروش';
      }
    }
    return result;
  }
}
