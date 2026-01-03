import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/provider_provider.dart';
import '../../../core/utils/logger.dart';
import '../../../shared/services/provider_service.dart';
import '../../../shared/services/review_service.dart';
import '../../bookings/screens/booking_screen.dart';
import 'provider_detail_screen.dart';

// Provider for fetching all providers (fallback for initial load)
final allProvidersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final providerService = ProviderService();
  logger.debug('ServiceListScreen: Fetching all providers...');
  final providers = await providerService.getAllProviders();
  logger.debug('ServiceListScreen: Fetched ${providers.length} providers');
  if (providers.isNotEmpty) {
    logger.debug('ServiceListScreen: First provider: ${providers[0]}');
  }
  return providers;
});

class ServiceListScreen extends ConsumerStatefulWidget {
  final String? initialCategory;
  
  const ServiceListScreen({super.key, this.initialCategory});

  @override
  ConsumerState<ServiceListScreen> createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends ConsumerState<ServiceListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'All';
  String? _searchFilter; // Store the search query for filtering
  String? _matchedCategory; // Store which category tab the search matched to

  // Common service categories in Namibia
  final List<String> _categories = [
    'All',
    'Cleaning',
    'Plumbing',
    'Electrical',
    'Carpentry',
    'Painting',
    'Gardening',
    'Mechanic',
    'Beauty & Wellness',
    'Tutoring',
    'IT & Tech',
    'Security',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    
    // Set initial category and search filter if provided
    if (widget.initialCategory != null) {
      _searchFilter = widget.initialCategory;
      
      // Try to match the search query to an existing category tab
      final categoryIndex = _categories.indexWhere(
        (cat) => cat.toLowerCase() == widget.initialCategory!.toLowerCase() ||
                 cat.toLowerCase().contains(widget.initialCategory!.toLowerCase()) ||
                 widget.initialCategory!.toLowerCase().contains(cat.toLowerCase())
      );
      
      if (categoryIndex != -1) {
        _matchedCategory = _categories[categoryIndex];
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _selectedCategory = _categories[categoryIndex];
          _tabController.animateTo(categoryIndex);
          setState(() {});
        });
      } else {
        // If exact match not found, try to find a partial match
        // e.g., "Web Development" -> "IT & Tech"
        final partialMatch = _categories.indexWhere(
          (cat) {
            final searchLower = widget.initialCategory!.toLowerCase();
            final catLower = cat.toLowerCase();
            // Check if search contains category or category contains key words from search
            return searchLower.contains(catLower) ||
                   catLower.contains(searchLower.split(' ').first) ||
                   (searchLower.contains('web') && catLower.contains('tech')) ||
                   (searchLower.contains('development') && catLower.contains('tech'));
          }
        );
        
        if (partialMatch != -1) {
          _matchedCategory = _categories[partialMatch];
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _selectedCategory = _categories[partialMatch];
            _tabController.animateTo(partialMatch);
            setState(() {});
          });
        } else {
          // If no match, stay on "All" tab and clear search filter
          _selectedCategory = 'All';
          _searchFilter = null;
        }
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filterProvidersByCategory(
    List<Map<String, dynamic>> providers,
    String category,
  ) {
    // Always show all providers on "All" tab (unless it's the matched category)
    if (category == 'All') {
      // Don't apply search filter on All tab - always show all providers
      return providers;
    }

    // For specific categories, if this is the matched category with search filter,
    // use category-based filtering (same as normal category filtering) since
    // we've already matched the search to this category
    if (_searchFilter != null && _searchFilter!.isNotEmpty && _matchedCategory == category) {
      // Use the same category filtering logic that works when browsing normally
      // This ensures we show all providers in this category
      final categoryLower = category.toLowerCase();
      return providers.where((provider) {
        final skills = (provider['skills'] as List<dynamic>?)?.cast<String>() ?? [];
        final bio = (provider['bio'] as String? ?? '').toLowerCase();
        
        // Check provider's selected service categories first (from provider_services)
        final serviceCategoryNames = (provider['service_category_names'] as List<dynamic>?)?.cast<String>() ?? [];
        final hasMatchingCategory = serviceCategoryNames.any((categoryName) {
          final catNameLower = categoryName.toLowerCase();
          return catNameLower.contains(categoryLower) ||
                 categoryLower.contains(catNameLower) ||
                 _matchesCategorySkill(catNameLower, categoryLower);
        });
        
        if (hasMatchingCategory) return true;
        
        // Also check if category matches any skill or bio
        return skills.any((skill) {
          final skillLower = skill.toLowerCase();
          return skillLower.contains(categoryLower) ||
                 categoryLower.contains(skillLower) ||
                 _matchesCategorySkill(skillLower, categoryLower);
        }) || bio.contains(categoryLower);
      }).toList();
    }
    
    // Normal category-based filtering (when no search filter or for non-matched categories)
    return providers.where((provider) {
      final skills = (provider['skills'] as List<dynamic>?)?.cast<String>() ?? [];
      final bio = (provider['bio'] as String? ?? '').toLowerCase();
      final categoryLower = category.toLowerCase();
      
      // Check provider's selected service categories first (from provider_services)
      final serviceCategoryNames = (provider['service_category_names'] as List<dynamic>?)?.cast<String>() ?? [];
      final hasMatchingCategory = serviceCategoryNames.any((categoryName) {
        final catNameLower = categoryName.toLowerCase();
        return catNameLower.contains(categoryLower) ||
               categoryLower.contains(catNameLower) ||
               _matchesCategorySkill(catNameLower, categoryLower);
      });
      
      if (hasMatchingCategory) return true;
      
      // Also check if category matches any skill or bio
      return skills.any((skill) {
        final skillLower = skill.toLowerCase();
        return skillLower.contains(categoryLower) ||
               categoryLower.contains(skillLower) ||
               _matchesCategorySkill(skillLower, categoryLower);
      }) || bio.contains(categoryLower);
    }).toList();
  }
  
  // Helper to match category with skills
  bool _matchesCategorySkill(String skill, String category) {
    final skillLower = skill.toLowerCase();
    final categoryLower = category.toLowerCase();
    
    // IT & Tech category matching
    if (categoryLower.contains('tech')) {
      return skillLower.contains('web') || 
             skillLower.contains('development') || 
             skillLower.contains('programming') || 
             skillLower.contains('coding') ||
             skillLower.contains('software') || 
             skillLower.contains('app') ||
             skillLower.contains('it support') ||
             skillLower.contains('it support') ||
             skillLower.contains('computer') ||
             skillLower.contains('technical') ||
             skillLower.contains('tech') ||
             skillLower.contains('it ') ||
             skillLower == 'it' ||
             skillLower.contains('information technology') ||
             skillLower.contains('network') ||
             skillLower.contains('system');
    }
    
    // Tutoring category matching
    if (categoryLower.contains('tutor')) {
      return skillLower.contains('tutor') || 
             skillLower.contains('teaching') || 
             skillLower.contains('education');
    }
    
    // Beauty & Wellness category matching
    if (categoryLower.contains('wellness') || categoryLower.contains('beauty')) {
      return skillLower.contains('beauty') || 
             skillLower.contains('wellness') ||
             skillLower.contains('spa') || 
             skillLower.contains('salon') ||
             skillLower.contains('massage') ||
             skillLower.contains('skincare');
    }
    
    // Cleaning category matching
    if (categoryLower.contains('clean')) {
      return skillLower.contains('clean') ||
             skillLower.contains('housekeeping') ||
             skillLower.contains('janitor');
    }
    
    // Plumbing category matching
    if (categoryLower.contains('plumb')) {
      return skillLower.contains('plumb') ||
             skillLower.contains('pipe') ||
             skillLower.contains('water');
    }
    
    // Electrical category matching
    if (categoryLower.contains('electric')) {
      return skillLower.contains('electric') ||
             skillLower.contains('wiring') ||
             skillLower.contains('circuit');
    }
    
    // Carpentry category matching
    if (categoryLower.contains('carpent')) {
      return skillLower.contains('carpent') ||
             skillLower.contains('wood') ||
             skillLower.contains('furniture');
    }
    
    // Painting category matching
    if (categoryLower.contains('paint')) {
      return skillLower.contains('paint') ||
             skillLower.contains('decorat');
    }
    
    // Gardening category matching
    if (categoryLower.contains('garden')) {
      return skillLower.contains('garden') ||
             skillLower.contains('landscap') ||
             skillLower.contains('lawn');
    }
    
    // Mechanic category matching
    if (categoryLower.contains('mechanic')) {
      return skillLower.contains('mechanic') ||
             skillLower.contains('auto') ||
             skillLower.contains('vehicle') ||
             skillLower.contains('car repair');
    }
    
    // Security category matching
    if (categoryLower.contains('security')) {
      return skillLower.contains('security') ||
             skillLower.contains('guard') ||
             skillLower.contains('protect');
    }
    
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // Use real-time stream for automatic updates
    final providersAsync = ref.watch(allProvidersStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Providers'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          onTap: (index) {
            setState(() {
              _selectedCategory = _categories[index];
              // Clear search filter and matched category when user manually changes tabs
              _searchFilter = null;
              _matchedCategory = null;
            });
          },
          tabs: _categories.map((category) {
            return Tab(
              child: Row(
                children: [
                  Icon(_getCategoryIcon(category), size: 18),
                  const SizedBox(width: 6),
                  Text(category),
                ],
              ),
            );
          }).toList(),
        ),
      ),
      body: SafeArea(
        child: providersAsync.when(
          data: (providers) {
          logger.debug('ServiceListScreen: Rendering with ${providers.length} providers');
          
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

          return TabBarView(
            controller: _tabController,
            children: _categories.map((category) {
              final categoryProviders = _filterProvidersByCategory(providers, category);
              
              if (categoryProviders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_getCategoryIcon(category), size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No ${category == 'All' ? 'service providers' : '${category.toLowerCase()} providers'} available',
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Check back later!',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: categoryProviders.length,
                itemBuilder: (context, index) {
                  final provider = categoryProviders[index];
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
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) {
          logger.error('ServiceListScreen: Error loading providers', error, stack);
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
      logger.error('Error getting provider stats', e);
      return {
        'avgRating': 0.0,
        'reviewCount': 0,
        'completedJobs': 0,
      };
    }
  }
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'all':
        return Icons.grid_view;
      case 'cleaning':
        return Icons.cleaning_services;
      case 'plumbing':
        return Icons.plumbing;
      case 'electrical':
        return Icons.electrical_services;
      case 'carpentry':
        return Icons.carpenter;
      case 'painting':
        return Icons.format_paint;
      case 'gardening':
        return Icons.yard;
      case 'mechanic':
        return Icons.build;
      case 'beauty & wellness':
        return Icons.spa;
      case 'tutoring':
        return Icons.school;
      case 'it & tech':
        return Icons.computer;
      case 'security':
        return Icons.security;
      default:
        return Icons.work;
    }
  }}
