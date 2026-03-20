import 'package:flutter/material.dart';
import 'landing_screen.dart'; // Use landing screen instead of dashboard

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MaizeMate',
      theme: ThemeData(
        primaryColor: const Color(0xFF2E7D32),
        scaffoldBackgroundColor: const Color(0xFFF5F5DC),
      ),
      home: const LandingScreen(),
    );
  }
}
