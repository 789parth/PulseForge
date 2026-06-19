import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../domain/entities/analytics.dart';

final weeklyAnalyticsProvider = FutureProvider<WeeklyAnalytics>((ref) async {
  await ref.watch(seedDataProvider.future);
  return ref.watch(analyticsRepositoryProvider).getWeeklyAnalytics();
});

final monthlyStatsProvider = FutureProvider<List<DailyStats>>((ref) async {
  await ref.watch(seedDataProvider.future);
  return ref.watch(analyticsRepositoryProvider).getMonthlyStats();
});
