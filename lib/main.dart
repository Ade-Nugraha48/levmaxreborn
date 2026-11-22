import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LevMaxApp());
}

class LevMaxApp extends StatelessWidget {
  const LevMaxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'LEVMAX',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const Scaffold(
        body: Center(
          child: Text(
            'LEVMAX SYSTEM INITIALIZED',
            style: TextStyle(letterSpacing: 2.0),
          ),
        ),
      ),
    );
  }
}
