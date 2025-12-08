import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/auth/splash_screen.dart';

void main() {
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
