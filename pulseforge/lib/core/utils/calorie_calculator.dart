abstract final class CalorieCalculator {
  static const _strideLengthM = 0.762;
  static const _caloriesPerStep = 0.04;

  static int stepsToCalories(int steps) => (steps * _caloriesPerStep).round();

  static double stepsToDistanceKm(int steps) =>
      (steps * _strideLengthM) / 1000;

  static int estimateWorkoutCalories({
    required String type,
    required int durationMinutes,
    double weightKg = 70,
  }) {
    const metValues = {
      'running': 9.8,
      'gym': 6.0,
      'yoga': 3.0,
      'cycling': 7.5,
    };
    final met = metValues[type.toLowerCase()] ?? 5.0;
    return (met * weightKg * (durationMinutes / 60)).round();
  }
}
