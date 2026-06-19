class DailyStats {
  const DailyStats({
    required this.date,
    required this.steps,
    required this.calories,
    required this.activeMinutes,
    required this.distanceKm,
    required this.workoutCount,
    required this.workoutMinutes,
  });

  final DateTime date;
  final int steps;
  final int calories;
  final int activeMinutes;
  final double distanceKm;
  final int workoutCount;
  final int workoutMinutes;
}

class WeeklyAnalytics {
  const WeeklyAnalytics({
    required this.dailySteps,
    required this.dailyCalories,
    required this.totalSteps,
    required this.totalCalories,
    required this.avgSteps,
    required this.avgCalories,
    required this.stepTrend,
    required this.calorieTrend,
  });

  final List<DailyStats> dailySteps;
  final List<int> dailyCalories;
  final int totalSteps;
  final int totalCalories;
  final double avgSteps;
  final double avgCalories;
  final double stepTrend;
  final double calorieTrend;
}
