import 'package:get/get.dart';
import '../controller/user_controller.dart';
import '../controller/auth_controller.dart';

/// App Bindings for GetX Dependency Injection
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<UserController>(UserController(), permanent: true);
  }
}

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<UserController>()) {
      Get.put<UserController>(UserController(), permanent: true);
    }
    Get.lazyPut<AuthController>(() => AuthController());
  }
}

class MainBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<UserController>()) {
      Get.put<UserController>(UserController(), permanent: true);
    }
    if (!Get.isRegistered<AuthController>()) {
      Get.lazyPut<AuthController>(() => AuthController());
    }
  }
}
