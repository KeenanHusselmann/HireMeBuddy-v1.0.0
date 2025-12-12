import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/provider_provider.dart';
import '../../../shared/services/provider_service.dart';
import '../../../shared/services/review_service.dart';
import '../../bookings/screens/booking_screen.dart';
import 'provider_detail_screen.dart';

// Provider for fetching all providers (fallback for initial load)
final allProvidersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final providerService = ProviderService();
  print('ServiceListScreen: Fetching all providers...');
  final providers = await providerService.getAllProviders();
  print('ServiceListScreen: Fetched ${providers.length} providers');
  if (providers.isNotEmpty) {
    print('ServiceListScreen: First provider: ${providers[0]}');
  }
  return providers;
});

class ServiceListScreen extends ConsumerWidget {
  const ServiceListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use real-time stream for automatic updates
    final providersAsync = ref.watch(allProvidersStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Providers'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Implement filter by category
            },
          ),
        ],
      ),
      body: SafeArea(
        child: providersAsync.when(
          data: (providers) {
          print('ServiceListScreen: Rendering with ${providers.length} providers');
          if (providers.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.work_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No service providers yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Be the first to join as a provider!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Real-time updates enabled
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: providers.length,
            itemBuilder: (context, index) {
                  final provider = providers[index];
                  final profile = provider['profiles'] as Map<String, dynamic>;
                  final providerId = profile['id'] as String;
                  final hourlyRate = provider['hourly_rate'] as num?;
                  final skills = (provider['skills'] as List<dynamic>?)?.cast<String>() ?? [];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 2,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProviderDetailScreen(
                                provider: provider,
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Provider Header
                              Row(
                                children: [
                                  Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: Colors.teal.shade100,
                                        backgroundImage: profile['avatar_url'] != null
                                            ? NetworkImage(profile['avatar_url'])
                                            : null,
                                        child: profile['avatar_url'] == null
                                            ? Text(
                                                (profile['full_name'] as String?)
                                                    ?.substring(0, 1)
                                                    .toUpperCase() ??
                                                'P',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.teal.shade700,
                                            ),
                                          )
                                        : null,
                                      ),
                                      // Availability status indicator
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          width: 14,
                                          height: 14,
                                          decoration: BoxDecoration(
                                            color: provider['is_available'] == true 
                                                ? Colors.green 
                                                : Colors.grey,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            profile['full_name'] ?? 'Unknown',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        // Availability status chip
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: provider['is_available'] == true 
                                                ? Colors.green.shade50 
                                                : Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: provider['is_available'] == true 
                                                  ? Colors.green.shade300 
                                                  : Colors.grey.shade300,
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                provider['is_available'] == true 
                                                    ? Icons.check_circle 
                                                    : Icons.cancel,
                                                color: provider['is_available'] == true 
                                                    ? Colors.green.shade700 
                                                    : Colors.grey.shade700,
                                                size: 12,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                provider['is_available'] == true 
                                                    ? 'Available' 
                                                    : 'Busy',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: provider['is_available'] == true 
                                                      ? Colors.green.shade700 
                                                      : Colors.grey.shade700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        if (provider['is_verified'] == true)
                                          Icon(
                                            Icons.verified,
                                            color: Colors.blue.shade600,
                                            size: 18,
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    FutureBuilder<Map<String, dynamic>>(
                                      future: _getProviderStats(providerId),
                                      builder: (context, snapshot) {
                                        final stats = snapshot.data ?? {};
                                        final avgRating = stats['avgRating'] as num? ?? 0.0;
                                        final reviewCount = stats['reviewCount'] as int? ?? 0;
                                        final completedJobs = stats['completedJobs'] as int? ?? 0;
                                        
                                        return Row(
                                          children: [
                                            Icon(Icons.star,
                                                color: Colors.amber.shade700, size: 16),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${avgRating.toStringAsFixed(1)} ($reviewCount reviews)',
                                              style: const TextStyle(fontSize: 13),
                                            ),
                                            const SizedBox(width: 12),
                                            Icon(Icons.check_circle,
                                                color: Colors.green.shade600, size: 16),
                                            const SizedBox(width: 4),
                                            Text(
                                              '$completedJobs jobs',
                                              style: const TextStyle(fontSize: 13),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Bio
                          if (provider['bio'] != null) ...[
                            Text(
                              provider['bio'],
                              style: const TextStyle(fontSize: 14),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                          ],

                          // Skills
                          if (skills.isNotEmpty) ...[
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: skills.take(3).map((skill) {
                                return Chip(
                                  label: Text(
                                    skill,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  backgroundColor: Colors.teal.shade600,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 0),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 8),
                          ],

                          // Pricing and Action
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (hourlyRate != null)
                                Text(
                                  'N\$${hourlyRate.toStringAsFixed(2)}/hr',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal.shade700,
                                  ),
                                ),
                              ElevatedButton.icon(
                                onPressed: provider['is_available'] == true 
                                  ? () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => BookingScreen(
                                            provider: provider,
                                          ),
                                        ),
                                      );
                                    }
                                  : null,
                                icon: Icon(
                                  provider['is_available'] == true 
                                    ? Icons.calendar_today 
                                    : Icons.block,
                                  size: 14,
                                ),
                                label: Text(
                                  provider['is_available'] == true 
                                    ? 'Book Now' 
                                    : 'Unavailable',
                                  style: const TextStyle(fontSize: 13),
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  backgroundColor: provider['is_available'] == true 
                                    ? null 
                                    : Colors.grey.shade300,
                                  foregroundColor: provider['is_available'] == true 
                                    ? null 
                                    : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) {
          print('ServiceListScreen: Error loading providers: $error');
          print('ServiceListScreen: Stack trace: $stack');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(
                  'Error loading providers',
                  style: TextStyle(fontSize: 16, color: Colors.red.shade700),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(allProvidersStreamProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        },
      ),
      ),
    );
  }

  Future<Map<String, dynamic>> _getProviderStats(String providerId) async {
    try {
      // Get review stats
      final reviews = await ReviewService().getProviderReviews(providerId);
      final avgRating = reviews.isEmpty 
          ? 0.0 
          : reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
      
      // Get completed jobs count from Supabase
      final supabase = Supabase.instance.client;
      final completedJobsResponse = await supabase
          .from('bookings')
          .select('id')
          .eq('provider_id', providerId)
          .eq('status', 'completed')
          .count();
      
      return {
        'avgRating': avgRating,
        'reviewCount': reviews.length,
        'completedJobs': completedJobsResponse.count,
      };
    } catch (e) {
      print('Error getting provider stats: $e');
      return {
        'avgRating': 0.0,
        'reviewCount': 0,
        'completedJobs': 0,
      };
    }
  }
}
