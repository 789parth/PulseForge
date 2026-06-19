import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../providers/app_providers.dart';
import '../../features/activity/domain/entities/step_entry.dart';
import '../../features/activity/presentation/providers/activity_providers.dart';
import '../../features/workout/domain/entities/workout.dart';
import '../../features/workout/presentation/providers/workout_providers.dart';
import '../../core/utils/calorie_calculator.dart';
import 'stat_card.dart';

Future<void> showManualEntrySheet(
  BuildContext context,
  WidgetRef ref, {
  required ManualEntryType type,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => ManualEntrySheet(type: type),
  );
}

enum ManualEntryType { steps, calories, workout }

class ManualEntrySheet extends ConsumerStatefulWidget {
  const ManualEntrySheet({super.key, required this.type});

  final ManualEntryType type;

  @override
  ConsumerState<ManualEntrySheet> createState() => _ManualEntrySheetState();
}

class _ManualEntrySheetState extends ConsumerState<ManualEntrySheet> {
  final _controller = TextEditingController();
  WorkoutType _workoutType = WorkoutType.running;
  String? _error;
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading) return;
    final value = int.tryParse(_controller.text);
    if (value == null || value <= 0) {
      setState(() => _error = 'Enter a valid positive number');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final haptics = ref.read(hapticsEnabledProvider).value ?? true;
      if (haptics) HapticFeedback.mediumImpact();

      switch (widget.type) {
        case ManualEntryType.steps:
          await ref.read(stepRepositoryProvider).addSteps(value);
        case ManualEntryType.calories:
          final today = await ref.read(stepRepositoryProvider).getToday();
          final now = DateTime.now();
          await ref.read(stepRepositoryProvider).upsert(
                StepEntryModel(
                  id: today?.id,
                  date: DateTime(now.year, now.month, now.day),
                  steps: today?.steps ?? 0,
                  calories: (today?.calories ?? 0) + value,
                  activeMinutes: today?.activeMinutes ?? 0,
                  distanceKm: today?.distanceKm ?? 0,
                ),
              );
        case ManualEntryType.workout:
          await ref.read(workoutRepositoryProvider).insert(
                WorkoutModel(
                  type: _workoutType,
                  durationMinutes: value,
                  calories: CalorieCalculator.estimateWorkoutCalories(
                    type: _workoutType.name,
                    durationMinutes: value,
                  ),
                  date: DateTime.now(),
                ),
              );
      }

      ref.invalidate(todayStepsProvider);
      ref.invalidate(weeklyStepsProvider);
      invalidateWorkoutCaches(ref);
      ref.invalidate(goalsWithProgressProvider);

      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (widget.type) {
      ManualEntryType.steps => 'Add Steps',
      ManualEntryType.calories => 'Add Calories',
      ManualEntryType.workout => 'Quick Workout',
    };

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.surface
              : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            if (widget.type == ManualEntryType.workout) ...[
              Wrap(
                spacing: 8,
                children: WorkoutType.values.map((t) {
                  final selected = _workoutType == t;
                  return ChoiceChip(
                    label: Text('${t.emoji} ${t.label}'),
                    selected: selected,
                    onSelected: (_) => setState(() => _workoutType = t),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: widget.type == ManualEntryType.workout
                    ? 'Duration (minutes)'
                    : 'Enter value',
                errorText: _error,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            PfButton(label: 'Save', isLoading: _isLoading, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
