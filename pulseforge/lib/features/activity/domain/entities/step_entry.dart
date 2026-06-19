class StepEntryModel {
  const StepEntryModel({
    this.id,
    required this.date,
    required this.steps,
    required this.calories,
    required this.activeMinutes,
    required this.distanceKm,
  });

  final int? id;
  final DateTime date;
  final int steps;
  final int calories;
  final int activeMinutes;
  final double distanceKm;

  StepEntryModel copyWith({
    int? id,
    DateTime? date,
    int? steps,
    int? calories,
    int? activeMinutes,
    double? distanceKm,
  }) {
    return StepEntryModel(
      id: id ?? this.id,
      date: date ?? this.date,
      steps: steps ?? this.steps,
      calories: calories ?? this.calories,
      activeMinutes: activeMinutes ?? this.activeMinutes,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }
}
