import 'package:hive/hive.dart';
import '../core/constants/hive_boxes.dart';

part 'grooming_item_model.g.dart';

@HiveType(typeId: HiveBoxes.groomingItemTypeId)
class GroomingItemModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String username;

  @HiveField(2)
  String title;

  @HiveField(3)
  bool isChecked;

  @HiveField(4)
  bool isDefault;

  GroomingItemModel({
    required this.id,
    required this.username,
    required this.title,
    this.isChecked = false,
    this.isDefault = false,
  });
}
