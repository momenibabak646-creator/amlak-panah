import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_config.dart';
import 'app_pages.dart';

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
  if(!AppConfig.hasSupabase)return const AppShell();
  return StreamBuilder<AuthState>(stream:Supabase.instance.client.auth.onAuthStateChange,builder:(context,snapshot){
   if(Supabase.instance.client.auth.currentUser!=null)return const AppShell();
   return const SignInPage();
  });
 }
}
class SignInPage extends StatefulWidget{const SignInPage({super.key});@override State<SignInPage> createState()=>_SignInPageState();}
class _SignInPageState extends State<SignInPage>{
 final email=TextEditingController(),password=TextEditingController();bool signup=false,busy=false;String? error;
 @override void dispose(){email.dispose();password.dispose();super.dispose();}
 Future<void> submit()async{setState(() { busy=true; error=null; });try{if(signup){await Supabase.instance.client.auth.signUp(email:email.text.trim(),password:password.text);}else{await Supabase.instance.client.auth.signInWithPassword(email:email.text.trim(),password:password.text);}}on AuthException catch(e){error=e.message;}catch(e){error=e.toString();}if(mounted)setState(()=>busy=false);}
 @override Widget build(BuildContext context)=>Scaffold(body:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:420),child:Card(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[
 Container(width:132,height:132,decoration:const BoxDecoration(color:Color(0xFFFFB900),shape:BoxShape.circle),padding:const EdgeInsets.all(9),child:Container(decoration:const BoxDecoration(color:Colors.black,shape:BoxShape.circle),alignment:Alignment.center,child:const Text('املاک پناه',textAlign:TextAlign.center,style:TextStyle(color:Colors.white,fontSize:22,fontWeight:FontWeight.bold)))),const SizedBox(height:10),Text(signup?'ایجاد حساب کاربری':'ورود به حساب کاربری'),const SizedBox(height:18),
 TextField(controller:email,keyboardType:TextInputType.emailAddress,decoration:const InputDecoration(labelText:'ایمیل',border:OutlineInputBorder())),const SizedBox(height:12),
 TextField(controller:password,obscureText:true,decoration:const InputDecoration(labelText:'رمز عبور',border:OutlineInputBorder())),
 if(error!=null)Padding(padding:const EdgeInsets.all(8),child:Text(error!,style:const TextStyle(color:Colors.red))),
 const SizedBox(height:12),SizedBox(width:double.infinity,child:FilledButton(onPressed:busy?null:submit,child:Text(busy?'لطفاً صبر کنید':signup?'ثبت‌نام':'ورود'))),
 TextButton(onPressed:()=>setState(()=>signup=!signup),child:Text(signup?'ورود به حساب':'ساخت حساب جدید')),
 ])))))));
}
