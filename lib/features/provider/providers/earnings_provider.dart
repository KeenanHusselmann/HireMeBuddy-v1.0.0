import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/earnings_service.dart';

final earningsServiceProvider = Provider<EarningsService>((ref) {
  return EarningsService();
});

final earningsDataProvider = StreamProvider.family<EarningsData, String>((ref, providerId) {
  final earningsService = ref.watch(earningsServiceProvider);
  return earningsService.getEarningsStream(providerId);
});

final growthPercentagesProvider = FutureProvider.family<Map<String, double>, String>((ref, providerId) {
  final earningsService = ref.watch(earningsServiceProvider);
  return earningsService.getGrowthPercentages(providerId);
});
