import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/gradient_background.dart';
import '../../../core/widgets/stat_card.dart';
import '../domain/entities/workout.dart';
import 'providers/workout_providers.dart';
import '../../activity/presentation/providers/activity_providers.dart';

class AddWorkoutScreen extends ConsumerStatefulWidget {
  const AddWorkoutScreen({super.key});

  @override
  ConsumerState<AddWorkoutScreen> createState() => _AddWorkoutScreenState();
}

class _AddWorkoutScreenState extends ConsumerState<AddWorkoutScreen> {
  late final TextEditingController _durationController;
  late final TextEditingController _caloriesController;
  late final TextEditingController _notesController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final form = ref.read(workoutFormProvider);
    _durationController = TextEditingController(text: '${form.durationMinutes}');
    _caloriesController = TextEditingController(text: '${form.calories}');
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _durationController.dispose();
    _caloriesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(workoutFormProvider, (previous, next) {
      if (previous?.calories != next.calories && next.autoCalories) {
        _caloriesController.text = '${next.calories}';
      }
      if (previous?.durationMinutes != next.durationMinutes &&
          _durationController.text != '${next.durationMinutes}') {
        _durationController.text = '${next.durationMinutes}';
      }
    });

    final form = ref.watch(workoutFormProvider);
    final notifier = ref.read(workoutFormProvider.notifier);

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Text(
                    'Add Workout',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Text('Workout Type', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: WorkoutType.values.map((type) {
                      final selected = form.type == type;
                      return GestureDetector(
                        onTap: () => notifier.setType(type),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            gradient: selected ? AppColors.primaryGradient : null,
                            color: selected ? null : AppColors.surface,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            border: Border.all(
                              color: selected
                                  ? Colors.transparent
                                  : AppColors.glassBorder,
                            ),
                          ),
                          child: Text(
                            '${type.emoji} ${type.label}',
                            style: TextStyle(
                              color: selected ? Colors.black : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    controller: _durationController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Duration (minutes)',
                    ),
                    onChanged: notifier.setDuration,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _caloriesController,
                    keyboardType: TextInputType.number,
                    readOnly: form.autoCalories,
                    decoration: InputDecoration(
                      labelText: 'Calories',
                      helperText: form.autoCalories ? 'Auto-calculated from type & duration' : null,
                      errorText: form.error,
                      suffixIcon: form.autoCalories
                          ? IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              onPressed: () {
                                notifier.setCalories(form.calories.toString());
                              },
                              tooltip: 'Edit calories manually',
                            )
                          : IconButton(
                              icon: const Icon(Icons.refresh, size: 20),
                              onPressed: notifier.resetAutoCalories,
                              tooltip: 'Reset to auto',
                            ),
                    ),
                    onChanged: notifier.setCalories,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                    ),
                    maxLines: 3,
                    onChanged: notifier.setNotes,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: SizedBox(
                width: double.infinity,
                child: PfButton(
                  label: 'Save Workout',
                  icon: Icons.check,
                  isLoading: _isSaving,
                  onPressed: _isSaving
                      ? null
                      : () async {
                          setState(() => _isSaving = true);
                          try {
                            final saved = await notifier.save();
                            if (saved && mounted) {
                              invalidateWorkoutCaches(ref);
                              ref.invalidate(goalsWithProgressProvider);
                              if (context.mounted) context.pop();
                            }
                          } finally {
                            if (mounted) setState(() => _isSaving = false);
                          }
                        },
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }
}
