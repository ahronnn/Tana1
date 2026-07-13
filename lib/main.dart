import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/splash_page.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://dphudshfuowpskpesord.supabase.co',
    anonKey: 'sb_publishable_hcyC8TsklMy5Mp4N15Gv8Q_zYpHrNJ4',
  );

  runApp(const Tana1App());
}

class Tana1App extends StatelessWidget {
  const Tana1App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TANA 1',
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.red,
      ),
      home: const SplashPage(),
    );
  }
}