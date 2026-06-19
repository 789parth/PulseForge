import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/workout.dart';

class WorkoutRepository {
  WorkoutRepository(this._db);

  final AppDatabase _db;

  Future<List<WorkoutModel>> getAll({
    String? type,
    DateTime? start,
    DateTime? end,
  }) async {
    final rows = await _db.getAllWorkouts(type: type, start: start, end: end);
    return rows.map(_map).toList();
  }

  Future<WorkoutModel?> getById(int id) async {
    final row = await _db.getWorkoutById(id);
    return row != null ? _map(row) : null;
  }

  Future<int> insert(WorkoutModel workout) {
    return _db.insertWorkout(
      WorkoutsCompanion.insert(
        type: workout.type.name,
        durationMinutes: workout.durationMinutes,
        calories: workout.calories,
        date: workout.date,
        notes: Value(workout.notes),
      ),
    );
  }

  Future<void> update(WorkoutModel workout) async {
    if (workout.id == null) return;
    await _db.updateWorkout(
      WorkoutsCompanion(
        id: Value(workout.id!),
        type: Value(workout.type.name),
        durationMinutes: Value(workout.durationMinutes),
        calories: Value(workout.calories),
        date: Value(workout.date),
        notes: Value(workout.notes),
      ),
    );
  }

  Future<void> delete(int id) => _db.deleteWorkout(id);

  WorkoutModel _map(Workout row) => WorkoutModel(
        id: row.id,
        type: WorkoutType.fromString(row.type),
        durationMinutes: row.durationMinutes,
        calories: row.calories,
        date: row.date,
        notes: row.notes,
      );
}
