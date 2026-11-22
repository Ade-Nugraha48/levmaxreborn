import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/theme/app_theme.dart';
import 'service/hive_service.dart';
import 'service/session_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Local Storage Layers (Modul 6)
  await HiveService.init();
  await SessionService.init();

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
