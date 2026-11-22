import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_pages.dart';
import 'routes/app_bindings.dart';
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
      initialBinding: InitialBinding(),
      initialRoute: AppPages.initial,
      getPages: AppPages.pages,
    );
  }
}
