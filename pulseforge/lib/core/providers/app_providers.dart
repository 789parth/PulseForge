import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/app_database.dart';
import '../services/seed_data_service.dart';
import '../../features/activity/data/repositories/step_repository.dart';
import '../../features/analytics/data/repositories/analytics_repository.dart';
import '../../features/goals/data/repositories/goal_repository.dart';
import '../../features/workout/data/repositories/workout_repository.dart';

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final stepRepositoryProvider = Provider<StepRepository>((ref) {
  return StepRepository(ref.watch(databaseProvider));
});

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  return WorkoutRepository(ref.watch(databaseProvider));
});

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return GoalRepository(ref.watch(databaseProvider));
});

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepository(
    ref.watch(stepRepositoryProvider),
    ref.watch(workoutRepositoryProvider),
  );
});

final seedDataProvider = FutureProvider<void>((ref) async {
  final service = SeedDataService(
    ref.watch(stepRepositoryProvider),
    ref.watch(workoutRepositoryProvider),
    ref.watch(goalRepositoryProvider),
  );
  await service.seedIfEmpty();
});

final onboardingCompleteProvider =
    StateNotifierProvider<OnboardingNotifier, AsyncValue<bool>>((ref) {
  return OnboardingNotifier(ref);
});

class OnboardingNotifier extends StateNotifier<AsyncValue<bool>> {
  OnboardingNotifier(this._ref) : super(const AsyncValue.loading()) {
    _load();
  }

  final Ref _ref;
  static const _key = 'onboarding_complete';

  Future<void> _load() async {
    final prefs = await _ref.read(sharedPreferencesProvider.future);
    state = AsyncValue.data(prefs.getBool(_key) ?? false);
  }

  Future<void> complete() async {
    final prefs = await _ref.read(sharedPreferencesProvider.future);
    await prefs.setBool(_key, true);
    state = const AsyncValue.data(true);
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, AsyncValue<bool>>((ref) {
  return ThemeModeNotifier(ref);
});

class ThemeModeNotifier extends StateNotifier<AsyncValue<bool>> {
  ThemeModeNotifier(this._ref) : super(const AsyncValue.loading()) {
    _load();
  }

  final Ref _ref;
  static const _key = 'dark_mode';

  Future<void> _load() async {
    final prefs = await _ref.read(sharedPreferencesProvider.future);
    state = AsyncValue.data(prefs.getBool(_key) ?? true);
  }

  Future<void> toggle() async {
    final current = state.value ?? true;
    final prefs = await _ref.read(sharedPreferencesProvider.future);
    await prefs.setBool(_key, !current);
    state = AsyncValue.data(!current);
  }
}

final hapticsEnabledProvider =
    StateNotifierProvider<HapticsNotifier, AsyncValue<bool>>((ref) {
  return HapticsNotifier(ref);
});

class HapticsNotifier extends StateNotifier<AsyncValue<bool>> {
  HapticsNotifier(this._ref) : super(const AsyncValue.loading()) {
    _load();
  }

  final Ref _ref;
  static const _key = 'haptics_enabled';

  Future<void> _load() async {
    final prefs = await _ref.read(sharedPreferencesProvider.future);
    state = AsyncValue.data(prefs.getBool(_key) ?? true);
  }

  Future<void> toggle() async {
    final current = state.value ?? true;
    final prefs = await _ref.read(sharedPreferencesProvider.future);
    await prefs.setBool(_key, !current);
    state = AsyncValue.data(!current);
  }
}
