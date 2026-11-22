import 'package:get/get.dart';

/// Navigation Controller managing the 4-Tab Main Shell
/// Indexes:
/// 0 - HOME (HomePage)
/// 1 - MAP (CardioPage)
/// 2 - STATS (StatsPage)
/// 3 - PROFILE (ProfilePage)
class NavigationController extends GetxController {
  static NavigationController get to => Get.find<NavigationController>();

  final RxInt currentIndex = 0.obs;

  void changeTab(int index) {
    if (index >= 0 && index <= 3) {
      currentIndex.value = index;
    }
  }

  void switchToHome() => changeTab(0);
  void switchToMap() => changeTab(1);
  void switchToStats() => changeTab(2);
  void switchToProfile() => changeTab(3);
}
