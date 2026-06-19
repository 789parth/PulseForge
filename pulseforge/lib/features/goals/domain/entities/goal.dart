enum GoalType {
  steps('steps', 'Daily Steps', 10000),
  calories('calories', 'Daily Calories', 500);

  const GoalType(this.key, this.label, this.defaultTarget);
  final String key;
  final String label;
  final int defaultTarget;

  static GoalType fromString(String value) {
    return GoalType.values.firstWhere(
      (g) => g.key == value,
      orElse: () => GoalType.steps,
    );
  }
}

class GoalModel {
  const GoalModel({
    this.id,
    required this.type,
    required this.target,
    this.isActive = true,
  });

  final int? id;
  final GoalType type;
  final int target;
  final bool isActive;

  GoalModel copyWith({
    int? id,
    GoalType? type,
    int? target,
    bool? isActive,
  }) {
    return GoalModel(
      id: id ?? this.id,
      type: type ?? this.type,
      target: target ?? this.target,
      isActive: isActive ?? this.isActive,
    );
  }
}
