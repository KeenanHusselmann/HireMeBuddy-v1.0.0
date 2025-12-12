import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/portfolio_service.dart';

final portfolioServiceProvider = Provider<PortfolioService>((ref) {
  return PortfolioService();
});

final portfolioImagesProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, providerId) async {
  final service = ref.watch(portfolioServiceProvider);
  return service.getPortfolioImages(providerId);
});
