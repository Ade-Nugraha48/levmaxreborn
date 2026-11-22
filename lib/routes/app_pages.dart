import 'package:get/get.dart';
import 'app_routes.dart';
import 'app_bindings.dart';
import '../view/pages/splash_page.dart';
import '../view/pages/login_page.dart';
import '../view/pages/register_page.dart';
import '../view/pages/main_shell_page.dart';
import '../view/pages/workout_detail_page.dart';
import '../view/pages/study_detail_page.dart';
import '../view/pages/grooming_detail_page.dart';
import '../view/pages/guide_page.dart';
import '../view/pages/achievements_page.dart';
import '../view/pages/edit_profile_page.dart';

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
    GetPage(
      name: AppRoutes.workoutDetail,
      page: () => const WorkoutDetailPage(),
      binding: MainBinding(),
    ),
    GetPage(
      name: AppRoutes.studyDetail,
      page: () => const StudyDetailPage(),
      binding: MainBinding(),
    ),
    GetPage(
      name: AppRoutes.groomingDetail,
      page: () => const GroomingDetailPage(),
      binding: MainBinding(),
    ),
    GetPage(
      name: AppRoutes.guide,
      page: () => const GuidePage(),
      binding: MainBinding(),
    ),
    GetPage(
      name: AppRoutes.achievements,
      page: () => const AchievementsPage(),
      binding: MainBinding(),
    ),
    GetPage(
      name: AppRoutes.editProfile,
      page: () => const EditProfilePage(),
      binding: MainBinding(),
    ),
  ];
}
