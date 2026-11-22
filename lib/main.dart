import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_config.dart';
import 'supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.initialize();
  runApp(const AmlakPanahApp());
}

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
        child: AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.hasSupabase) return const PropertyHomePage();
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (Supabase.instance.client.auth.currentUser != null) {
          return const PropertyHomePage();
        }
        return const SignInPage();
      },
    );
  }
}

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});
  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool isSignUp = false;
  bool busy = false;
  String? error;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    setState(() { busy = true; error = null; });
    try {
      if (isSignUp) {
        await Supabase.instance.client.auth.signUp(
          email: email.text.trim(), password: password.text,
        );
      } else {
        await Supabase.instance.client.auth.signInWithPassword(
          email: email.text.trim(), password: password.text,
        );
      }
    } on AuthException catch (e) {
      setState(() => error = e.message);
    } catch (e) {
      setState(() => error = 'خطا در ارتباط: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.home_work, size: 56, color: Color(0xFFB58A35)),
                const SizedBox(height: 12),
                const Text('املاک پناه', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(isSignUp ? 'ایجاد حساب کاربری' : 'ورود به حساب کاربری'),
                const SizedBox(height: 20),
                TextField(controller: email, keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'ایمیل', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: password, obscureText: true,
                  decoration: const InputDecoration(labelText: 'رمز عبور', border: OutlineInputBorder())),
                if (error != null) Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(error!, style: const TextStyle(color: Colors.red)),
                ),
                const SizedBox(height: 18),
                SizedBox(width: double.infinity, child: FilledButton(
                  onPressed: busy ? null : submit,
                  child: Text(busy ? 'لطفاً صبر کنید...' : (isSignUp ? 'ثبت‌نام' : 'ورود')),
                )),
                TextButton(onPressed: () => setState(() { isSignUp = !isSignUp; error = null; }),
                  child: Text(isSignUp ? 'حساب دارم؛ ورود' : 'حساب ندارم؛ ثبت‌نام')),
              ]),
            ),
          ),
        ),
      ),
    ),
  );
}

class Property {
  Property({this.id, required this.title, required this.location, required this.area,
    required this.price, required this.phone, required this.kind});
  String? id;
  String title, location, area, price, phone, kind;

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'location': location, 'area': area,
    'price': price, 'phone': phone, 'kind': kind,
  };

  factory Property.fromJson(Map<String, dynamic> json) => Property(
    id: json['id']?.toString(), title: json['title'] ?? '', location: json['location'] ?? '',
    area: json['area'] ?? '', price: json['price'] ?? '',
    phone: json['phone'] ?? '', kind: json['kind'] ?? 'آپارتمان',
  );
}

class PropertyHomePage extends StatefulWidget {
  const PropertyHomePage({super.key});
  @override
  State<PropertyHomePage> createState() => _PropertyHomePageState();
}

class _PropertyHomePageState extends State<PropertyHomePage> {
  final List<Property> _properties = [];
  final _search = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('amlak_panah_properties');
    if (saved != null) {
      try {
        final decoded = jsonDecode(saved) as List<dynamic>;
        _properties.addAll(decoded.map((item) =>
          Property.fromJson(Map<String, dynamic>.from(item))));
      } catch (_) {
        // Ignore invalid local cache and start with an empty list.
      }
    }
    if (AppConfig.hasSupabase && AmlakSupabase.currentUser != null) {
      try {
        final cloudRows = await AmlakSupabase.loadProperties();
        _properties
          ..clear()
          ..addAll(cloudRows.map((row) => Property(
            id: row['id']?.toString(),
            title: row['title']?.toString() ?? '',
            location: row['address']?.toString() ?? '',
            area: row['area']?.toString() ?? '',
            price: row['price']?.toString() ?? '',
            phone: row['phone']?.toString() ?? '',
            kind: row['property_type']?.toString() ?? 'آپارتمان',
          )));
        await _saveProperties();
      } catch (_) {
        // Keep the local copy available when cloud sync is temporarily unavailable.
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveProperties() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('amlak_panah_properties',
      jsonEncode(_properties.map((p) => p.toJson()).toList()));
  }

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
      if (AppConfig.hasSupabase && AmlakSupabase.currentUser != null) {
        try {
          final saved = await AmlakSupabase.saveProperty(
            id: property?.id,
            title: title.text.trim(), kind: kind,
            address: location.text.trim(), area: area.text.trim(),
            price: price.text.trim(), phone: phone.text.trim(),
          );
          final savedId = saved['id']?.toString();
          if (property == null && _properties.isNotEmpty) _properties.first.id = savedId;
          if (property != null) property.id = savedId;
        } catch (e) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ذخیره آنلاین انجام نشد؛ نسخه گوشی نگهداری شد: $e')));
        }
      }
      await _saveProperties();
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
          if (AppConfig.hasSupabase && AmlakSupabase.currentUser != null)
            IconButton(tooltip: 'خروج', onPressed: () => Supabase.instance.client.auth.signOut(),
              icon: const Icon(Icons.logout)),
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
            child: _loading
              ? const Center(child: CircularProgressIndicator())
              : items.isEmpty
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
                                if (v == 'delete') {
                                  setState(() => _properties.remove(p));
                                  if (p.id != null && AppConfig.hasSupabase && AmlakSupabase.currentUser != null) {
                                    AmlakSupabase.deleteProperty(p.id!).catchError((_) {});
                                  }
                                  _saveProperties();
                                }
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
