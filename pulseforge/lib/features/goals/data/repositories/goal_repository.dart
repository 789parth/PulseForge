import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/goal.dart';

class GoalRepository {
  GoalRepository(this._db);

  final AppDatabase _db;

  Future<List<GoalModel>> getActive() async {
    final rows = await _db.getActiveGoals();
    return rows.map(_map).toList();
  }

  Future<List<GoalModel>> getAll() async {
    final rows = await _db.getAllGoals();
    return rows.map(_map).toList();
  }

  Future<void> upsert(GoalModel goal) async {
    await _db.upsertGoal(
      GoalsCompanion(
        id: goal.id != null ? Value(goal.id!) : const Value.absent(),
        type: Value(goal.type.key),
        target: Value(goal.target),
        isActive: Value(goal.isActive),
      ),
    );
  }

  Future<void> delete(int id) => _db.deleteGoal(id);

  Future<void> ensureDefaults() async {
    final existing = await getAll();
    if (existing.isNotEmpty) return;

    for (final type in GoalType.values) {
      await upsert(GoalModel(type: type, target: type.defaultTarget));
    }
  }

  GoalModel _map(Goal row) => GoalModel(
        id: row.id,
        type: GoalType.fromString(row.type),
        target: row.target,
        isActive: row.isActive,
      );
}
