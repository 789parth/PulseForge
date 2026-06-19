import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/animated_progress_ring.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/gradient_background.dart';
import '../../../core/widgets/skeleton_loader.dart';
import 'providers/goals_providers.dart';
import '../../activity/presentation/providers/activity_providers.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsWithProgressProvider);

    return GradientBackground(
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'Goals',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: goalsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: SkeletonLoader(height: 200),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: ErrorState(
                    message: 'Failed to load goals',
                    onRetry: () => ref.invalidate(goalsWithProgressProvider),
                  ),
                ),
                data: (goals) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Column(
                    children: goals.map((g) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _GoalCard(
                          progress: g,
                          onEdit: (target) async {
                            await ref
                                .read(goalsNotifierProvider.notifier)
                                .updateGoal(g.goal, target);
                            ref.invalidate(goalsWithProgressProvider);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalCard extends StatefulWidget {
  const _GoalCard({required this.progress, required this.onEdit});

  final GoalProgress progress;
  final Future<void> Function(int target) onEdit;

  @override
  State<_GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends State<_GoalCard> {
  bool _editing = false;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: '${widget.progress.goal.target}',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.progress;

    return RepaintBoundary(
      child: GlassCard(
        child: Column(
          children: [
            Row(
              children: [
                AnimatedProgressRing(
                  progress: g.progress,
                  size: 72,
                  strokeWidth: 6,
                  child: Text(
                    '${(g.progress * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        g.goal.type.label,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        '${g.current} / ${g.goal.target}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _editing = !_editing),
                  icon: Icon(_editing ? Icons.close : Icons.edit_outlined),
                ),
              ],
            ),
            if (_editing) ...[
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Target ${g.goal.type.key}',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () async {
                    final target = int.tryParse(_controller.text);
                    if (target != null && target > 0) {
                      HapticFeedback.lightImpact();
                      await widget.onEdit(target);
                      if (mounted) setState(() => _editing = false);
                    }
                  },
                  child: const Text('Save Target'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
