import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'splash_page.dart'; // Ensure this file is in your lib/ folder

void main() async {
  // Ensure Flutter bindings are initialized[cite: 4]
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase[cite: 2, 4]
  await Firebase.initializeApp();

  // Initialize Supabase[cite: 2, 4]
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
      // Starts the app at the splash screen[cite: 4]
      home: const SplashPage(),
    );
  }
}