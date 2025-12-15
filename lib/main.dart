import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Tambahkan ini
import 'screens/auth/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Supabase
  await Supabase.initialize(
    url: 'https://jhqolrarbjlfhobdwrgp.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpocW9scmFyYmpsZmhvYmR3cmdwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU3NDkyMDgsImV4cCI6MjA4MTMyNTIwOH0.3vXs9moyjsb_R2ZadECJg2_qDaFE787ktcU110WM95U',
  );

  runApp(const PredictIQApp());
}

class PredictIQApp extends StatelessWidget {
  const PredictIQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PredictIQ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
        scaffoldBackgroundColor: Colors.grey[50],
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}