import 'dart:math';

import '../../features/activity/data/repositories/step_repository.dart';
import '../../features/activity/domain/entities/step_entry.dart';
import '../../features/goals/data/repositories/goal_repository.dart';
import '../../features/workout/data/repositories/workout_repository.dart';
import '../../features/workout/domain/entities/workout.dart';

class SeedDataService {
  SeedDataService(this._steps, this._workouts, this._goals);

  final StepRepository _steps;
  final WorkoutRepository _workouts;
  final GoalRepository _goals;

  Future<void> seedIfEmpty() async {
    await _goals.ensureDefaults();

    final existing = await _steps.getToday();
    if (existing != null && existing.steps > 0) return;

    final random = Random(42);
    final now = DateTime.now();

    for (var i = 6; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final steps = 6000 + random.nextInt(6000);
      await _steps.upsert(
        StepEntryModel(
          date: date,
          steps: steps,
          calories: (steps * 0.04).round(),
          activeMinutes: 20 + random.nextInt(60),
          distanceKm: (steps * 0.762) / 1000,
        ),
      );
    }

    const workoutTypes = ['running', 'gym', 'yoga', 'cycling'];
    for (var i = 0; i < 5; i++) {
      final date = now.subtract(Duration(days: random.nextInt(14)));
      await _workouts.insert(
        WorkoutModel(
          type: WorkoutType.fromString(workoutTypes[random.nextInt(workoutTypes.length)]),
          durationMinutes: 20 + random.nextInt(50),
          calories: 150 + random.nextInt(350),
          date: date,
        ),
      );
    }
  }
}
