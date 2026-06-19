import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../data/repositories/goal_repository.dart';
import '../../domain/entities/goal.dart';

final goalsProvider = FutureProvider<List<GoalModel>>((ref) async {
  await ref.watch(seedDataProvider.future);
  return ref.watch(goalRepositoryProvider).getAll();
});

class GoalsNotifier extends StateNotifier<AsyncValue<void>> {
  GoalsNotifier(this._repo) : super(const AsyncValue.data(null));

  final GoalRepository _repo;

  Future<void> updateGoal(GoalModel goal, int target) async {
    state = const AsyncValue.loading();
    try {
      await _repo.upsert(goal.copyWith(target: target));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final goalsNotifierProvider =
    StateNotifierProvider<GoalsNotifier, AsyncValue<void>>((ref) {
  return GoalsNotifier(ref.watch(goalRepositoryProvider));
});
