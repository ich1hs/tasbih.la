import 'package:hive/hive.dart';

part 'zikr_model.g.dart';

@HiveType(typeId: 0)
class ZikrModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int targetCount;

  @HiveField(3)
  int currentCount;

  @HiveField(4)
  String? ayahText;

  @HiveField(5)
  String? ayahImagePath;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  DateTime lastUpdated;

  ZikrModel({
    required this.id,
    required this.name,
    required this.targetCount,
    this.currentCount = 0,
    this.ayahText,
    this.ayahImagePath,
    DateTime? createdAt,
    DateTime? lastUpdated,
  }) : createdAt = createdAt ?? DateTime.now(),
       lastUpdated = lastUpdated ?? DateTime.now();

  double get progress => targetCount > 0 
      ? (currentCount / targetCount).clamp(0.0, 1.0) 
      : 0.0;

  bool get isCompleted => currentCount >= targetCount;

  void increment() {
    currentCount++;
    lastUpdated = DateTime.now();
  }

  void reset() {
    currentCount = 0;
    lastUpdated = DateTime.now();
  }

  ZikrModel copyWith({
    String? id,
    String? name,
    int? targetCount,
    int? currentCount,
    String? ayahText,
    String? ayahImagePath,
    DateTime? createdAt,
    DateTime? lastUpdated,
  }) {
    return ZikrModel(
      id: id ?? this.id,
      name: name ?? this.name,
      targetCount: targetCount ?? this.targetCount,
      currentCount: currentCount ?? this.currentCount,
      ayahText: ayahText ?? this.ayahText,
      ayahImagePath: ayahImagePath ?? this.ayahImagePath,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
