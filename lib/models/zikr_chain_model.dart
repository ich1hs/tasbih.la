import 'package:hive/hive.dart';

part 'zikr_chain_model.g.dart';

/// A single step in a zikr chain
@HiveType(typeId: 2)
class ChainStep extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  int targetCount;

  @HiveField(2)
  int currentCount;

  @HiveField(3)
  String? ayahText;

  ChainStep({
    required this.name,
    required this.targetCount,
    this.currentCount = 0,
    this.ayahText,
  });

  double get progress => targetCount > 0 
      ? (currentCount / targetCount).clamp(0.0, 1.0) 
      : 0.0;

  bool get isCompleted => currentCount >= targetCount;

  void increment() => currentCount++;
  
  void reset() => currentCount = 0;

  ChainStep copyWith({
    String? name,
    int? targetCount,
    int? currentCount,
    String? ayahText,
  }) {
    return ChainStep(
      name: name ?? this.name,
      targetCount: targetCount ?? this.targetCount,
      currentCount: currentCount ?? this.currentCount,
      ayahText: ayahText ?? this.ayahText,
    );
  }
}

/// A chain of multiple zikr that auto-progresses
@HiveType(typeId: 1)
class ZikrChainModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  List<ChainStep> steps;

  @HiveField(3)
  int currentStepIndex;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  DateTime lastUpdated;

  @HiveField(6)
  bool isBuiltIn; // For Tasbih Fatimah etc.

  ZikrChainModel({
    required this.id,
    required this.name,
    required this.steps,
    this.currentStepIndex = 0,
    this.isBuiltIn = false,
    DateTime? createdAt,
    DateTime? lastUpdated,
  })  : createdAt = createdAt ?? DateTime.now(),
        lastUpdated = lastUpdated ?? DateTime.now();

  /// Current active step
  ChainStep get currentStep => steps[currentStepIndex];

  /// Overall progress across all steps
  double get overallProgress {
    if (steps.isEmpty) return 0.0;
    
    int totalTarget = steps.fold(0, (sum, s) => sum + s.targetCount);
    int totalCurrent = steps.fold(0, (sum, s) => sum + s.currentCount);
    
    return totalTarget > 0 ? (totalCurrent / totalTarget).clamp(0.0, 1.0) : 0.0;
  }

  /// Is the entire chain completed?
  bool get isCompleted => 
      currentStepIndex >= steps.length - 1 && currentStep.isCompleted;

  /// Increment current step, auto-advance if completed
  /// Returns true if advanced to next step
  bool increment() {
    currentStep.increment();
    lastUpdated = DateTime.now();
    
    // Auto-advance to next step if current is completed
    if (currentStep.isCompleted && currentStepIndex < steps.length - 1) {
      currentStepIndex++;
      return true; // Stepped to next
    }
    return false;
  }

  /// Reset entire chain
  void reset() {
    currentStepIndex = 0;
    for (var step in steps) {
      step.reset();
    }
    lastUpdated = DateTime.now();
  }

  /// Factory for Tasbih Fatimah
  factory ZikrChainModel.tasbihFatimah({
    int subhanAllahCount = 33,
    int alhamdulillahCount = 33,
    int allahuAkbarCount = 34,
  }) {
    return ZikrChainModel(
      id: 'tasbih_fatimah',
      name: 'Tasbih Fatimah',
      isBuiltIn: true,
      steps: [
        ChainStep(
          name: 'SubhanAllah',
          targetCount: subhanAllahCount,
          ayahText: 'سُبْحَانَ اللَّهِ',
        ),
        ChainStep(
          name: 'Alhamdulillah',
          targetCount: alhamdulillahCount,
          ayahText: 'الْحَمْدُ لِلَّهِ',
        ),
        ChainStep(
          name: 'Allahu Akbar',
          targetCount: allahuAkbarCount,
          ayahText: 'اللَّهُ أَكْبَرُ',
        ),
      ],
    );
  }

  ZikrChainModel copyWith({
    String? id,
    String? name,
    List<ChainStep>? steps,
    int? currentStepIndex,
    bool? isBuiltIn,
  }) {
    return ZikrChainModel(
      id: id ?? this.id,
      name: name ?? this.name,
      steps: steps ?? this.steps.map((s) => s.copyWith()).toList(),
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      createdAt: createdAt,
      lastUpdated: DateTime.now(),
    );
  }
}
