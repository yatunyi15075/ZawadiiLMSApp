import 'package:flutter/material.dart';
import '../screens/logo_screen.dart';
import '../theme/app_theme.dart';

void main() {
  runApp(const FeynmanAIApp());
}

class FeynmanAIApp extends StatelessWidget {
  const FeynmanAIApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zawadii Learn',
      theme: ThemeData(
        // Primary color scheme
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          primary: Colors.blue,
        ),
        
        // Visual density
        visualDensity: VisualDensity.adaptivePlatformDensity,
        
        // Typography
        textTheme: Typography.material2021().englishLike,
        
        // App-wide styling
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