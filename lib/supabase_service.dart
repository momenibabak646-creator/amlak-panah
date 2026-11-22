import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
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

  static String _cacheKey(String table) => 'amlak_panah_${uid}_$table';
  static Future<void> _writeCache(String table,List<Map<String,dynamic>> rows) async {
    final prefs=await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey(table),jsonEncode(rows));
  }
  static Future<List<Map<String,dynamic>>> _readCache(String table) async {
    final prefs=await SharedPreferences.getInstance();
    final raw=prefs.getString(_cacheKey(table));
    if(raw==null)return <Map<String,dynamic>>[];
    return (jsonDecode(raw) as List).map((e)=>Map<String,dynamic>.from(e as Map)).toList();
  }
  static Future<List<Map<String,dynamic>>> list(String table,{String order='created_at'}) async {
    try {
      final rows=List<Map<String,dynamic>>.from(await client.from(table).select().order(order,ascending:false));
      await _writeCache(table,rows);
      return rows;
    } catch (_) {
      final cached=await _readCache(table);
      if(cached.isNotEmpty)return cached;
      rethrow;
    }
  }
  static Future<List<Map<String,dynamic>>> loadProperties() async => list('properties');
  static Future<List<Map<String,dynamic>>> loadCustomers() async => list('customers');
  static Future<List<Map<String,dynamic>>> loadFollowups() async => list('followups',order:'followup_date');
  static Future<List<Map<String,dynamic>>> loadProfiles() async => list('profiles');

  static Future<Map<String,dynamic>> saveRow(String table,Map<String,dynamic> values,{String? id}) async {
    final data=<String,dynamic>{...values,'owner_id':uid};
    final Map<String,dynamic> saved;
    if(id==null) {
      saved=Map<String,dynamic>.from(await client.from(table).insert(data).select().single());
    } else {
      data.remove('owner_id');
      saved=Map<String,dynamic>.from(await client.from(table).update(data).eq('id',id).select().single());
    }
    final cached=await _readCache(table);
    final index=cached.indexWhere((row)=>row['id']==saved['id']);
    if(index<0)cached.insert(0,saved);else cached[index]=saved;
    await _writeCache(table,cached);
    return saved;
  }
  static Future<void> deleteRow(String table,String id) async {
    await client.from(table).delete().eq('id',id);
    final cached=await _readCache(table);
    cached.removeWhere((row)=>row['id']==id);
    await _writeCache(table,cached);
  }
  static Future<Map<String,dynamic>> saveProperty({
    String? id, required String title, required String kind, required String address,
    required String area, required String price, required String phone,
    String dealType='فروش', String city='گرگان', String neighborhood='',
    String deposit='', String monthlyRent='', String bedrooms='', String buildingAge='',
    bool parking=false,bool elevator=false,bool storage=false,List<String> features=const [],
    String sellerName='',String documentType='',String description='',String status='active',String commissionAmount='',String consultantShare='',bool negotiable=false,
  }) async {
    num? n(String s)=>num.tryParse(s.replaceAll(',','').trim());
    final values=<String,dynamic>{
      'title':title,'property_type':kind,'deal_type':dealType,'transaction_type':dealType,
      'city':city,'address':address,'neighborhood':neighborhood,'area':n(area),
      'price':n(price),'deposit':n(deposit),'monthly_rent':n(monthlyRent),
      'bedrooms':int.tryParse(bedrooms),'building_age':int.tryParse(buildingAge),
      'parking':parking,'elevator':elevator,'storage':storage,'features':features,'phone':phone,
      'seller_name':sellerName,'document_type':documentType,'description':description,'status':status,'commission_amount':n(commissionAmount),'consultant_share':n(consultantShare),'negotiable':negotiable,
      'updated_at':DateTime.now().toUtc().toIso8601String(),
    };
    final Map<String,dynamic> saved;
    if(id==null) {
      saved=Map<String,dynamic>.from(await client.from('properties').insert({...values,'owner_id':uid,'assigned_to':uid}).select().single());
    } else {
      saved=Map<String,dynamic>.from(await client.from('properties').update(values).eq('id',id).select().single());
    }
    final cached=await _readCache('properties');
    final index=cached.indexWhere((row)=>row['id']==saved['id']);
    if(index<0)cached.insert(0,saved);else cached[index]=saved;
    await _writeCache('properties',cached);
    return saved;
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
  static Future<List<Map<String,dynamic>>> loadPropertyImages(String propertyId) async {
    final rows=List<Map<String,dynamic>>.from(await client.from('property_images').select().eq('property_id',propertyId).order('created_at'));
    final output=<Map<String,dynamic>>[];
    for(final row in rows){
      final path=(row['image_url']??row['storage_path'])?.toString()??'';
      if(path.isEmpty)continue;
      try{row['signed_url']=await createSignedImageUrl(path);output.add(row);}catch(_){}
    }
    return output;
  }
  static Future<void> deletePropertyImage(String imageId,String path) async {
    await client.storage.from(bucket).remove([path]);
    await client.from('property_images').delete().eq('id',imageId);
  }
  static Future<String> loadPrivateNote(String propertyId) async {
    final row=await client.from('property_private_notes').select('note').eq('property_id',propertyId).maybeSingle();
    return row?['note']?.toString()??'';
  }
  static Future<void> savePrivateNote(String propertyId,String note) async {
    await client.from('property_private_notes').upsert({'property_id':propertyId,'note':note,'updated_at':DateTime.now().toUtc().toIso8601String()});
  }
  static Future<List<Map<String,dynamic>>> loadPropertyAccess(String propertyId) async =>
      List<Map<String,dynamic>>.from(await client.from('property_access').select().eq('property_id',propertyId));
  static Future<void> grantProperty(String propertyId,String userId) async {
    await client.from('property_access').insert({'property_id':propertyId,'user_id':userId,'granted_by':uid});
  }
  static Future<void> revokeProperty(String propertyId,String userId) async {
    await client.from('property_access').delete().eq('property_id',propertyId).eq('user_id',userId);
  }
}
