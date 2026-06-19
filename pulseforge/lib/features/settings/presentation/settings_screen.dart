import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/gradient_background.dart';
import '../../../core/widgets/manual_entry_sheet.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider).value ?? true;
    final haptics = ref.watch(hapticsEnabledProvider).value ?? true;

    return GradientBackground(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              'Settings',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            GlassCard(
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.dark_mode_outlined,
                    title: 'Dark Mode',
                    subtitle: isDark ? 'Enabled' : 'Disabled',
                    trailing: Switch.adaptive(
                      value: isDark,
                      activeTrackColor: AppColors.primaryBlue,
                      onChanged: (_) =>
                          ref.read(themeModeProvider.notifier).toggle(),
                    ),
                  ),
                  const Divider(),
                  _SettingsTile(
                    icon: Icons.vibration,
                    title: 'Haptic Feedback',
                    subtitle: haptics ? 'Enabled' : 'Disabled',
                    trailing: Switch.adaptive(
                      value: haptics,
                      activeTrackColor: AppColors.primaryBlue,
                      onChanged: (_) =>
                          ref.read(hapticsEnabledProvider.notifier).toggle(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            GlassCard(
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.directions_walk,
                    title: 'Manual Step Entry',
                    subtitle: 'Add steps manually',
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => showManualEntrySheet(
                      context,
                      ref,
                      type: ManualEntryType.steps,
                    ),
                  ),
                  const Divider(),
                  _SettingsTile(
                    icon: Icons.local_fire_department,
                    title: 'Manual Calorie Entry',
                    subtitle: 'Log calories',
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => showManualEntrySheet(
                      context,
                      ref,
                      type: ManualEntryType.calories,
                    ),
                  ),
                  const Divider(),
                  _SettingsTile(
                    icon: Icons.fitness_center,
                    title: 'Workout History',
                    subtitle: 'View all workouts',
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/workouts'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            GlassCard(
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.info_outline,
                    title: 'PulseForge',
                    subtitle: 'Version 1.0.0',
                  ),
                  const Divider(),
                  _SettingsTile(
                    icon: Icons.speed,
                    title: 'Impeller Renderer',
                    subtitle: 'GPU-accelerated rendering enabled',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primaryBlue, size: 20),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: trailing,
    );
  }
}
