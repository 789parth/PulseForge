import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/utils/calorie_calculator.dart';
import '../../domain/entities/step_entry.dart';

class StepRepository {
  StepRepository(this._db);

  final AppDatabase _db;

  Future<StepEntryModel?> getToday() {
    final now = DateTime.now();
    return getForDate(DateTime(now.year, now.month, now.day));
  }

  Future<StepEntryModel?> getForDate(DateTime date) async {
    final row = await _db.getStepsForDate(date);
    return row != null ? _map(row) : null;
  }

  Future<List<StepEntryModel>> getRange(DateTime start, DateTime end) async {
    final rows = await _db.getStepsInRange(start, end);
    return rows.map(_map).toList();
  }

  Future<void> upsert(StepEntryModel entry) async {
    await _db.upsertSteps(
      StepEntriesCompanion(
        id: entry.id != null ? Value(entry.id!) : const Value.absent(),
        date: Value(_normalizeDate(entry.date)),
        steps: Value(entry.steps),
        calories: Value(entry.calories),
        activeMinutes: Value(entry.activeMinutes),
        distanceKm: Value(entry.distanceKm),
      ),
    );
  }

  Future<void> addSteps(int additionalSteps) async {
    final today = DateTime.now();
    final normalized = _normalizeDate(today);
    final existing = await getForDate(normalized);
    final newSteps = (existing?.steps ?? 0) + additionalSteps;
    await upsert(
      StepEntryModel(
        id: existing?.id,
        date: normalized,
        steps: newSteps,
        calories: _calcCalories(newSteps, existing),
        activeMinutes: existing?.activeMinutes ?? 0,
        distanceKm: CalorieCalculator.stepsToDistanceKm(newSteps),
      ),
    );
  }

  StepEntryModel _map(StepEntry row) => StepEntryModel(
        id: row.id,
        date: row.date,
        steps: row.steps,
        calories: row.calories,
        activeMinutes: row.activeMinutes,
        distanceKm: row.distanceKm,
      );

  DateTime _normalizeDate(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  int _calcCalories(int steps, StepEntryModel? existing) {
    if (existing != null && existing.steps > 0) {
      final ratio = steps / existing.steps;
      return (existing.calories * ratio).round();
    }
    return CalorieCalculator.stepsToCalories(steps);
  }
}
