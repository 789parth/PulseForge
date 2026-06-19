import 'package:flutter/foundation.dart';

import '../../features/analytics/domain/entities/analytics.dart';
import '../../features/activity/domain/entities/step_entry.dart';

class AnalyticsComputeInput {
  const AnalyticsComputeInput({
    required this.entries,
    required this.workoutCaloriesByDate,
    this.workoutCountByDate = const {},
    this.workoutMinutesByDate = const {},
  });

  final List<StepEntryModel> entries;
  final Map<String, int> workoutCaloriesByDate;
  final Map<String, int> workoutCountByDate;
  final Map<String, int> workoutMinutesByDate;
}

Future<WeeklyAnalytics> computeWeeklyAnalytics(AnalyticsComputeInput input) {
  return compute(_computeWeeklyAnalytics, input);
}

WeeklyAnalytics _computeWeeklyAnalytics(AnalyticsComputeInput input) {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));

  final dailyStats = <DailyStats>[];
  final dailyCalories = <int>[];

  for (var i = 0; i < 7; i++) {
    final date = start.add(Duration(days: i));
    final key = _dateKey(date);
    final entry = input.entries.where((e) => _isSameDay(e.date, date)).firstOrNull;
    final workoutCal = input.workoutCaloriesByDate[key] ?? 0;
    final steps = entry?.steps ?? 0;
    final cal = (entry?.calories ?? 0) + workoutCal;

    dailyStats.add(
      DailyStats(
        date: date,
        steps: steps,
        calories: cal,
        activeMinutes: entry?.activeMinutes ?? 0,
        distanceKm: entry?.distanceKm ?? 0,
        workoutCount: input.workoutCountByDate[key] ?? 0,
        workoutMinutes: input.workoutMinutesByDate[key] ?? 0,
      ),
    );
    dailyCalories.add(cal);
  }

  final totalSteps = dailyStats.fold<int>(0, (s, d) => s + d.steps);
  final totalCalories = dailyCalories.fold<int>(0, (s, c) => s + c);

  final firstHalf = dailyStats.take(3).fold<int>(0, (s, d) => s + d.steps);
  final secondHalf = dailyStats.skip(4).fold<int>(0, (s, d) => s + d.steps);
  final stepTrend = firstHalf > 0 ? ((secondHalf - firstHalf) / firstHalf) * 100 : 0.0;

  final firstCal = dailyCalories.take(3).fold<int>(0, (s, c) => s + c);
  final secondCal = dailyCalories.skip(4).fold<int>(0, (s, c) => s + c);
  final calorieTrend = firstCal > 0 ? ((secondCal - firstCal) / firstCal) * 100 : 0.0;

  return WeeklyAnalytics(
    dailySteps: dailyStats,
    dailyCalories: dailyCalories,
    totalSteps: totalSteps,
    totalCalories: totalCalories,
    avgSteps: totalSteps / 7,
    avgCalories: totalCalories / 7,
    stepTrend: stepTrend,
    calorieTrend: calorieTrend,
  );
}

String _dateKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
