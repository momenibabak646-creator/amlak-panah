import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'supabase_service.dart';

const gold = Color(0xFFB58A35);
const kinds = ['آپارتمان','خانه و ویلا','زمین','مغازه','دفتر کار'];
const deals = ['فروش','رهن و اجاره','رهن کامل','اجاره'];
String money(dynamic v) => v == null ? '—' : '${v.toString()} تومان';

class AppPages {
  static const titles = ['داشبورد','فایل‌های ملک','مشتریان','پیگیری‌ها','گزارش‌ها','کاربران'];
  static const icons = [Icons.dashboard_outlined,Icons.home_work_outlined,Icons.people_alt_outlined,Icons.event_note_outlined,Icons.analytics_outlined,Icons.manage_accounts_outlined];
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override State<DashboardPage> createState()=>_DashboardPageState();
}
class _DashboardPageState extends State<DashboardPage>{
  int properties=0,customers=0,followups=0; bool loading=true;
  @override void initState(){super.initState();load();}
  Future<void> load()async{try{final a=await AmlakSupabase.loadProperties();final b=await AmlakSupabase.loadCustomers();final c=await AmlakSupabase.loadFollowups();if(mounted)setState((){properties=a.length;customers=b.length;followups=c.length;loading=false;});}catch(_){if(mounted)setState(()=>loading=false);}}
  @override Widget build(BuildContext context)=>RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.all(16),children:[
    const Text('خوش آمدید',style:TextStyle(fontSize:23,fontWeight:FontWeight.bold)),const SizedBox(height:5),const Text('نمای کلی دفتر املاک پناه'),
    const SizedBox(height:18),if(loading)const LinearProgressIndicator(),
    Wrap(spacing:10,runSpacing:10,children:[
      _stat('کل فایل‌ها',properties,Icons.home_work),_stat('مشتریان',customers,Icons.people),_stat('پیگیری‌ها',followups,Icons.event_note),
    ]),
    const SizedBox(height:20),const Card(child:Padding(padding:EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('مدیریت یکپارچه املاک پناه',style:TextStyle(fontWeight:FontWeight.bold,fontSize:17)),SizedBox(height:8),Text('از نوار پایین برای مدیریت فایل‌ها، مشتریان، پیگیری‌ها، گزارش‌ها و کاربران استفاده کنید. اطلاعات پس از ورود به حساب در فضای ابری ذخیره می‌شوند.')]))),
  ]));
  Widget _stat(String title,int value,IconData icon)=>SizedBox(width:MediaQuery.sizeOf(context).width/2-22,child:Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(icon,color:gold,size:28),const SizedBox(height:10),Text('$value',style:const TextStyle(fontSize:25,fontWeight:FontWeight.bold)),Text(title)]))));
}

class PropertiesPage extends StatefulWidget {
  const PropertiesPage({super.key});
  @override State<PropertiesPage> createState()=>_PropertiesPageState();
}
class _PropertiesPageState extends State<PropertiesPage>{
  List<Map<String,dynamic>> rows=[]; bool loading=true; String query='',deal='همه',kind='همه'; final minPrice=TextEditingController(),maxPrice=TextEditingController(),minArea=TextEditingController(),maxArea=TextEditingController();
  @override void dispose(){minPrice.dispose();maxPrice.dispose();minArea.dispose();maxArea.dispose();super.dispose();}
  num? _num(dynamic v)=>num.tryParse((v??'').toString().replaceAll(',','').trim());
  Future<void> shareProperty(Map<String,dynamic> p)async{
    try{
      final me=await AmlakSupabase.profile();
      if(me['role']!='manager'){_error(Exception('اشتراک‌گذاری فقط توسط مدیر دفتر مجاز است.'));return;}
      final profiles=await AmlakSupabase.loadProfiles();
      final access=await AmlakSupabase.loadPropertyAccess(p['id'].toString());
      final selected=access.map((x)=>x['user_id'].toString()).toSet();
      await showDialog<void>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,refresh)=>AlertDialog(
        title:const Text('اشتراک فایل با مشاوران'),
        content:SizedBox(width:420,child:profiles.isEmpty?const Text('مشاوری ثبت نشده است.'):ListView(shrinkWrap:true,children:profiles.where((x)=>x['id']!=AmlakSupabase.uid&&x['is_active']!=false).map((x){final id=x['id'].toString();final checked=selected.contains(id);return CheckboxListTile(value:checked,title:Text(x['full_name']??'مشاور'),subtitle:Text(x['phone']??''),onChanged:(v)async{try{if(v==true){await AmlakSupabase.grantProperty(p['id'].toString(),id);selected.add(id);}else{await AmlakSupabase.revokeProperty(p['id'].toString(),id);selected.remove(id);}refresh((){});}catch(e){_error(e);}});}).toList())),
        actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('پایان'))]
      )));
    }catch(e){_error(e);}
  }
  Future<void> details(Map<String,dynamic> p)async{
    await showDialog<void>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,refresh)=>AlertDialog(
      title:Text(p['title']??'جزئیات ملک'),
      content:SizedBox(width:480,child:SingleChildScrollView(child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisSize:MainAxisSize.min,children:[
        FutureBuilder<List<Map<String,dynamic>>>(future:AmlakSupabase.loadPropertyImages(p['id'].toString()),builder:(ctx,s){
          if(s.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator());
          final imgs=s.data??[];
          if(imgs.isEmpty)return const Text('برای این ملک تصویری ثبت نشده است.');
          return SizedBox(height:190,child:ListView(scrollDirection:Axis.horizontal,children:imgs.map((im)=>SizedBox(width:170,child:Card(child:Column(children:[
            Expanded(child:Image.network(im['signed_url'],fit:BoxFit.cover,width:170,errorBuilder:(_,__,___)=>const Icon(Icons.broken_image))),
            IconButton(tooltip:'حذف تصویر',onPressed:()async{try{await AmlakSupabase.deletePropertyImage(im['id'].toString(),im['image_url'].toString());refresh((){});}catch(e){_error(e);}},icon:const Icon(Icons.delete_outline,color:Colors.red))
          ])))).toList()));
        }),
        const SizedBox(height:12),
        Text('نوع ملک: ${p['property_type']??'—'}'),
        Text('معامله: ${p['deal_type']??'—'}'),
        Text('شهر و محله: ${p['city']??''} - ${p['neighborhood']??''}'),
        Text('آدرس: ${p['address']??'—'}'),
        Text('متراژ: ${p['area']??'—'} متر'),
        Text('قیمت: ${money(p['price'])} ${p['negotiable']==true?'(قابل مذاکره)':''}'),
        Text('ودیعه: ${money(p['deposit'])} | اجاره: ${money(p['monthly_rent'])}'),
        Text('کمیسیون: ${money(p['commission_amount'])} | سهم مشاور: ${money(p['consultant_share'])}'),
        Text('خواب: ${p['bedrooms']??'—'} | سن بنا: ${p['building_age']??'—'}'),
        Text('پارکینگ: ${p['parking']==true?'دارد':'ندارد'} | آسانسور: ${p['elevator']==true?'دارد':'ندارد'} | انباری: ${p['storage']==true?'دارد':'ندارد'}'),
        Text('مالک: ${p['seller_name']??'—'} | تماس: ${p['phone']??'—'}'),
        Text('کد فایل: ${p['file_code']??'—'}'),
        Text('توضیحات: ${p['description']??'—'}')
      ]))),
      actions:[
        TextButton.icon(onPressed:()=>shareProperty(p),icon:const Icon(Icons.share),label:const Text('اشتراک با مشاوران')),
        TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('بستن'))
      ]
    )));
  }

  @override void initState(){super.initState();load();}
  Future<void> load()async{try{final r=await AmlakSupabase.loadProperties();if(mounted)setState(()=>rows=r);}catch(e){_error(e);}finally{if(mounted)setState(()=>loading=false);}}
  void _error(Object e)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('خطا: $e')));
  List<Map<String,dynamic>> get filtered=>rows.where((p){final text='${p['title']} ${p['address']} ${p['neighborhood']} ${p['phone']} ${p['file_code']}'.toLowerCase();final price=_num(p['price'])??0,area=_num(p['area'])??0;final loP=_num(minPrice.text),hiP=_num(maxPrice.text),loA=_num(minArea.text),hiA=_num(maxArea.text);return text.contains(query.toLowerCase())&&(deal=='همه'||p['deal_type']==deal)&&(kind=='همه'||p['property_type']==kind)&&(loP==null||price>=loP)&&(hiP==null||price<=hiP)&&(loA==null||area>=loA)&&(hiA==null||area<=hiA);}).toList();
  Future<void> edit([Map<String,dynamic>? p])async{Map<String,dynamic>? initial=p==null?null:Map<String,dynamic>.from(p);if(initial!=null){try{initial['private_note']=await AmlakSupabase.loadPrivateNote(initial['id'].toString());}catch(_){initial['private_note']='';}}final result=await showDialog<Map<String,dynamic>>(context:context,builder:(_)=>PropertyForm(initial:initial));if(result==null)return;try{final saved=await AmlakSupabase.saveProperty(id:p?['id']?.toString(),title:result['title'],kind:result['property_type'],address:result['address'],area:result['area'],price:result['price'],phone:result['phone'],dealType:result['deal_type'],city:result['city'],neighborhood:result['neighborhood'],deposit:result['deposit'],monthlyRent:result['monthly_rent'],bedrooms:result['bedrooms'],buildingAge:result['building_age'],parking:result['parking'],elevator:result['elevator'],storage:result['storage'],features:List<String>.from(result['features']??[]),sellerName:result['seller_name'],documentType:result['document_type'],description:result['description'],status:result['status'],commissionAmount:result['commission_amount'],consultantShare:result['consultant_share'],negotiable:result['negotiable']);await AmlakSupabase.savePrivateNote(saved['id'].toString(),result['private_note']??'');for(final image in List<XFile>.from(result['_images']??[])){await AmlakSupabase.uploadImage(saved['id'].toString(),image);}if(p!=null){rows[rows.indexWhere((x)=>x['id']==p['id'])]=saved;}else{rows.insert(0,saved);}if(mounted)setState((){});}catch(e){_error(e);}}
  Future<void> remove(Map<String,dynamic> p)async{try{await AmlakSupabase.deleteRow('properties',p['id'].toString());setState(()=>rows.remove(p));}catch(e){_error(e);}}
  @override Widget build(BuildContext context)=>Scaffold(floatingActionButton:FloatingActionButton.extended(onPressed:()=>edit(),backgroundColor:gold,icon:const Icon(Icons.add),label:const Text('ثبت فایل')),body:RefreshIndicator(onRefresh:load,child:Column(children:[
    Padding(padding:const EdgeInsets.fromLTRB(12,12,12,4),child:TextField(onChanged:(v)=>setState(()=>query=v),decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'جستجوی کد، عنوان، محله یا تلفن',border:OutlineInputBorder()))),
    Padding(padding:const EdgeInsets.symmetric(horizontal:12,vertical:6),child:Row(children:[Expanded(child:DropdownButtonFormField<String>(value:deal,decoration:const InputDecoration(labelText:'نوع معامله'),items:['همه',...deals].map((e)=>DropdownMenuItem(value:e,child:Text(e))).toList(),onChanged:(v)=>setState(()=>deal=v??'همه'))),const SizedBox(width:8),Expanded(child:DropdownButtonFormField<String>(value:kind,decoration:const InputDecoration(labelText:'نوع ملک'),items:['همه',...kinds].map((e)=>DropdownMenuItem(value:e,child:Text(e))).toList(),onChanged:(v)=>setState(()=>kind=v??'همه')))])),
    ExpansionTile(title:const Text('فیلتر پیشرفته قیمت و متراژ'),children:[Padding(padding:const EdgeInsets.symmetric(horizontal:12),child:Column(children:[Row(children:[Expanded(child:TextField(controller:minPrice,onChanged:(_)=>setState((){}),keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'حداقل قیمت',suffixText:'تومان'))),const SizedBox(width:8),Expanded(child:TextField(controller:maxPrice,onChanged:(_)=>setState((){}),keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'حداکثر قیمت',suffixText:'تومان')))]),Row(children:[Expanded(child:TextField(controller:minArea,onChanged:(_)=>setState((){}),keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'حداقل متراژ'))),const SizedBox(width:8),Expanded(child:TextField(controller:maxArea,onChanged:(_)=>setState((){}),keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'حداکثر متراژ')))]),Align(alignment:Alignment.centerLeft,child:TextButton(onPressed:()=>setState((){minPrice.clear();maxPrice.clear();minArea.clear();maxArea.clear();}),child:const Text('پاک کردن فیلترها')))]))]),
    Expanded(child:loading?const Center(child:CircularProgressIndicator()):filtered.isEmpty?const Center(child:Text('فایلی پیدا نشد')):ListView.builder(padding:const EdgeInsets.all(10),itemCount:filtered.length,itemBuilder:(c,i){final p=filtered[i];return Card(child:ListTile(isThreeLine:true,title:Text(p['title']??'بدون عنوان',style:const TextStyle(fontWeight:FontWeight.bold)),subtitle:Text('${p['property_type']??''} • ${p['deal_type']??''}\n${p['neighborhood']??p['address']??''} • ${p['area']??'—'} متر\nقیمت: ${money(p['price'])} | ودیعه: ${money(p['deposit'])} | اجاره: ${money(p['monthly_rent'])}'),onTap:()=>details(p),trailing:PopupMenuButton<String>(onSelected:(v){if(v=='edit')edit(p);if(v=='delete')remove(p);},itemBuilder:(_)=>const [PopupMenuItem(value:'edit',child:Text('ویرایش')),PopupMenuItem(value:'delete',child:Text('حذف'))]),leading:CircleAvatar(backgroundColor:gold.withValues(alpha:.15),child:const Icon(Icons.home,color:gold))));})),
  ])));
}

class PropertyForm extends StatefulWidget {
 final Map<String,dynamic>? initial; const PropertyForm({super.key,this.initial});
 @override State<PropertyForm> createState()=>_PropertyFormState();
}
class _PropertyFormState extends State<PropertyForm>{
 final keyForm=GlobalKey<FormState>();final picker=ImagePicker();final List<XFile> selectedImages=[];late final Map<String,TextEditingController> c;late String kind,deal,status;late bool parking,elevator,storage,negotiable; Set<String> features={};
 @override void initState(){super.initState();final p=widget.initial??{};c={for(final k in ['title','city','neighborhood','address','area','price','deposit','monthly_rent','bedrooms','building_age','phone','seller_name','document_type','description','commission_amount','consultant_share','private_note']) k:TextEditingController(text:p[k]?.toString()??(k=='city'?'گرگان':''))};kind=p['property_type']??kinds.first;deal=p['deal_type']??deals.first;status=p['status']??'active';parking=p['parking']==true;elevator=p['elevator']==true;storage=p['storage']==true;negotiable=p['negotiable']==true;features=Set<String>.from((p['features'] is List)?p['features']:[]);}
 @override void dispose(){for(final x in c.values){x.dispose();}super.dispose();}
 Widget field(String k,String label,{bool number=false,int lines=1})=>Padding(padding:const EdgeInsets.only(bottom:10),child:TextFormField(controller:c[k],maxLines:lines,keyboardType:number?TextInputType.number:TextInputType.text,decoration:InputDecoration(labelText:label,border:const OutlineInputBorder()),validator:k=='title'?(v)=>v==null||v.trim().isEmpty?'عنوان ملک الزامی است':null:null));
 @override Widget build(BuildContext context)=>AlertDialog(title:Text(widget.initial==null?'ثبت مشخصات کامل ملک':'ویرایش ملک'),content:SizedBox(width:480,child:Form(key:keyForm,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
  DropdownButtonFormField<String>(value:kind,decoration:const InputDecoration(labelText:'نوع ملک'),items:kinds.map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:(v)=>setState(()=>kind=v??kind)),
  const SizedBox(height:10),DropdownButtonFormField<String>(value:deal,decoration:const InputDecoration(labelText:'نوع معامله'),items:deals.map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:(v)=>setState(()=>deal=v??deal)),
  const SizedBox(height:10),field('title','عنوان فایل'),field('city','شهر'),field('neighborhood','محله'),field('address','آدرس کامل'),field('area','متراژ (متر)',number:true),field('price','قیمت کل (تومان)',number:true),field('deposit','مبلغ رهن/ودیعه (تومان)',number:true),field('monthly_rent','اجاره ماهانه (تومان)',number:true),field('bedrooms','تعداد اتاق',number:true),field('building_age','سن بنا (سال)',number:true),
  const Align(alignment:Alignment.centerRight,child:Text('امکانات ملک',style:TextStyle(fontWeight:FontWeight.bold))),...['بالکن','پکیج','کولر گازی','انباری اضافی','لابی','نگهبانی','استخر','سالن ورزشی','کابینت MDF','بازسازی‌شده'].map((f)=>CheckboxListTile(dense:true,contentPadding:EdgeInsets.zero,title:Text(f),value:features.contains(f),onChanged:(v)=>setState((){if(v==true){features.add(f);}else{features.remove(f);}}))),SwitchListTile(title:const Text('پارکینگ'),value:parking,onChanged:(v)=>setState(()=>parking=v)),SwitchListTile(title:const Text('آسانسور'),value:elevator,onChanged:(v)=>setState(()=>elevator=v)),SwitchListTile(title:const Text('انباری'),value:storage,onChanged:(v)=>setState(()=>storage=v)),
  field('seller_name','نام مالک'),field('phone','شماره تماس',number:true),field('document_type','نوع سند'),field('description','توضیحات و امکانات',lines:3),field('commission_amount','مبلغ کمیسیون (تومان)',number:true),field('consultant_share','سهم مشاور از کمیسیون (تومان)',number:true),SwitchListTile(title:const Text('قیمت قابل مذاکره است'),value:negotiable,onChanged:(v)=>setState(()=>negotiable=v)),field('private_note','یادداشت محرمانه دفتر',lines:2),
  Align(alignment:Alignment.centerRight,child:TextButton.icon(onPressed:()async{final files=await picker.pickMultiImage(imageQuality:82,maxWidth:1800);if(files.isNotEmpty)setState(()=>selectedImages.addAll(files));},icon:const Icon(Icons.add_photo_alternate),label:const Text('افزودن تصاویر ملک'))),
  if(selectedImages.isNotEmpty) Align(alignment:Alignment.centerRight,child:Text('${selectedImages.length} تصویر انتخاب شده است')),
  if(selectedImages.isNotEmpty) SizedBox(height:76,child:ListView(scrollDirection:Axis.horizontal,children:selectedImages.map((f)=>Padding(padding:const EdgeInsets.all(4),child:Image.file(File(f.path),width:76,height:76,fit:BoxFit.cover))).toList())),
  DropdownButtonFormField<String>(value:status,decoration:const InputDecoration(labelText:'وضعیت فایل'),items:const [DropdownMenuItem(value:'active',child:Text('فعال')),DropdownMenuItem(value:'sold',child:Text('فروخته‌شده')),DropdownMenuItem(value:'rented',child:Text('اجاره رفته')),DropdownMenuItem(value:'archived',child:Text('بایگانی'))],onChanged:(v)=>setState(()=>status=v??status)),
 ])))),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('انصراف')),FilledButton(onPressed:(){if(keyForm.currentState!.validate()){final out=<String,dynamic>{for(final e in c.entries)e.key:e.value.text.trim(),'property_type':kind,'deal_type':deal,'parking':parking,'elevator':elevator,'storage':storage,'features':features.toList(),'status':status,'negotiable':negotiable,'_images':selectedImages};Navigator.pop(context,out);}},child:const Text('ذخیره'))]);
}

class CustomersPage extends StatefulWidget {const CustomersPage({super.key});@override State<CustomersPage> createState()=>_CustomersPageState();}
class _CustomersPageState extends State<CustomersPage>{
 List<Map<String,dynamic>> rows=[];bool loading=true;String query='';
 @override void initState(){super.initState();load();}
 Future<void> load()async{try{rows=await AmlakSupabase.loadCustomers();}catch(e){err(e);}if(mounted)setState(()=>loading=false);}
 void err(Object e)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('خطا: $e')));
 Future<void> edit([Map<String,dynamic>? p])async{final name=TextEditingController(text:p?['full_name']??'');final phone=TextEditingController(text:p?['phone']??'');final type=TextEditingController(text:p?['customer_type']??'');final note=TextEditingController(text:p?['description']??'');final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:Text(p==null?'مشتری جدید':'ویرایش مشتری'),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:name,decoration:const InputDecoration(labelText:'نام و نام خانوادگی')),TextField(controller:phone,decoration:const InputDecoration(labelText:'شماره تماس'),keyboardType:TextInputType.phone),TextField(controller:type,decoration:const InputDecoration(labelText:'نوع درخواست (خریدار/مستأجر/مالک)')),TextField(controller:note,decoration:const InputDecoration(labelText:'توضیحات'))])),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('انصراف')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('ذخیره'))]));if(ok!=true||name.text.trim().isEmpty)return;try{final saved=await AmlakSupabase.saveRow('customers',{'full_name':name.text.trim(),'phone':phone.text.trim(),'customer_type':type.text.trim(),'description':note.text.trim()},id:p?['id']?.toString());if(p==null)rows.insert(0,saved);else rows[rows.indexWhere((x)=>x['id']==p['id'])]=saved;setState((){});}catch(e){err(e);}}
 @override Widget build(BuildContext context){
    final filtered=rows.where((p)=>('${p['full_name']} ${p['phone']} ${p['customer_type']}').toLowerCase().contains(query.toLowerCase())).toList();
    return Scaffold(
      floatingActionButton:FloatingActionButton.extended(onPressed:()=>edit(),backgroundColor:gold,icon:const Icon(Icons.person_add),label:const Text('مشتری جدید')),
      body:loading?const Center(child:CircularProgressIndicator()):RefreshIndicator(onRefresh:load,child:Column(children:[
        Padding(padding:const EdgeInsets.all(10),child:TextField(onChanged:(v)=>setState(()=>query=v),decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'جستجوی نام، شماره یا نوع درخواست',border:OutlineInputBorder()))),
        Expanded(child:ListView.builder(itemCount:filtered.length,itemBuilder:(ctx,i){final p=filtered[i];return Card(child:ListTile(leading:const CircleAvatar(child:Icon(Icons.person)),title:Text(p['full_name']??''),subtitle:Text('${p['phone']??''} • ${p['customer_type']??''}\n${p['description']??''}'),isThreeLine:true,onTap:()=>edit(p),trailing:IconButton(icon:const Icon(Icons.edit),onPressed:()=>edit(p))));}))
      ]))
    );
  }
}

class FollowupsPage extends StatefulWidget {const FollowupsPage({super.key});@override State<FollowupsPage> createState()=>_FollowupsPageState();}
class _FollowupsPageState extends State<FollowupsPage>{
 List<Map<String,dynamic>> rows=[];List<Map<String,dynamic>> customers=[];List<Map<String,dynamic>> properties=[];bool loading=true;
 @override void initState(){super.initState();load();}
 Future<void> load()async{try{final r=await Future.wait([AmlakSupabase.loadFollowups(),AmlakSupabase.loadCustomers(),AmlakSupabase.loadProperties()]);rows=r[0];customers=r[1];properties=r[2];}catch(e){err(e);}if(mounted)setState(()=>loading=false);}
 void err(Object e)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('خطا: $e')));
 Future<void> add()async{String? customer=customers.isEmpty?null:customers.first['id'].toString();String? property;String description='';DateTime date=DateTime.now().add(const Duration(days:1));final ok=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,ss)=>AlertDialog(title:const Text('ثبت پیگیری'),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
 DropdownButtonFormField<String>(value:customer,decoration:const InputDecoration(labelText:'مشتری'),items:customers.map((x)=>DropdownMenuItem(value:x['id'].toString(),child:Text(x['full_name']??''))).toList(),onChanged:(v)=>ss(()=>customer=v)),
 const SizedBox(height:10),DropdownButtonFormField<String>(value:property,decoration:const InputDecoration(labelText:'ملک مرتبط (اختیاری)'),items:properties.map((x)=>DropdownMenuItem(value:x['id'].toString(),child:Text(x['title']??''))).toList(),onChanged:(v)=>ss(()=>property=v)),
 TextFormField(decoration:const InputDecoration(labelText:'شرح پیگیری'),maxLines:3,onChanged:(v)=>description=v),
 TextButton.icon(onPressed:()async{final d=await showDatePicker(context:ctx,initialDate:date,firstDate:DateTime(2020),lastDate:DateTime(2100));if(d!=null)ss(()=>date=d);},icon:const Icon(Icons.calendar_month),label:Text('تاریخ: ${date.year}/${date.month}/${date.day}')),
 ])),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('انصراف')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('ذخیره'))])));if(ok!=true)return;try{final saved=await AmlakSupabase.saveRow('followups',{'customer_id':customer,'property_id':property,'followup_date':date.toUtc().toIso8601String(),'description':description,'status':'pending'});rows.insert(0,saved);setState((){});}catch(e){err(e);}}
 @override Widget build(BuildContext context)=>Scaffold(floatingActionButton:FloatingActionButton.extended(onPressed:customers.isEmpty?null:add,backgroundColor:gold,icon:const Icon(Icons.add_task),label:const Text('پیگیری جدید')),body:loading?const Center(child:CircularProgressIndicator()):RefreshIndicator(onRefresh:load,child:ListView.builder(itemCount:rows.length,itemBuilder:(ctx,i){final p=rows[i];final who=customers.firstWhere((x)=>x['id']==p['customer_id'],orElse:()=>{'full_name':'مشتری'})['full_name']??'مشتری';return Card(child:ListTile(leading:const Icon(Icons.event_note,color:gold),title:Text(who.toString()),subtitle:Text('${p['description']??''}\n${p['followup_date']??''}'),isThreeLine:true,trailing:PopupMenuButton<String>(onSelected:(v)async{try{await AmlakSupabase.client.from('followups').update({'status':v}).eq('id',p['id']);setState(()=>p['status']=v);}catch(e){err(e);}},itemBuilder:(_)=>const [PopupMenuItem(value:'done',child:Text('انجام شد')),PopupMenuItem(value:'cancelled',child:Text('لغو'))])));})));
}

class ReportsPage extends StatefulWidget{const ReportsPage({super.key});@override State<ReportsPage> createState()=>_ReportsPageState();}
class _ReportsPageState extends State<ReportsPage>{
 bool loading=true;List<Map<String,dynamic>> p=[];
 @override void initState(){super.initState();load();}
 Future<void> load()async{try{p=await AmlakSupabase.loadProperties();}catch(_){}if(mounted)setState(()=>loading=false);}
 @override Widget build(BuildContext context){
  num sum(String key)=>p.fold<num>(0,(v,x)=>v+(num.tryParse(x[key]?.toString()??'')??0));
  final active=p.where((x)=>x['status']=='active').length,sold=p.where((x)=>x['status']=='sold').length,rented=p.where((x)=>x['status']=='rented').length,negotiable=p.where((x)=>x['negotiable']==true).length;
  return loading?const Center(child:CircularProgressIndicator()):RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.all(16),children:[const Text('گزارش عملکرد دفتر',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),const SizedBox(height:12),_tile('مجموع فایل‌ها',p.length),_tile('فایل‌های فعال',active),_tile('فروخته‌شده',sold),_tile('اجاره‌رفته',rented),_tile('قابل مذاکره',negotiable),_tile('جمع کمیسیون‌های ثبت‌شده',sum('commission_amount'),moneyValue:true),_tile('جمع سهم مشاوران',sum('consultant_share'),moneyValue:true)]));
 }
 Widget _tile(String s,num n,{bool moneyValue=false})=>Card(child:ListTile(title:Text(s),trailing:Text(moneyValue?money(n):n.toString(),style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold,color:gold))));
}

class TeamPage extends StatefulWidget{const TeamPage({super.key});@override State<TeamPage> createState()=>_TeamPageState();}
class _TeamPageState extends State<TeamPage>{
 List<Map<String,dynamic>> rows=[];bool loading=true;bool manager=false;
 @override void initState(){super.initState();load();}
 Future<void> load()async{try{final profile=await AmlakSupabase.profile();manager=profile['role']=='manager';if(manager)rows=await AmlakSupabase.loadProfiles();}catch(_){}if(mounted)setState(()=>loading=false);}
 Future<void> invite()async{
  final name=TextEditingController(),email=TextEditingController(),phone=TextEditingController();
  final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:const Text('افزودن مشاور جدید'),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
   TextField(controller:name,decoration:const InputDecoration(labelText:'نام و نام خانوادگی')),
   TextField(controller:email,keyboardType:TextInputType.emailAddress,decoration:const InputDecoration(labelText:'ایمیل مشاور')),
   TextField(controller:phone,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'شماره تماس'))
  ])),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('انصراف')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('ارسال دعوت‌نامه'))]));
  if(ok!=true)return;
  if(name.text.trim().isEmpty||!email.text.contains('@')){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('نام و ایمیل معتبر وارد کنید.')));return;}
  try{final result=await AmlakSupabase.client.functions.invoke('invite-consultant',body:{'full_name':name.text.trim(),'email':email.text.trim(),'phone':phone.text.trim()});if(result.status<200||result.status>=300)throw Exception(result.data);if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('دعوت‌نامه مشاور ارسال شد.')));await load();}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('ارسال دعوت‌نامه ناموفق بود: $e')));}
  name.dispose();email.dispose();phone.dispose();
 }
 @override Widget build(BuildContext context)=>loading?const Center(child:CircularProgressIndicator()):!manager?const Center(child:Text('این بخش فقط برای مدیر دفتر فعال است.')):Scaffold(
  floatingActionButton:FloatingActionButton.extended(onPressed:invite,backgroundColor:gold,icon:const Icon(Icons.person_add),label:const Text('دعوت مشاور')),
  body:RefreshIndicator(onRefresh:load,child:rows.isEmpty?const Center(child:Text('هنوز مشاوری ثبت نشده است.')):ListView(children:rows.map((p)=>Card(child:ListTile(leading:const Icon(Icons.badge_outlined),title:Text(p['full_name']??'بدون نام'),subtitle:Text('${p['phone']??''} • ${p['role']??''}'),trailing:Icon(p['is_active']==true?Icons.check_circle:Icons.block,color:p['is_active']==true?Colors.green:Colors.red)))).toList())));
}

class AppShell extends StatefulWidget{const AppShell({super.key});@override State<AppShell> createState()=>_AppShellState();}
class _AppShellState extends State<AppShell>{int index=0;final pages=const [DashboardPage(),PropertiesPage(),CustomersPage(),FollowupsPage(),ReportsPage(),TeamPage()];@override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(AppPages.titles[index],style:const TextStyle(fontWeight:FontWeight.bold)),actions:[IconButton(tooltip:'خروج',onPressed:()=>Supabase.instance.client.auth.signOut(),icon:const Icon(Icons.logout))]),body:pages[index],bottomNavigationBar:NavigationBar(selectedIndex:index,onDestinationSelected:(v)=>setState(()=>index=v),destinations:List.generate(AppPages.titles.length,(i)=>NavigationDestination(icon:Icon(AppPages.icons[i]),label:AppPages.titles[i]))));}
