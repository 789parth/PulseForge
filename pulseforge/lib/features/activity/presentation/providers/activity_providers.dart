import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/utils/calorie_calculator.dart';
import '../../data/repositories/step_repository.dart';
import '../../domain/entities/step_entry.dart';
import '../../../goals/domain/entities/goal.dart';

final todayStepsProvider = FutureProvider<StepEntryModel?>((ref) async {
  await ref.watch(seedDataProvider.future);
  return ref.watch(stepRepositoryProvider).getToday();
});

final weeklyStepsProvider = FutureProvider<List<StepEntryModel>>((ref) async {
  await ref.watch(seedDataProvider.future);
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
  return ref.watch(stepRepositoryProvider).getRange(start, now.add(const Duration(days: 1)));
});

class ActivityTrackingNotifier extends StateNotifier<ActivityState> {
  ActivityTrackingNotifier(this._repo) : super(const ActivityState());

  final StepRepository _repo;

  void startTracking() {
    if (state.isTracking) return;
    state = state.copyWith(
      isTracking: true,
      startTime: DateTime.now(),
      baseSteps: state.currentSteps,
    );
    _tick();
  }

  void stopTracking() {
    state = state.copyWith(isTracking: false);
  }

  void _tick() async {
    while (state.isTracking) {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted || !state.isTracking) break;
      final elapsed = DateTime.now().difference(state.startTime!).inSeconds;
      final simulated = state.baseSteps + (elapsed * 2);
      state = state.copyWith(
        currentSteps: simulated,
        distanceKm: CalorieCalculator.stepsToDistanceKm(simulated),
        calories: CalorieCalculator.stepsToCalories(simulated),
        activeMinutes: elapsed ~/ 60,
      );
    }
  }

  Future<void> saveProgress() async {
    final now = DateTime.now();
    await _repo.upsert(
      StepEntryModel(
        date: DateTime(now.year, now.month, now.day),
        steps: state.currentSteps,
        calories: state.calories,
        activeMinutes: state.activeMinutes,
        distanceKm: state.distanceKm,
      ),
    );
  }

  Future<void> loadToday() async {
    final today = await _repo.getToday();
    if (today != null) {
      state = state.copyWith(
        currentSteps: today.steps,
        calories: today.calories,
        activeMinutes: today.activeMinutes,
        distanceKm: today.distanceKm,
        baseSteps: today.steps,
      );
    }
  }
}

class ActivityState {
  const ActivityState({
    this.isTracking = false,
    this.currentSteps = 0,
    this.calories = 0,
    this.activeMinutes = 0,
    this.distanceKm = 0,
    this.baseSteps = 0,
    this.startTime,
  });

  final bool isTracking;
  final int currentSteps;
  final int calories;
  final int activeMinutes;
  final double distanceKm;
  final int baseSteps;
  final DateTime? startTime;

  ActivityState copyWith({
    bool? isTracking,
    int? currentSteps,
    int? calories,
    int? activeMinutes,
    double? distanceKm,
    int? baseSteps,
    DateTime? startTime,
  }) {
    return ActivityState(
      isTracking: isTracking ?? this.isTracking,
      currentSteps: currentSteps ?? this.currentSteps,
      calories: calories ?? this.calories,
      activeMinutes: activeMinutes ?? this.activeMinutes,
      distanceKm: distanceKm ?? this.distanceKm,
      baseSteps: baseSteps ?? this.baseSteps,
      startTime: startTime ?? this.startTime,
    );
  }
}

final activityTrackingProvider =
    StateNotifierProvider<ActivityTrackingNotifier, ActivityState>((ref) {
  return ActivityTrackingNotifier(ref.watch(stepRepositoryProvider));
});

final goalsWithProgressProvider = FutureProvider<List<GoalProgress>>((ref) async {
  await ref.watch(seedDataProvider.future);
  final goals = await ref.watch(goalRepositoryProvider).getActive();
  final today = await ref.watch(stepRepositoryProvider).getToday();

  final now = DateTime.now();
  final dayStart = DateTime(now.year, now.month, now.day);
  final dayEnd = dayStart.add(const Duration(days: 1));
  final todayWorkouts = await ref.read(workoutRepositoryProvider).getAll(
        start: dayStart,
        end: dayEnd,
      );
  final workoutCalories =
      todayWorkouts.fold<int>(0, (sum, workout) => sum + workout.calories);

  return goals.map((goal) {
    final current = switch (goal.type) {
      GoalType.steps => today?.steps ?? 0,
      GoalType.calories => (today?.calories ?? 0) + workoutCalories,
    };
    return GoalProgress(goal: goal, current: current);
  }).toList();
});

class GoalProgress {
  const GoalProgress({required this.goal, required this.current});

  final GoalModel goal;
  final int current;

  double get progress => goal.target > 0 ? (current / goal.target).clamp(0.0, 1.0) : 0;
}
