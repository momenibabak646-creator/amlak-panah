import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_config.dart';
import 'app_pages.dart';
import 'brand_logo.dart';

Future<void> main() async {
 WidgetsFlutterBinding.ensureInitialized();
 await AppConfig.initialize();
 runApp(const AmlakPanahApp());
}
class AmlakPanahApp extends StatelessWidget {
 const AmlakPanahApp({super.key});
 @override Widget build(BuildContext context)=>MaterialApp(
  debugShowCheckedModeBanner:false,title:'املاک پناه',
  theme:ThemeData(useMaterial3:true,colorScheme:ColorScheme.fromSeed(seedColor:const Color(0xFFB58A35)),scaffoldBackgroundColor:const Color(0xFFF7F6F2)),
  home:const Directionality(textDirection:TextDirection.rtl,child:AuthGate()));
}
class AuthGate extends StatelessWidget {
 const AuthGate({super.key});
 @override Widget build(BuildContext context){
  if(!AppConfig.hasSupabase){
   return const AccountStatusPage(
    message:'تنظیمات اتصال پایگاه داده کامل نیست. ورود محلی بدون احراز هویت فعال نمی‌شود.',
    canSignOut:false,
   );
  }
  final client=Supabase.instance.client;
  return StreamBuilder<AuthState>(
   stream:client.auth.onAuthStateChange,
   builder:(context,snapshot){
    final user=client.auth.currentUser;
    if(user==null)return const SignInPage();
    return FutureBuilder<Map<String,dynamic>?>(
     key:ValueKey(user.id),
     future:client.from('profiles').select('is_active').eq('id',user.id).maybeSingle(),
     builder:(context,profileSnapshot){
      if(profileSnapshot.connectionState==ConnectionState.waiting){
       return const Scaffold(body:Center(child:CircularProgressIndicator()));
      }
      if(profileSnapshot.hasError){
       return const AccountStatusPage(
        message:'وضعیت حساب بررسی نشد. اتصال اینترنت را بررسی کنید و دوباره وارد شوید.',
       );
      }
      if(profileSnapshot.data==null||profileSnapshot.data!['is_active']!=true){
       return const AccountStatusPage(
        message:'حساب شما هنوز توسط مدیر دفتر فعال نشده است. برای دسترسی، با مدیر املاک پناه تماس بگیرید.',
       );
      }
      return const AppShell();
     },
    );
   },
  );
 }
}

class AccountStatusPage extends StatelessWidget {
 final String message;
 final bool canSignOut;
 const AccountStatusPage({super.key,required this.message,this.canSignOut=true});
 @override Widget build(BuildContext context)=>Scaffold(
  body:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:ConstrainedBox(
   constraints:const BoxConstraints(maxWidth:420),
   child:Card(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[
    const BrandLogo(size:120),
    const SizedBox(height:18),
    Text(message,textAlign:TextAlign.center),
    if(canSignOut)...[
     const SizedBox(height:18),
     SizedBox(width:double.infinity,child:FilledButton(
      onPressed:()=>Supabase.instance.client.auth.signOut(),
      child:const Text('خروج از حساب'),
     )),
    ],
   ]))),
  ))),
 );
}

class SignInPage extends StatefulWidget{
 const SignInPage({super.key});
 @override State<SignInPage> createState()=>_SignInPageState();
}
class _SignInPageState extends State<SignInPage>{
 final email=TextEditingController(),password=TextEditingController();
 bool busy=false;
 String? error;
 @override void dispose(){email.dispose();password.dispose();super.dispose();}
 Future<void> submit()async{
  setState((){busy=true;error=null;});
  try{
   await Supabase.instance.client.auth.signInWithPassword(
    email:email.text.trim(),
    password:password.text,
   );
  } on AuthException catch(e){
   error=e.message;
  } on SocketException{
   error='اتصال به سرور برقرار نشد. اینترنت گوشی، DNS یا VPN را بررسی کنید و دوباره تلاش کنید.';
  } on TimeoutException{
   error='پاسخ سرور دیر رسید. اتصال اینترنت را بررسی و دوباره تلاش کنید.';
  } on FormatException{
   error='نشانی اتصال سرور معتبر نیست. تنظیمات برنامه باید بررسی شود.';
  } catch(_){
   error='ورود انجام نشد. لطفاً اتصال اینترنت را بررسی و دوباره تلاش کنید.';
  }
  if(mounted)setState(()=>busy=false);
 }
 @override Widget build(BuildContext context)=>Scaffold(
  body:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:ConstrainedBox(
   constraints:const BoxConstraints(maxWidth:420),
   child:Card(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[
    const BrandLogo(size:144),
    const SizedBox(height:10),
    const Text('ورود به حساب کاربری'),
    const SizedBox(height:18),
    TextField(controller:email,keyboardType:TextInputType.emailAddress,decoration:const InputDecoration(labelText:'ایمیل',border:OutlineInputBorder())),
    const SizedBox(height:12),
    TextField(controller:password,obscureText:true,decoration:const InputDecoration(labelText:'رمز عبور',border:OutlineInputBorder())),
    if(error!=null)Padding(padding:const EdgeInsets.all(8),child:Text(error!,style:const TextStyle(color:Colors.red))),
    const SizedBox(height:12),
    SizedBox(width:double.infinity,child:FilledButton(
     onPressed:busy?null:submit,
     child:Text(busy?'لطفاً صبر کنید':'ورود'),
    )),
    const SizedBox(height:8),
    const Text('برای ساخت حساب مشاور، از مدیر دفتر دعوت‌نامه دریافت کنید.',textAlign:TextAlign.center),
   ]))),
  ))),
 );
}
