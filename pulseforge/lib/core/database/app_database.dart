import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [StepEntries, Workouts, Goals])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _createIndices();
        },
        onUpgrade: (m, from, to) async {
          // Drop tables in local dev database to migrate schema to version 2 safely.
          await customStatement('DROP TABLE IF EXISTS step_entries;');
          await customStatement('DROP TABLE IF EXISTS workouts;');
          await customStatement('DROP TABLE IF EXISTS goals;');
          await m.createAll();
          await _createIndices();
        },
      );

  Future<void> _createIndices() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_steps_date ON step_entries(date)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_workouts_date ON workouts(date)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_workouts_type ON workouts(type)',
    );
  }

  Future<StepEntry?> getStepsForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(stepEntries)
          ..where((t) => t.date.isBiggerOrEqualValue(start) & t.date.isSmallerThanValue(end)))
        .getSingleOrNull();
  }

  Future<List<StepEntry>> getStepsInRange(DateTime start, DateTime end) {
    return (select(stepEntries)
          ..where((t) => t.date.isBiggerOrEqualValue(start) & t.date.isSmallerThanValue(end))
          ..orderBy([(t) => OrderingTerm.asc(t.date)]))
        .get();
  }

  Future<int> upsertSteps(StepEntriesCompanion entry) {
    return into(stepEntries).insertOnConflictUpdate(entry);
  }

  Future<List<Workout>> getAllWorkouts({String? type, DateTime? start, DateTime? end}) {
    return (select(workouts)
          ..where((t) {
            Expression<bool> condition = const Constant(true);
            if (type != null && type.isNotEmpty) {
              condition = condition & t.type.equals(type);
            }
            if (start != null) {
              condition = condition & t.date.isBiggerOrEqualValue(start);
            }
            if (end != null) {
              condition = condition & t.date.isSmallerThanValue(end);
            }
            return condition;
          })
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  Future<Workout?> getWorkoutById(int id) {
    return (select(workouts)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertWorkout(WorkoutsCompanion workout) {
    return into(workouts).insert(workout);
  }

  Future<bool> updateWorkout(WorkoutsCompanion workout) {
    return update(workouts).replace(workout);
  }

  Future<int> deleteWorkout(int id) {
    return (delete(workouts)..where((t) => t.id.equals(id))).go();
  }

  Future<List<Goal>> getActiveGoals() {
    return (select(goals)..where((t) => t.isActive.equals(true))).get();
  }

  Future<List<Goal>> getAllGoals() => select(goals).get();

  Future<int> upsertGoal(GoalsCompanion goal) {
    return into(goals).insertOnConflictUpdate(goal);
  }

  Future<int> deleteGoal(int id) {
    return (delete(goals)..where((t) => t.id.equals(id))).go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'pulseforge.db'));
    return NativeDatabase(file);
  });
}
