import 'package:get/get.dart';
import 'app_routes.dart';
import 'app_bindings.dart';
import '../view/pages/splash_page.dart';
import '../view/pages/login_page.dart';
import '../view/pages/register_page.dart';
import '../view/pages/main_shell_page.dart';

/// App Pages Configuration with Bindings
class AppPages {
  AppPages._();

  static const String initial = AppRoutes.splash;

  static final List<GetPage> pages = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashPage(),
      binding: InitialBinding(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginPage(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.register,
      page: () => const RegisterPage(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.main,
      page: () => const MainShellPage(),
      binding: MainBinding(),
    ),
  ];
}
