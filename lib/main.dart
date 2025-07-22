import 'package:flutter/material.dart';
import 'screens/logo_screen.dart';

void main() {
  runApp(const FeynmanAIApp());
}

class FeynmanAIApp extends StatelessWidget {
  const FeynmanAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zawadii Learn',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: Typography.material2021().englishLike,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.blue,
        ),
      ),
      home: const LogoScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

