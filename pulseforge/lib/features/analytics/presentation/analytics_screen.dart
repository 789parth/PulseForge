import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/charts.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/gradient_background.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/stat_card.dart';
import 'providers/analytics_providers.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyAsync = ref.watch(weeklyAnalyticsProvider);
    final monthlyAsync = ref.watch(monthlyStatsProvider);

    return GradientBackground(
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'Analytics',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: weeklyAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: SkeletonLoader(height: 100),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: ErrorState(
                    message: 'Failed to load analytics',
                    onRetry: () => ref.invalidate(weeklyAnalyticsProvider),
                  ),
                ),
                data: (analytics) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          label: 'Weekly Steps',
                          value: _formatNumber(analytics.totalSteps),
                          icon: Icons.directions_walk,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: StatCard(
                          label: 'Weekly Cal',
                          value: '${analytics.totalCalories}',
                          unit: 'kcal',
                          icon: Icons.local_fire_department,
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
                  loading: () => const SkeletonLoader(height: 200),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (analytics) {
                    final labels = analytics.dailySteps
                        .map((d) => DateFormat('E').format(d.date))
                        .toList();
                    final stepValues =
                        analytics.dailySteps.map((d) => d.steps.toDouble()).toList();
                    final calValues =
                        analytics.dailyCalories.map((c) => c.toDouble()).toList();

                    return Column(
                      children: [
                        GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Steps — Weekly',
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  TrendBadge(trend: analytics.stepTrend),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              WeeklyLineChart(values: stepValues, labels: labels),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'Avg ${analytics.avgSteps.round()} steps/day',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Calories — Weekly',
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  TrendBadge(trend: analytics.calorieTrend),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              CalorieBarChart(values: calValues, labels: labels),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'Avg ${analytics.avgCalories.round()} kcal/day',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
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
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.xxl,
                ),
                child: monthlyAsync.when(
                  loading: () => const SkeletonLoader(height: 200),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (stats) {
                    if (stats.isEmpty) return const SizedBox.shrink();

                    final values = stats.map((s) => s.steps.toDouble()).toList();

                    return GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Monthly Overview',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          WeeklyLineChart(
                            values: values,
                            labels: stats.map((s) => '${s.date.day}').toList(),
                            height: 160,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}
