import '../../../../core/utils/analytics_compute.dart';
import '../../../activity/data/repositories/step_repository.dart';
import '../../../workout/data/repositories/workout_repository.dart';
import '../../domain/entities/analytics.dart';

class AnalyticsRepository {
  AnalyticsRepository(this._steps, this._workouts);

  final StepRepository _steps;
  final WorkoutRepository _workouts;

  Future<WeeklyAnalytics> getWeeklyAnalytics() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
    final end = now.add(const Duration(days: 1));

    final entries = await _steps.getRange(start, end);
    final workouts = await _workouts.getAll(start: start, end: end);

    final workoutCaloriesByDate = <String, int>{};
    final workoutCountByDate = <String, int>{};
    final workoutMinutesByDate = <String, int>{};
    for (final w in workouts) {
      final key = _dateKey(w.date);
      workoutCaloriesByDate[key] = (workoutCaloriesByDate[key] ?? 0) + w.calories;
      workoutCountByDate[key] = (workoutCountByDate[key] ?? 0) + 1;
      workoutMinutesByDate[key] = (workoutMinutesByDate[key] ?? 0) + w.durationMinutes;
    }

    return computeWeeklyAnalytics(
      AnalyticsComputeInput(
        entries: entries,
        workoutCaloriesByDate: workoutCaloriesByDate,
        workoutCountByDate: workoutCountByDate,
        workoutMinutesByDate: workoutMinutesByDate,
      ),
    );
  }

  Future<List<DailyStats>> getMonthlyStats() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);

    final entries = await _steps.getRange(start, end);
    final workouts = await _workouts.getAll(start: start, end: end);

    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final stats = <DailyStats>[];

    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(now.year, now.month, day);
      if (date.isAfter(now)) break;

      final entry = entries.where((e) => _isSameDay(e.date, date)).firstOrNull;

      final dayWorkouts = workouts.where((w) => _isSameDay(w.date, date)).toList();
      final workoutCal = dayWorkouts.fold<int>(0, (s, w) => s + w.calories);
      final workoutMin = dayWorkouts.fold<int>(0, (s, w) => s + w.durationMinutes);

      stats.add(
        DailyStats(
          date: date,
          steps: entry?.steps ?? 0,
          calories: (entry?.calories ?? 0) + workoutCal,
          activeMinutes: (entry?.activeMinutes ?? 0) + workoutMin,
          distanceKm: entry?.distanceKm ?? 0,
          workoutCount: dayWorkouts.length,
          workoutMinutes: workoutMin,
        ),
      );
    }

    return stats;
  }

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
