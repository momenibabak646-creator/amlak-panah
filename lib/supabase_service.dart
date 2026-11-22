import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AmlakSupabase {
  AmlakSupabase._();
  static final client = Supabase.instance.client;
  static const bucket = 'property-images';

  static User? get currentUser => client.auth.currentUser;

  static Future<List<Map<String, dynamic>>> loadProperties() async {
    final user = currentUser;
    if (user == null) return [];
    final rows = await client.from('properties').select(
      'id,title,property_type,address,area,price,phone,created_at'
    ).eq('user_id', user.id).order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  static Future<Map<String, dynamic>> saveProperty({
    String? id,
    required String title,
    required String kind,
    required String address,
    required String area,
    required String price,
    required String phone,
  }) async {
    final user = currentUser;
    if (user == null) throw const AuthException('ابتدا وارد حساب کاربری شوید.');
    final values = <String, dynamic>{
      'user_id': user.id,
      'title': title,
      'property_type': kind,
      'address': address,
      'area': num.tryParse(area.replaceAll(',', '')),
      'price': num.tryParse(price.replaceAll(',', '')),
      'phone': phone,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (id == null) {
      return await client.from('properties').insert(values).select().single();
    }
    return await client.from('properties').update(values).eq('id', id).select().single();
  }

  static Future<void> deleteProperty(String id) async {
    await client.from('properties').delete().eq('id', id);
  }

  static Future<String> uploadImage(String propertyId, XFile image) async {
    final user = currentUser;
    if (user == null) throw const AuthException('ابتدا وارد حساب کاربری شوید.');
    final extension = image.name.contains('.') ? image.name.split('.').last : 'jpg';
    final path = '${user.id}/$propertyId/${DateTime.now().microsecondsSinceEpoch}.$extension';
    await client.storage.from(bucket).upload(path, File(image.path));
    return path;
  }

  static Future<String> createSignedImageUrl(String path) =>
      client.storage.from(bucket).createSignedUrl(path, 60 * 60 * 24 * 7);
}
