enum WorkoutType {
  running('Running', '🏃'),
  gym('Gym', '💪'),
  yoga('Yoga', '🧘'),
  cycling('Cycling', '🚴');

  const WorkoutType(this.label, this.emoji);
  final String label;
  final String emoji;

  static WorkoutType fromString(String value) {
    return WorkoutType.values.firstWhere(
      (t) => t.name == value.toLowerCase() || t.label.toLowerCase() == value.toLowerCase(),
      orElse: () => WorkoutType.running,
    );
  }
}

class WorkoutModel {
  const WorkoutModel({
    this.id,
    required this.type,
    required this.durationMinutes,
    required this.calories,
    required this.date,
    this.notes,
  });

  final int? id;
  final WorkoutType type;
  final int durationMinutes;
  final int calories;
  final DateTime date;
  final String? notes;

  WorkoutModel copyWith({
    int? id,
    WorkoutType? type,
    int? durationMinutes,
    int? calories,
    DateTime? date,
    String? notes,
  }) {
    return WorkoutModel(
      id: id ?? this.id,
      type: type ?? this.type,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      calories: calories ?? this.calories,
      date: date ?? this.date,
      notes: notes ?? this.notes,
    );
  }
}
