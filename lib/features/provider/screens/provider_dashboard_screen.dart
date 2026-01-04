import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/provider_provider.dart';
import '../../../core/utils/logger.dart';
import '../../../shared/models/provider_profile.dart';
import '../../../shared/services/notification_service.dart';
import '../../../shared/services/workmanager_notification_service.dart';
import '../../../core/services/deep_link_handler.dart';
import 'provider_bookings_screen.dart';
import 'provider_earnings_screen.dart';
import 'provider_portfolio_screen.dart';
import 'provider_reviews_screen.dart';
import '../../chat/screens/conversations_screen.dart';
import 'subscription_required_screen.dart';
import 'edit_service_screen.dart';

// Real-time provider for pending bookings count
final pendingBookingsCountProvider = StreamProvider.autoDispose<int>((ref) async* {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;
  
  if (userId == null) {
    yield 0;
    return;
  }
  
  // Get provider profile ID first
  final profile = await supabase
      .from('profiles')
      .select('id')
      .eq('user_id', userId)
      .maybeSingle();
  
  if (profile == null) {
    yield 0;
    return;
  }
  
  final providerId = profile['id'] as String;
  logger.info('[BOOKINGS] Setting up real-time stream for provider: $providerId');
  
  await for (final bookings in supabase
      .from('bookings')
      .stream(primaryKey: ['id'])) {
    // Filter for pending bookings for this provider
    final pendingBookings = bookings.where((booking) => 
      booking['provider_id'] == providerId && 
      booking['status'] == 'pending'
    ).toList();
    
    final count = pendingBookings.length;
    logger.debug('[BOOKINGS] Real-time update: $count pending bookings');
    yield count;
  }
});

// Real-time provider for unread messages count
final unreadMessagesCountProvider = StreamProvider.autoDispose<int>((ref) async* {
  logger.info('[MESSAGES] Setting up provider unread messages stream...');
  
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;
  
  if (userId == null) {
    logger.warning('[MESSAGES] No authenticated user');
    yield 0;
    return;
  }
  
  try {
    // Get profile ID first
    final profile = await supabase
        .from('profiles')
        .select('id')
        .eq('user_id', userId)
        .single();
    
    final profileId = profile['id'] as String;
    logger.debug('[MESSAGES] Provider profile_id: ${AppLogger.sanitizeUserId(profileId)}');
    
    // Stream unread messages
    await for (final messages in supabase
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .asyncMap((data) async {
          // Filter for messages where this user is receiver and not read
          final filtered = data.where((msg) {
            final receiverId = msg['receiver_id'] as String?;
            final isRead = msg['read'] as bool? ?? false;
            final match = receiverId == profileId && !isRead;
            
            if (match) {
              final content = msg['content']?.toString() ?? "";
              final preview = content.length > 20 ? content.substring(0, 20) : content;
              print('📨 [MESSAGES] Unread: $preview...');
            }
            
            return match;
          }).toList();
          
          print('🟢 [MESSAGES] Provider unread count: ${filtered.length}');
          return filtered;
        })) {
      yield messages.length;
    }
  } catch (e) {
    logger.error('[MESSAGES] Error in provider unread messages stream', e);
    yield 0;
  }
});

class ProviderDashboardScreen extends ConsumerStatefulWidget {
  const ProviderDashboardScreen({super.key});

  @override
  ConsumerState<ProviderDashboardScreen> createState() => _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends ConsumerState<ProviderDashboardScreen> {
  final _notificationService = NotificationService();
  bool _notificationsInitialized = false;
  String? _providerId;

  String _capitalizeWords(String text) {
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _registerDeepLinkHandler();
  }

  Future<void> _initializeNotifications() async {
    try {
      await _notificationService.initialize();
      setState(() {
        _notificationsInitialized = true;
      });
      logger.info('Notifications initialized successfully');
    } catch (e) {
      logger.error('Error initializing notifications', e);
    }
  }
  
  void _registerDeepLinkHandler() {
    print('🔗 Dashboard: Registering deep link handler...');
    print('🔗 Dashboard: Has pending navigation? ${DeepLinkHandler().hasPendingNavigation}');
    
    // Register callback to handle deep link navigation from push notifications
    DeepLinkHandler().registerNavigationCallback((route, {params}) {
      print('🔗 Dashboard: Deep link navigation requested: $route, params: $params');
      
      // Use addPostFrameCallback to ensure navigation happens after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          logger.warning('Dashboard: Not mounted, skipping navigation');
          return;
        }
        
        logger.debug('Dashboard: Executing navigation to $route');
        
        switch (route) {
          case 'bookings':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProviderBookingsScreen(),
              ),
            );
            logger.info('Dashboard: Navigated to bookings');
            break;
            
          case 'messages':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ConversationsScreen(),
              ),
            );
            logger.info('Dashboard: Navigated to messages');
            break;
            
          default:
            logger.warning('Dashboard: Unknown deep link route: $route');
        }
      });
    });
  }

  Future<void> _loadProviderId(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .single();
      
      setState(() {
        _providerId = response['id'] as String;
      });
      
      // Subscribe now that we have the profile ID
      if (_notificationsInitialized && _providerId != null) {
        _notificationService.subscribeToProviderBookings(_providerId!);
        _notificationService.subscribeToMessages(_providerId!);
        _notificationService.subscribeToNotifications(_providerId!);
        
        // Start WorkManager for periodic background notifications (checks every 15 minutes)
        WorkManagerNotificationService.initialize(_providerId!, 'labourer').then((_) {
          logger.info('WorkManager background task registered for provider ${AppLogger.sanitizeUserId(_providerId!)}');
        }).catchError((e) {
          logger.error('WorkManager initialization error', e);
        });
        
        logger.info('Subscribed to notifications for provider');
      }
    } catch (e) {
      logger.error('Error loading provider ID', e);
    }
  }

  @override
  void dispose() {
    // Clear deep link callbacks to prevent memory leaks
    DeepLinkHandler().clearCallbacks();
    _notificationService.unsubscribeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final userProfile = ref.watch(userProfileProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('User not found')),
          );
        }

        // Load provider ID and subscribe to notifications
        if (_notificationsInitialized && _providerId == null) {
          _loadProviderId(user.id);
        }

        // Now watching StreamProvider for real-time updates
        final providerProfileAsync = ref.watch(providerProfileProvider(user.id));
        final providerServicesAsync = ref.watch(providerServicesProvider(user.id));

        return _buildDashboard(context, ref, user, userProfile, providerProfileAsync, providerServicesAsync);
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    WidgetRef ref,
    dynamic user,
    AsyncValue userProfile,
    AsyncValue providerProfileAsync,
    AsyncValue providerServicesAsync,
  ) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Dashboard'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                ref.read(authStateProvider.notifier).signOut();
                context.go('/provider-login');
              } else if (value == 'profile') {
                context.push('/profile');
              } else if (value == 'portfolio') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProviderPortfolioScreen(),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'portfolio',
                child: Row(
                  children: [
                    Icon(Icons.photo_library, size: 20, color: Colors.grey.shade800),
                    const SizedBox(width: 8),
                    const Text('My Portfolio'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, size: 20, color: Colors.grey.shade800),
                    const SizedBox(width: 8),
                    const Text('My Profile'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20, color: Colors.grey.shade800),
                    const SizedBox(width: 8),
                    const Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
              // Welcome Header with Availability Toggle
              Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.deepOrange.shade600,
                    Colors.deepOrange.shade400,
                  ],
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        backgroundImage: userProfile.when(
                          data: (profile) {
                            final avatarUrl = profile?.profileImageUrl;
                            return avatarUrl != null && avatarUrl.isNotEmpty
                                ? NetworkImage(avatarUrl) as ImageProvider
                                : null;
                          },
                          loading: () => null,
                          error: (_, __) => null,
                        ),
                        child: userProfile.when(
                          data: (profile) {
                            final avatarUrl = profile?.profileImageUrl;
                            // Only show initial if no avatar
                            if (avatarUrl == null || avatarUrl.isEmpty) {
                              return Text(
                                profile?.displayName.substring(0, 1).toUpperCase() ?? 'P',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepOrange.shade600,
                                ),
                              );
                            }
                            return null;
                          },
                          loading: () => Text(
                            'P',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange.shade600,
                            ),
                          ),
                          error: (_, __) => Text(
                            'P',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange.shade600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back,',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              userProfile.when(
                                data: (profile) => profile?.firstName ?? 'Provider',
                                loading: () => 'Loading...',
                                error: (_, __) => 'Provider',
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Availability Toggle - Only show if provider profile exists
                  providerProfileAsync.when(
                    data: (profile) {
                      if (profile == null) return const SizedBox.shrink();
                      final providerProfile = profile as ProviderProfile;
                      
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Icon(
                              providerProfile.isAvailable ? Icons.check_circle : Icons.cancel,
                              color: providerProfile.isAvailable ? Colors.green : Colors.grey,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Availability Status',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    providerProfile.isAvailable ? 'Available for bookings' : 'Currently unavailable',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: providerProfile.isAvailable ? Colors.green.shade700 : Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: providerProfile.isAvailable,
                              onChanged: (value) async {
                                // Update availability in database
                                try {
                                  await Supabase.instance.client
                                    .from('provider_profiles')
                                    .update({'is_available': value})
                                    .eq('id', providerProfile.id);
                                  
                                  // Refresh provider profile
                                  ref.invalidate(providerProfileProvider(user.id));
                                  
                                  // Show confirmation
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          value 
                                            ? '✅ You are now available for bookings' 
                                            : '⏸️ You are now unavailable',
                                        ),
                                        backgroundColor: value ? Colors.green : Colors.orange,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error updating availability: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                              activeThumbColor: Colors.green,
                              activeTrackColor: Colors.green.shade200,
                            ),
                          ],
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            // Provider Profile Card
            Padding(
              padding: const EdgeInsets.all(16),
              child: providerProfileAsync.when(
                data: (profile) {
                  if (profile == null) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Icon(Icons.info_outline, size: 48, color: Colors.orange),
                            const SizedBox(height: 12),
                            const Text(
                              'Complete Your Provider Profile',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'You need to complete your provider registration to start receiving bookings.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => context.push('/provider-registration'),
                              icon: const Icon(Icons.app_registration),
                              label: const Text('Complete Registration'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final providerProfile = profile as ProviderProfile;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Profile Status',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: providerProfile.isVerified
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: providerProfile.isVerified
                                        ? Colors.green
                                        : Colors.orange,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      providerProfile.isVerified
                                          ? Icons.verified
                                          : Icons.pending,
                                      size: 18,
                                      color: providerProfile.isVerified
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      providerProfile.isVerified
                                          ? 'VERIFIED'
                                          : 'PENDING',
                                      style: TextStyle(
                                        color: providerProfile.isVerified
                                            ? Colors.green
                                            : Colors.orange,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (!providerProfile.isVerified) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.orange.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.orange.shade700,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Your account is pending verification. Admin will review and approve your profile soon.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.orange.shade900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          // Show daily + hourly rate summary based on registered services
                          Consumer(
                            builder: (context, ref, _) {
                              final servicesAsync = ref.watch(providerServicesProvider(user.id));

                              return servicesAsync.when(
                                data: (services) {
                                  num? dailyRate;

                                  for (final service in services) {
                                    final rateType =
                                        (service['rate_type'] as String?)?.toLowerCase();
                                    if (rateType == 'daily') {
                                      final base = service['base_price'] as num?;
                                      if (base != null) {
                                        dailyRate = base;
                                        break;
                                      }
                                    }
                                  }

                                  return Column(
                                    children: [
                                      if (dailyRate != null)
                                        _buildInfoRow(
                                          'Daily Rate',
                                          'N\$${dailyRate.toStringAsFixed(2)}',
                                        ),
                                      _buildInfoRow(
                                        'Average Rating',
                                        '${providerProfile.averageRating.toStringAsFixed(1)} ⭐',
                                      ),
                                      _buildInfoRow(
                                        'Total Reviews',
                                        '${providerProfile.totalReviews}',
                                      ),
                                      _buildInfoRow(
                                        'Completed Jobs',
                                        '${providerProfile.completedJobs}',
                                      ),
                                    ],
                                  );
                                },
                                loading: () => Column(
                                  children: [
                                    _buildInfoRow(
                                      'Average Rating',
                                      '${providerProfile.averageRating.toStringAsFixed(1)} ⭐',
                                    ),
                                    _buildInfoRow(
                                      'Total Reviews',
                                      '${providerProfile.totalReviews}',
                                    ),
                                    _buildInfoRow(
                                      'Completed Jobs',
                                      '${providerProfile.completedJobs}',
                                    ),
                                  ],
                                ),
                                error: (_, __) => Column(
                                  children: [
                                    _buildInfoRow(
                                      'Average Rating',
                                      '${providerProfile.averageRating.toStringAsFixed(1)} ⭐',
                                    ),
                                    _buildInfoRow(
                                      'Total Reviews',
                                      '${providerProfile.totalReviews}',
                                    ),
                                    _buildInfoRow(
                                      'Completed Jobs',
                                      '${providerProfile.completedJobs}',
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const Card(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (error, stack) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Error loading profile: $error'),
                  ),
                ),
              ),
            ),

            // Services Section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'My Services',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  providerServicesAsync.when(
                    data: (services) {
                      if (services.isEmpty) {
                        return Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                const Icon(Icons.work_outline, size: 48, color: Colors.grey),
                                const SizedBox(height: 16),
                                const Text(
                                  'No services added yet',
                                  style: TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: () {
                                    context.push('/add-service');
                                  },
                                  child: const Text('Add Service'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: [
                          ...services.map<Widget>((service) {
                            final category = service['service_categories'];
                            return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.teal.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(Icons.work, color: Colors.teal.shade700, size: 24),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _capitalizeWords(category['name'] ?? 'Unknown Service'),
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            if ((service['rate_type'] as String?)?.toLowerCase() == 'daily') ...[
                                              Text(
                                                'Daily Rate: N\$${service['base_price']}',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.teal.shade700,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Hourly (derived): N\$${(((service['base_price'] as num?) ?? 0) / 8).toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey.shade700,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ] else if ((service['rate_type'] as String?)?.toLowerCase() == 'hourly') ...[
                                              Text(
                                                'Hourly Rate: N\$${service['base_price']}',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.teal.shade700,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ] else ...[
                                              Text(
                                                'Base Price: N\$${service['base_price']}',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.teal.shade700,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (service['description'] != null && service['description'].toString().isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      service['description'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  const Divider(height: 1),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        service['is_available'] == true ? Icons.check_circle : Icons.cancel,
                                        size: 16,
                                        color: service['is_available'] == true ? Colors.green : Colors.grey,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        service['is_available'] == true ? 'Available' : 'Unavailable',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: service['is_available'] == true ? Colors.green : Colors.grey,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const Spacer(),
                                      Transform.scale(
                                        scale: 0.85,
                                        child: Switch(
                                          value: service['is_available'] ?? false,
                                          onChanged: (value) async {
                                          try {
                                            await ref
                                                .read(providerServiceProvider)
                                                .updateServiceAvailability(
                                                  serviceId: service['id'],
                                                  isAvailable: value,
                                                );
                                            ref.invalidate(providerServicesProvider(user.id));
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    value ? 'Service enabled' : 'Service disabled',
                                                    style: const TextStyle(fontSize: 13),
                                                  ),
                                                  behavior: SnackBarBehavior.floating,
                                                  margin: const EdgeInsets.all(8),
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8,
                                                  ),
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Update failed: $e',
                                                    style: const TextStyle(fontSize: 13),
                                                  ),
                                                  backgroundColor: Colors.red,
                                                  behavior: SnackBarBehavior.floating,
                                                  margin: const EdgeInsets.all(8),
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8,
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                        },
                                      ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Edit Button
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 22),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => EditServiceScreen(
                                                serviceId: service['id'],
                                                serviceName: category['name'],
                                                currentBasePrice: (service['base_price'] as num).toDouble(),
                                                currentDescription: service['description'] ?? '',
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Delete Service'),
                                              content: Text(
                                                'Remove ${category['name']} from your services?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context, false),
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context, true),
                                                  child: const Text(
                                                    'Delete',
                                                    style: TextStyle(color: Colors.red),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );

                                          if (confirm == true && context.mounted) {
                                            try {
                                              await ref
                                                  .read(providerServiceProvider)
                                                  .deleteProviderService(service['id']);
                                              ref.invalidate(providerServicesProvider(user.id));
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Service deleted',
                                                      style: TextStyle(fontSize: 13),
                                                    ),
                                                    behavior: SnackBarBehavior.floating,
                                                    margin: EdgeInsets.all(8),
                                                    padding: EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8,
                                                    ),
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Delete failed: $e',
                                                      style: const TextStyle(fontSize: 13),
                                                    ),
                                                backgroundColor: Colors.red,
                                                behavior: SnackBarBehavior.floating,
                                                margin: const EdgeInsets.all(8),
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                      }
                                    },
                                  ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // Show subscription screen for additional services
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SubscriptionRequiredScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Add Another Service'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Text('Error loading services: $error'),
                ),
              ],
            ),
          ),

            const SizedBox(height: 16),

            // Quick Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Actions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  // Bookings with badge
                  Consumer(
                    builder: (context, ref, child) {
                      final pendingCount = ref.watch(pendingBookingsCountProvider);
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _buildActionCard(
                            context,
                            'Bookings',
                            Icons.calendar_today,
                            Colors.blue,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ProviderBookingsScreen(),
                                ),
                              );
                            },
                          ),
                          if (pendingCount.whenOrNull(data: (count) => count > 0) ?? false)
                            Positioned(
                              right: 2,
                              top: -6,
                              child: pendingCount.when(
                                data: (count) => Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 24,
                                    minHeight: 24,
                                  ),
                                  child: Text(
                                    count > 9 ? '9+' : '$count',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                loading: () => const SizedBox.shrink(),
                                error: (_, __) => const SizedBox.shrink(),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Consumer(
                    builder: (context, ref, child) {
                      final unreadCount = ref.watch(unreadMessagesCountProvider);
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _buildActionCard(
                            context,
                            'Messages',
                            Icons.message,
                            Colors.green,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ConversationsScreen(),
                                ),
                              );

                            },
                          ),
                          if (unreadCount.whenOrNull(data: (count) => count > 0) ?? false)
                            Positioned(
                              right: 2,
                              top: -6,
                              child: unreadCount.when(
                                data: (count) => Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 24,
                                    minHeight: 24,
                                  ),
                                  child: Text(
                                    count > 9 ? '9+' : '$count',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                loading: () => const SizedBox.shrink(),
                                error: (_, __) => const SizedBox.shrink(),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildActionCard(
                    context,
                    'Earnings',
                    Icons.attach_money,
                    Colors.purple,
                    () {
                      if (_providerId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProviderEarningsScreen(providerId: _providerId!),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Loading provider data...')),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  // Reviews action with badge showing total review count
                  Consumer(
                    builder: (context, ref, _) {
                      final providerProfileAsync = ref.watch(providerProfileProvider(user.id));

                      return providerProfileAsync.when(
                        data: (profile) {
                          final providerProfile = profile;
                          final totalReviews = providerProfile?.totalReviews ?? 0;

                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              _buildActionCard(
                                context,
                                'Reviews',
                                Icons.star,
                                Colors.amber,
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ProviderReviewsScreen(),
                                    ),
                                  );
                                },
                              ),
                              if (totalReviews > 0)
                                Positioned(
                                  right: 8,
                                  top: -4,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.red.withOpacity(0.3),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      totalReviews.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                        loading: () => _buildActionCard(
                          context,
                          'Reviews',
                          Icons.star,
                          Colors.amber,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProviderReviewsScreen(),
                              ),
                            );
                          },
                        ),
                        error: (_, __) => _buildActionCard(
                          context,
                          'Reviews',
                          Icons.star,
                          Colors.amber,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProviderReviewsScreen(),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Row(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
