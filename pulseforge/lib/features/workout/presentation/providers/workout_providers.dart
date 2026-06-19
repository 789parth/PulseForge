import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/utils/calorie_calculator.dart';
import '../../data/repositories/workout_repository.dart';
import '../../domain/entities/workout.dart';
import '../../../analytics/presentation/providers/analytics_providers.dart';

final workoutsProvider = FutureProvider.family<List<WorkoutModel>, WorkoutFilter>(
  (ref, filter) async {
    await ref.watch(seedDataProvider.future);
    return ref.watch(workoutRepositoryProvider).getAll(
          type: filter.type?.name,
          start: filter.start,
          end: filter.end,
        );
  },
);

final workoutDetailProvider = FutureProvider.family<WorkoutModel?, int>((ref, id) async {
  await ref.watch(seedDataProvider.future);
  return ref.watch(workoutRepositoryProvider).getById(id);
});

class WorkoutFilter {
  const WorkoutFilter({this.type, this.start, this.end});

  final WorkoutType? type;
  final DateTime? start;
  final DateTime? end;

  @override
  bool operator ==(Object other) =>
      other is WorkoutFilter &&
      other.type == type &&
      other.start == start &&
      other.end == end;

  @override
  int get hashCode => Object.hash(type, start, end);
}

void invalidateWorkoutCaches(WidgetRef ref) {
  ref.invalidate(workoutsProvider);
  ref.invalidate(weeklyAnalyticsProvider);
  ref.invalidate(monthlyStatsProvider);
}

class WorkoutFormNotifier extends StateNotifier<WorkoutFormState> {
  WorkoutFormNotifier(this._repo)
      : super(
          WorkoutFormState(
            calories: CalorieCalculator.estimateWorkoutCalories(
              type: WorkoutType.running.name,
              durationMinutes: 30,
            ),
          ),
        );

  final WorkoutRepository _repo;

  void setType(WorkoutType type) {
    state = state.copyWith(type: type, clearError: true);
    _updateCalories();
  }

  void setDuration(String value) {
    final parsed = int.tryParse(value);
    if (parsed == null) return;
    state = state.copyWith(durationMinutes: parsed, clearError: true);
    _updateCalories();
  }

  void setCalories(String value) {
    final parsed = int.tryParse(value);
    if (parsed == null) return;
    state = state.copyWith(
      calories: parsed,
      autoCalories: false,
      clearError: true,
    );
  }

  void setNotes(String value) => state = state.copyWith(notes: value);

  void resetAutoCalories() {
    state = state.copyWith(autoCalories: true, clearError: true);
    _updateCalories();
  }

  void _updateCalories() {
    if (!state.autoCalories) return;
    state = state.copyWith(
      calories: CalorieCalculator.estimateWorkoutCalories(
        type: state.type.name,
        durationMinutes: state.durationMinutes,
      ),
    );
  }

  String? validate() {
    if (state.durationMinutes <= 0) return 'Duration must be greater than 0';
    if (state.calories <= 0) return 'Calories must be greater than 0';
    return null;
  }

  Future<bool> save() async {
    final error = validate();
    if (error != null) {
      state = state.copyWith(error: error);
      return false;
    }
    try {
      await _repo.insert(
        WorkoutModel(
          type: state.type,
          durationMinutes: state.durationMinutes,
          calories: state.calories,
          date: DateTime.now(),
          notes: state.notes.isEmpty ? null : state.notes,
        ),
      );
      return true;
    } catch (_) {
      state = state.copyWith(error: 'Failed to save workout. Please try again.');
      return false;
    }
  }
}

class WorkoutFormState {
  const WorkoutFormState({
    this.type = WorkoutType.running,
    this.durationMinutes = 30,
    this.calories = 0,
    this.notes = '',
    this.autoCalories = true,
    this.error,
  });

  final WorkoutType type;
  final int durationMinutes;
  final int calories;
  final String notes;
  final bool autoCalories;
  final String? error;

  WorkoutFormState copyWith({
    WorkoutType? type,
    int? durationMinutes,
    int? calories,
    String? notes,
    bool? autoCalories,
    String? error,
    bool clearError = false,
  }) {
    return WorkoutFormState(
      type: type ?? this.type,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      calories: calories ?? this.calories,
      notes: notes ?? this.notes,
      autoCalories: autoCalories ?? this.autoCalories,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final workoutFormProvider =
    StateNotifierProvider.autoDispose<WorkoutFormNotifier, WorkoutFormState>((ref) {
  return WorkoutFormNotifier(ref.watch(workoutRepositoryProvider));
});
