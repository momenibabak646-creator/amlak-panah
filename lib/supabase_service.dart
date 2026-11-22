import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AmlakSupabase {
  AmlakSupabase._();
  static final client = Supabase.instance.client;
  static const bucket = 'property-images';
  static User? get currentUser => client.auth.currentUser;
  static String get uid => currentUser?.id ?? (throw const AuthException('ابتدا وارد حساب شوید.'));

  static Future<Map<String,dynamic>> profile() async =>
      await client.from('profiles').select().eq('id', uid).single();

  static Future<List<Map<String,dynamic>>> list(String table,{String order='created_at'}) async {
    final rows=await client.from(table).select().order(order,ascending:false);
    return List<Map<String,dynamic>>.from(rows);
  }
  static Future<List<Map<String,dynamic>>> loadProperties() async => list('properties');
  static Future<List<Map<String,dynamic>>> loadCustomers() async => list('customers');
  static Future<List<Map<String,dynamic>>> loadFollowups() async => list('followups',order:'followup_date');
  static Future<List<Map<String,dynamic>>> loadProfiles() async => list('profiles');

  static Future<Map<String,dynamic>> saveRow(String table,Map<String,dynamic> values,{String? id}) async {
    final data={...values,'owner_id':uid};
    if(id==null) return await client.from(table).insert(data).select().single();
    data.remove('owner_id');
    return await client.from(table).update(data).eq('id',id).select().single();
  }
  static Future<void> deleteRow(String table,String id) async {
    await client.from(table).delete().eq('id',id);
  }
  static Future<Map<String,dynamic>> saveProperty({
    String? id, required String title, required String kind, required String address,
    required String area, required String price, required String phone,
    String dealType='فروش', String city='گرگان', String neighborhood='',
    String deposit='', String monthlyRent='', String bedrooms='', String buildingAge='',
    bool parking=false,bool elevator=false,bool storage=false,
    String sellerName='',String documentType='',String description='',String status='active',
  }) async {
    final n(String s)=>num.tryParse(s.replaceAll(',','').trim());
    final values=<String,dynamic>{
      'title':title,'property_type':kind,'deal_type':dealType,'transaction_type':dealType,
      'city':city,'address':address,'neighborhood':neighborhood,'area':n(area),
      'price':n(price),'deposit':n(deposit),'monthly_rent':n(monthlyRent),
      'bedrooms':int.tryParse(bedrooms),'building_age':int.tryParse(buildingAge),
      'parking':parking,'elevator':elevator,'storage':storage,'phone':phone,
      'seller_name':sellerName,'document_type':documentType,'description':description,'status':status,
      'updated_at':DateTime.now().toUtc().toIso8601String(),
    };
    if(id==null) return await client.from('properties').insert({...values,'owner_id':uid}).select().single();
    return await client.from('properties').update(values).eq('id',id).select().single();
  }
  static Future<String> uploadImage(String propertyId,XFile image) async {
    final ext=image.name.contains('.')?image.name.split('.').last:'jpg';
    final path='${uid}/$propertyId/${DateTime.now().microsecondsSinceEpoch}.$ext';
    await client.storage.from(bucket).upload(path,File(image.path));
    await client.from('property_images').insert({'property_id':propertyId,'image_url':path});
    return path;
  }
  static Future<String> createSignedImageUrl(String path)=>
      client.storage.from(bucket).createSignedUrl(path,604800);
  static Future<void> grantProperty(String propertyId,String userId) async {
    await client.from('property_access').insert({'property_id':propertyId,'user_id':userId,'granted_by':uid});
  }
  static Future<void> revokeProperty(String propertyId,String userId) async {
    await client.from('property_access').delete().eq('property_id',propertyId).eq('user_id',userId);
  }
}
