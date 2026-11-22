import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/constants/game_config.dart';
import '../model/grooming_item_model.dart';
import '../service/hive_service.dart';
import 'quest_controller.dart';
import 'user_controller.dart';

/// Grooming Controller
/// Manages Full Hive CRUD operations for daily grooming checklist items,
/// rank-based minimum requirements, and quest submission.
/// Conforms to `docs/database_schema.md` (TypeId 2) and `docs/roadmap.md` (Phase 5).
class GroomingController extends GetxController {
  static GroomingController get to => Get.find<GroomingController>();

  /// Observable list of user's grooming items
  final RxList<GroomingItemModel> items = <GroomingItemModel>[].obs;

  /// Observable loading state
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadItems();
  }

  /// Active username from UserController
  String get currentUsername {
    if (Get.isRegistered<UserController>()) {
      return UserController.to.username;
    }
    return '';
  }

  /// User's current rank
  String get userRank {
    if (Get.isRegistered<UserController>()) {
      return UserController.to.rank;
    }
    return 'Novice';
  }

  /// Minimum required grooming items based on Rank Overload Specifications
  int get minRequiredItems {
    final target = GameConfig.rankTargets[userRank];
    return target?.minGroomingItems ?? 3;
  }

  /// Number of completed (checked) items
  int get completedCount => items.where((i) => i.isChecked).length;

  /// Total items in checklist
  int get totalCount => items.length;

  /// Progress ratio towards minimum requirement [0.0 .. 1.0]
  double get progressRatio {
    if (minRequiredItems == 0) return 1.0;
    return (completedCount / minRequiredItems).clamp(0.0, 1.0);
  }

  /// Percentage value towards minimum requirement (e.g. 60%)
  int get percentage => (progressRatio * 100).round();

  /// Whether the minimum threshold for today has been reached
  bool get isThresholdMet => completedCount >= minRequiredItems;

  /// Whether Grooming quest was already completed today
  bool get isAlreadySubmitted {
    if (Get.isRegistered<QuestController>()) {
      return QuestController.to.dailyQuest.value?.groomingCompleted ?? false;
    }
    return false;
  }

  // ==========================================
  // HIVE FULL CRUD OPERATIONS (Modul 6)
  // ==========================================

  /// [READ]: Loads all grooming items for active username from Hive
  void loadItems() {
    final username = currentUsername;
    if (username.isEmpty) return;

    final box = HiveService.groomingItemsBox;
    final userItems = box.values.where((item) => item.username == username).toList();

    // If box has no items for this user (e.g. fresh register without seed), seed default 5
    if (userItems.isEmpty) {
      _seedDefaultItems(username);
      return;
    }

    items.assignAll(userItems);
  }

  /// [CREATE]: Adds a new custom grooming item to Hive
  Future<GroomingItemModel> addItem(String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Title cannot be empty');
    }

    final username = currentUsername;
    final newItem = GroomingItemModel(
      id: '${username}_${DateTime.now().millisecondsSinceEpoch}',
      username: username,
      title: trimmed,
      isChecked: false,
      isDefault: false,
    );

    await HiveService.groomingItemsBox.add(newItem);
    items.add(newItem);
    return newItem;
  }

  /// [UPDATE - Toggle]: Toggles isChecked state and persists to Hive
  Future<void> toggleItem(GroomingItemModel item) async {
    item.isChecked = !item.isChecked;
    if (item.isInBox) {
      await item.save();
    }
    items.refresh();
  }

  /// [UPDATE - Title]: Edits item title and persists to Hive
  Future<void> editItem(GroomingItemModel item, String newTitle) async {
    final trimmed = newTitle.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Title cannot be empty');
    }

    item.title = trimmed;
    if (item.isInBox) {
      await item.save();
    }
    items.refresh();
  }

  /// [DELETE]: Deletes an item from Hive
  Future<void> deleteItem(GroomingItemModel item) async {
    if (item.isInBox) {
      await item.delete();
    }
    items.remove(item);
  }

  // ==========================================
  // QUEST SUBMISSION & REWARDS
  // ==========================================

  /// Submits the daily grooming quest if minimum requirement is attained
  Future<QuestCompletionResult?> submitGrooming() async {
    if (isAlreadySubmitted) {
      if (!Get.testMode && Get.context != null) {
        Get.snackbar(
          'PROTOCOL COMMITTED',
          'Daily Grooming protocol already registered for today.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF151A26),
          colorText: const Color(0xFFF3F4F6),
        );
      }
      return null;
    }

    if (!isThresholdMet) {
      final remaining = minRequiredItems - completedCount;
      if (!Get.testMode && Get.context != null) {
        Get.snackbar(
          'QUOTA DEFICIENT',
          'Complete at least $remaining more objective(s) to satisfy the $minRequiredItems item quota.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF151A26),
          colorText: const Color(0xFFFF2A85),
        );
      }
      return null;
    }

    isLoading.value = true;
    try {
      final result = await QuestController.to.completeQuest(
        type: QuestType.grooming,
        repsCount: completedCount,
      );
      return result;
    } finally {
      isLoading.value = false;
    }
  }

  /// Helper to seed default 5 items if none exist
  void _seedDefaultItems(String username) {
    items.clear();
    for (int i = 0; i < GameConfig.defaultGroomingItems.length; i++) {
      final item = GroomingItemModel(
        id: '${username}_$i',
        username: username,
        title: GameConfig.defaultGroomingItems[i],
        isChecked: false,
        isDefault: true,
      );
      HiveService.groomingItemsBox.add(item);
      items.add(item);
    }
  }
}
