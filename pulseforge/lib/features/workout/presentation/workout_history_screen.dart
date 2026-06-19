import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/gradient_background.dart';
import '../domain/entities/workout.dart';
import 'providers/workout_providers.dart';

enum _WorkoutDateRange { all, week, month }

class WorkoutHistoryScreen extends ConsumerStatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  ConsumerState<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends ConsumerState<WorkoutHistoryScreen> {
  WorkoutType? _filterType;
  _WorkoutDateRange _dateRange = _WorkoutDateRange.all;

  WorkoutFilter get _filter {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return switch (_dateRange) {
      _WorkoutDateRange.all => WorkoutFilter(type: _filterType),
      _WorkoutDateRange.week => WorkoutFilter(
          type: _filterType,
          start: today.subtract(const Duration(days: 6)),
          end: today.add(const Duration(days: 1)),
        ),
      _WorkoutDateRange.month => WorkoutFilter(
          type: _filterType,
          start: DateTime(now.year, now.month, 1),
          end: today.add(const Duration(days: 1)),
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final workoutsAsync = ref.watch(workoutsProvider(_filter));

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: Text(
                      'Workouts',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.push('/workouts/add'),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                children: [
                  _FilterChip(
                    label: 'All Time',
                    selected: _dateRange == _WorkoutDateRange.all,
                    onTap: () => setState(() => _dateRange = _WorkoutDateRange.all),
                  ),
                  _FilterChip(
                    label: 'This Week',
                    selected: _dateRange == _WorkoutDateRange.week,
                    onTap: () => setState(() => _dateRange = _WorkoutDateRange.week),
                  ),
                  _FilterChip(
                    label: 'This Month',
                    selected: _dateRange == _WorkoutDateRange.month,
                    onTap: () => setState(() => _dateRange = _WorkoutDateRange.month),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                children: [
                  _FilterChip(
                    label: 'All Types',
                    selected: _filterType == null,
                    onTap: () => setState(() => _filterType = null),
                  ),
                  ...WorkoutType.values.map(
                    (t) => _FilterChip(
                      label: t.label,
                      selected: _filterType == t,
                      onTap: () => setState(() => _filterType = t),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: workoutsAsync.when(
                loading: () => ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  itemCount: 5,
                  itemBuilder: (context, index) => const Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.sm),
                    child: SkeletonLoader(height: 80, borderRadius: AppSpacing.radiusMd),
                  ),
                ),
                error: (e, stackTrace) => Center(
                  child: ErrorState(
                    message: 'Failed to load workouts',
                    onRetry: () => ref.invalidate(workoutsProvider(_filter)),
                  ),
                ),
                data: (workouts) {
                  if (workouts.isEmpty) {
                    return EmptyState(
                      icon: Icons.fitness_center,
                      title: 'No Workouts Yet',
                      subtitle: 'Start logging your training sessions to see them here.',
                      action: TextButton(
                        onPressed: () => context.push('/workouts/add'),
                        child: const Text('Add Workout'),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.xxl,
                    ),
                    itemCount: workouts.length,
                    itemBuilder: (context, index) {
                      final workout = workouts[index];
                      return _WorkoutTile(
                        workout: workout,
                        onTap: workout.id == null
                            ? null
                            : () => context.push('/workouts/${workout.id}'),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primaryBlue.withValues(alpha: 0.2),
        checkmarkColor: AppColors.primaryBlue,
      ),
    );
  }
}

class _WorkoutTile extends StatelessWidget {
  const _WorkoutTile({required this.workout, this.onTap});

  final WorkoutModel workout;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GlassCard(
        onTap: onTap,
        child: Row(
          children: [
            Text(workout.type.emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workout.type.label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    DateFormat('MMM d, yyyy • h:mm a').format(workout.date),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${workout.durationMinutes} min',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${workout.calories} kcal',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.warning,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
