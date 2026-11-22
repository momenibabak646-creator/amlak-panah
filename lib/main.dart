import 'package:flutter/material.dart';

void main() => runApp(const AmlakPanahApp());

class AmlakPanahApp extends StatelessWidget {
  const AmlakPanahApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'املاک پناه',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFB58A35)),
        scaffoldBackgroundColor: const Color(0xFFF7F6F2),
        fontFamily: 'Roboto',
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: PropertyHomePage(),
      ),
    );
  }
}

class Property {
  Property({required this.title, required this.location, required this.area,
    required this.price, required this.phone, required this.kind});
  String title, location, area, price, phone, kind;
}

class PropertyHomePage extends StatefulWidget {
  const PropertyHomePage({super.key});
  @override
  State<PropertyHomePage> createState() => _PropertyHomePageState();
}

class _PropertyHomePageState extends State<PropertyHomePage> {
  final List<Property> _properties = [];
  final _search = TextEditingController();

  List<Property> get _filtered => _properties.where((p) {
    final q = _search.text.trim().toLowerCase();
    return p.title.toLowerCase().contains(q) ||
        p.location.toLowerCase().contains(q) ||
        p.phone.contains(q);
  }).toList();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _editProperty([Property? property]) async {
    final title = TextEditingController(text: property?.title ?? '');
    final location = TextEditingController(text: property?.location ?? '');
    final area = TextEditingController(text: property?.area ?? '');
    final price = TextEditingController(text: property?.price ?? '');
    final phone = TextEditingController(text: property?.phone ?? '');
    String kind = property?.kind ?? 'آپارتمان';
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(property == null ? 'ثبت فایل جدید' : 'ویرایش فایل'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  DropdownButtonFormField<String>(
                    value: kind,
                    decoration: const InputDecoration(labelText: 'نوع ملک'),
                    items: ['آپارتمان', 'خانه و ویلا', 'زمین', 'مغازه', 'دفتر کار']
                        .map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                    onChanged: (v) => setDialogState(() => kind = v ?? kind),
                  ),
                  const SizedBox(height: 10),
                  _field(title, 'عنوان فایل'),
                  _field(location, 'محله یا آدرس'),
                  _field(area, 'متراژ (متر مربع)', number: true),
                  _field(price, 'قیمت (تومان)', number: true),
                  _field(phone, 'شماره تماس', number: true),
                ]),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('انصراف')),
            FilledButton(onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            }, child: const Text('ذخیره')),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() {
        if (property == null) {
          _properties.insert(0, Property(title: title.text.trim(),
            location: location.text.trim(), area: area.text.trim(),
            price: price.text.trim(), phone: phone.text.trim(), kind: kind));
        } else {
          property.title = title.text.trim();
          property.location = location.text.trim();
          property.area = area.text.trim();
          property.price = price.text.trim();
          property.phone = phone.text.trim();
          property.kind = kind;
        }
      });
    }
    title.dispose(); location.dispose(); area.dispose(); price.dispose(); phone.dispose();
  }

  Widget _field(TextEditingController controller, String label, {bool number = false}) =>
      Padding(
        padding: const EdgeInsets.only(top: 10),
        child: TextFormField(
          controller: controller,
          keyboardType: number ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
          validator: (v) => v == null || v.trim().isEmpty ? 'این قسمت را وارد کنید' : null,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    return Scaffold(
      appBar: AppBar(
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('املاک پناه', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('مدیریت فایل‌های املاک', style: TextStyle(fontSize: 12)),
        ]),
        actions: [
          IconButton(tooltip: 'افزودن فایل', onPressed: () => _editProperty(),
            icon: const Icon(Icons.add_circle_outline, size: 28)),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'جستجو بر اساس عنوان، محله یا شماره تماس',
              prefixIcon: const Icon(Icons.search),
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 18),
          Row(children: [
            const Text('فایل‌های ثبت‌شده', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Spacer(),
            Chip(label: Text('${_properties.length} فایل')),
          ]),
          const SizedBox(height: 8),
          Expanded(
            child: items.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.home_work_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(_properties.isEmpty ? 'هنوز فایلی ثبت نشده است' : 'موردی پیدا نشد',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 16)),
                  if (_properties.isEmpty) ...[
                    const SizedBox(height: 8),
                    FilledButton.icon(onPressed: () => _editProperty(),
                      icon: const Icon(Icons.add), label: const Text('ثبت اولین فایل')),
                  ],
                ]))
              : ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final p = items[index];
                    return Card(
                      color: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade200)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Container(padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: const Color(0xFFB58A35).withValues(alpha: .12),
                                borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.apartment, color: Color(0xFF9A742B))),
                            const SizedBox(width: 10),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(p.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text('${p.kind} • ${p.location}', style: TextStyle(color: Colors.grey.shade600)),
                            ])),
                            PopupMenuButton<String>(
                              onSelected: (v) {
                                if (v == 'edit') _editProperty(p);
                                if (v == 'delete') setState(() => _properties.remove(p));
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(value: 'edit', child: Text('ویرایش')),
                                PopupMenuItem(value: 'delete', child: Text('حذف')),
                              ],
                            ),
                          ]),
                          const Divider(height: 22),
                          Wrap(spacing: 18, runSpacing: 8, children: [
                            _info(Icons.square_foot, '${p.area} متر'),
                            _info(Icons.payments_outlined, '${p.price} تومان'),
                            _info(Icons.phone_outlined, p.phone),
                          ]),
                        ]),
                      ),
                    );
                  },
                ),
          ),
        ]),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editProperty(),
        icon: const Icon(Icons.add),
        label: const Text('ثبت فایل'),
      ),
    );
  }

  Widget _info(IconData icon, String value) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 17, color: Colors.grey.shade600),
    const SizedBox(width: 5),
    Text(value, style: const TextStyle(fontSize: 12)),
  ]);
}
