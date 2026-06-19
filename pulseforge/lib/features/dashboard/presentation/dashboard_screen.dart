import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/animated_progress_ring.dart';
import '../../../core/widgets/charts.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/gradient_background.dart';
import '../../../core/widgets/manual_entry_sheet.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/stat_card.dart';
import '../../activity/presentation/providers/activity_providers.dart';
import '../../analytics/presentation/providers/analytics_providers.dart';
import '../../goals/domain/entities/goal.dart';
import '../../workout/presentation/providers/workout_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(todayStepsProvider);
    final goalsAsync = ref.watch(goalsWithProgressProvider);
    final weeklyAsync = ref.watch(weeklyAnalyticsProvider);
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    final workoutsAsync = ref.watch(
      workoutsProvider(WorkoutFilter(start: todayStart, end: todayEnd)),
    );

    return GradientBackground(
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting(),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      'PulseForge',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: todayAsync.when(
                  loading: () => const _DashboardSkeleton(),
                  error: (e, _) => const SizedBox.shrink(),
                  data: (today) {
                    final steps = today?.steps ?? 0;
                    final calories = today?.calories ?? 0;
                    final activeMin = today?.activeMinutes ?? 0;
                    final stepTarget = goalsAsync.valueOrNull
                            ?.where((g) => g.goal.type == GoalType.steps)
                            .map((g) => g.goal.target)
                            .firstOrNull ??
                        GoalType.steps.defaultTarget;

                    return RepaintBoundary(
                      child: GlassCard(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Row(
                          children: [
                            AnimatedProgressRing(
                              progress: stepTarget > 0 ? steps / stepTarget : 0,
                              size: 120,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _formatNumber(steps),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  Text(
                                    'steps',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.lg),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _MiniStat(label: 'Calories', value: '$calories kcal'),
                                  const SizedBox(height: AppSpacing.sm),
                                  _MiniStat(label: 'Active', value: '$activeMin min'),
                                  const SizedBox(height: AppSpacing.sm),
                                  workoutsAsync.when(
                                    loading: () => const SizedBox.shrink(),
                                    error: (_, _) => const SizedBox.shrink(),
                                    data: (workouts) {
                                      final todayCount = workouts
                                          .where((w) => _isToday(w.date))
                                          .length;
                                      return _MiniStat(
                                        label: 'Workouts',
                                        value: '$todayCount today',
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: todayAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (today) {
                    return Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            label: 'Steps',
                            value: _formatNumber(today?.steps ?? 0),
                            icon: Icons.directions_walk,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: StatCard(
                            label: 'Calories',
                            value: '${today?.calories ?? 0}',
                            unit: 'kcal',
                            icon: Icons.local_fire_department,
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: goalsAsync.when(
                  loading: () => const SkeletonLoader(height: 80),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (goals) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Goals', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: AppSpacing.sm),
                      ...goals.map(
                        (g) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _GoalBar(
                            label: g.goal.type.label,
                            progress: g.progress,
                            current: g.current,
                            target: g.goal.target,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: weeklyAsync.when(
                  loading: () => const SkeletonLoader(height: 180),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (analytics) {
                    final labels = analytics.dailySteps
                        .map((d) => DateFormat('E').format(d.date).substring(0, 1))
                        .toList();
                    final values =
                        analytics.dailySteps.map((d) => d.steps.toDouble()).toList();

                    return GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Weekly Progress',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              TrendBadge(trend: analytics.stepTrend),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          WeeklyLineChart(values: values, labels: labels),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.xxl,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: PfButton(
                        label: 'Add Steps',
                        icon: Icons.add,
                        outlined: true,
                        onPressed: () => showManualEntrySheet(
                          context,
                          ref,
                          type: ManualEntryType.steps,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: PfButton(
                        label: 'Workout',
                        icon: Icons.fitness_center,
                        onPressed: () => context.push('/workouts/add'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  String _formatNumber(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _GoalBar extends StatelessWidget {
  const _GoalBar({
    required this.label,
    required this.progress,
    required this.current,
    required this.target,
  });

  final String label;
  final double progress;
  final int current;
  final int target;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text('$current / $target'),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: progress * 0.6, end: progress),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (_, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor: AppColors.surfaceLight,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primaryBlue),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const GlassCard(
      child: Row(
        children: [
          SkeletonLoader(width: 120, height: 120, borderRadius: 60),
          SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(height: 20),
                SizedBox(height: 12),
                SkeletonLoader(height: 20),
                SizedBox(height: 12),
                SkeletonLoader(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
