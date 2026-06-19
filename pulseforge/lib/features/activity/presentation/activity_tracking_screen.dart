import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/animated_progress_ring.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/gradient_background.dart';
import '../../../core/widgets/manual_entry_sheet.dart';
import '../../../core/widgets/stat_card.dart';
import '../../goals/domain/entities/goal.dart';
import 'providers/activity_providers.dart';

class ActivityTrackingScreen extends ConsumerStatefulWidget {
  const ActivityTrackingScreen({super.key});

  @override
  ConsumerState<ActivityTrackingScreen> createState() =>
      _ActivityTrackingScreenState();
}

class _ActivityTrackingScreenState extends ConsumerState<ActivityTrackingScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(activityTrackingProvider.notifier).loadToday(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(activityTrackingProvider);
    final stepTarget = ref.watch(goalsWithProgressProvider).valueOrNull
            ?.where((g) => g.goal.type == GoalType.steps)
            .map((g) => g.goal.target)
            .firstOrNull ??
        GoalType.steps.defaultTarget;

    return GradientBackground(
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Activity',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    Text(
                      state.isTracking ? 'Tracking live...' : 'Ready to move',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Center(
                child: RepaintBoundary(
                  child: GlassCard(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: AnimatedProgressRing(
                      progress: stepTarget > 0 ? state.currentSteps / stepTarget : 0,
                      size: 220,
                      strokeWidth: 14,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${state.currentSteps}',
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const Text('steps'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: 'Distance',
                        value: state.distanceKm.toStringAsFixed(2),
                        unit: 'km',
                        icon: Icons.route,
                        color: AppColors.accentCyan,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: StatCard(
                        label: 'Calories',
                        value: '${state.calories}',
                        unit: 'kcal',
                        icon: Icons.local_fire_department,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: StatCard(
                  label: 'Active Minutes',
                  value: '${state.activeMinutes}',
                  unit: 'min',
                  icon: Icons.timer,
                  color: AppColors.primaryPurple,
                ),
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    PfButton(
                      label: state.isTracking ? 'Stop Tracking' : 'Start Tracking',
                      icon: state.isTracking ? Icons.stop : Icons.play_arrow,
                      onPressed: () async {
                        final notifier = ref.read(activityTrackingProvider.notifier);
                        if (state.isTracking) {
                          notifier.stopTracking();
                          await notifier.saveProgress();
                          ref.invalidate(todayStepsProvider);
                          ref.invalidate(weeklyStepsProvider);
                          ref.invalidate(goalsWithProgressProvider);
                        } else {
                          notifier.startTracking();
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    PfButton(
                      label: 'Add Steps Manually',
                      outlined: true,
                      onPressed: () => showManualEntrySheet(
                        context,
                        ref,
                        type: ManualEntryType.steps,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
