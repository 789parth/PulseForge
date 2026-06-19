// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:pulseforge/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:pulseforge/core/services/seed_data_service.dart';
import 'package:pulseforge/features/activity/data/repositories/step_repository.dart';
import 'package:pulseforge/features/workout/data/repositories/workout_repository.dart';
import 'package:pulseforge/features/goals/data/repositories/goal_repository.dart';

void main() {
  test('Database queries and seed test', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());

    try {
      final stepsRepo = StepRepository(db);
      final workoutsRepo = WorkoutRepository(db);
      final goalsRepo = GoalRepository(db);

      final seeder = SeedDataService(stepsRepo, workoutsRepo, goalsRepo);

      // Verify seeding runs without exceptions
      await seeder.seedIfEmpty();
      print('Seeding completed successfully!');

      // Verify queries run
      final goals = await goalsRepo.getAll();
      print('Goals count: ${goals.length}');
      expect(goals.length, greaterThan(0));

      final todaySteps = await stepsRepo.getToday();
      print('Today steps: ${todaySteps?.steps}');
      expect(todaySteps, isNotNull);

      final workouts = await workoutsRepo.getAll();
      print('Workouts count: ${workouts.length}');
      expect(workouts.length, greaterThan(0));

    } catch (e, stack) {
      print('DB Test Exception: $e');
      print(stack);
      rethrow;
    } finally {
      await db.close();
    }
  });
}
