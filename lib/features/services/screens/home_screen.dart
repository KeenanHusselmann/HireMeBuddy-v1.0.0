import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/logger.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/services/notification_service.dart';

import '../../../core/services/deep_link_handler.dart';
import '../../bookings/screens/my_bookings_screen.dart';
import '../../chat/screens/conversations_screen.dart';

// Real-time stream provider for client pending bookings count
final clientPendingBookingsCountProvider = StreamProvider.autoDispose<int>((ref) async* {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;
  
  if (userId == null) {
    yield 0;
    return;
  }
  
  // Get client profile ID first
  final profile = await supabase
      .from('profiles')
      .select('id')
      .eq('user_id', userId)
      .maybeSingle();
  
  if (profile == null) {
    yield 0;
    return;
  }
  
  final clientId = profile['id'] as String;
  logger.debug('🔴 [CLIENT PENDING] Setting up real-time stream for client: $clientId');
  
  await for (final bookings in supabase
      .from('bookings')
      .stream(primaryKey: ['id'])) {
    // Filter for pending bookings for this client
    final pendingBookings = bookings.where((booking) => 
      booking['client_id'] == clientId && 
      booking['status'] == 'pending'
    ).toList();
    
    final count = pendingBookings.length;
    logger.debug('🟢 [CLIENT PENDING] Real-time update: $count pending bookings');
    yield count;
  }
});

// Provider for client unread messages count (real-time)
final clientUnreadMessagesCountProvider = StreamProvider.autoDispose<int>((ref) async* {
  logger.debug('🔴 Setting up client unread messages stream...');
  
  // Get current user's profile ID first
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) {
    logger.error('❌ No authenticated user', Exception('No user'));
    yield 0;
    return;
  }

  try {
    final profileResponse = await Supabase.instance.client
        .from('profiles')
        .select('id')
        .eq('user_id', user.id)
        .single();
    
    final profileId = profileResponse['id'] as String;
    logger.debug('✅ Client profile_id: $profileId');

    // Stream unread messages
    await for (final messages in Supabase.instance.client
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .asyncMap((data) async {
          // Filter for messages where this user is receiver and not read
          final filtered = data.where((msg) {
            final receiverId = msg['receiver_id'] as String?;
            final isRead = msg['read'] as bool? ?? false;
            return receiverId == profileId && !isRead;
          }).toList();
          
          logger.debug('🟢 Client unread messages count updated: ${filtered.length}');
          return filtered;
        })) {
      yield messages.length;
    }
  } catch (e) {
    logger.error('❌ Error in client unread messages stream', e);
    yield 0;
  }
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _notificationService = NotificationService();
  bool _notificationsInitialized = false;
  String? _myProfileId;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _registerDeepLinkHandler();
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
    setState(() => _notificationsInitialized = true);
    
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _loadProfileId(user.id);
    }
  }
  
  void _registerDeepLinkHandler() {
    // Register callback to handle deep link navigation from push notifications
    DeepLinkHandler().registerNavigationCallback((route, {params}) {
      
      // Use addPostFrameCallback to ensure navigation happens after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        
        switch (route) {
          case 'bookings':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MyBookingsScreen(),
              ),
            );
            break;
            
          case 'messages':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ConversationsScreen(),
              ),
            );
            break;
            
          default:
            break;
        }
      });
    });
  }

  Future<void> _loadProfileId(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .single();
      
      setState(() {
        _myProfileId = response['id'] as String;
      });
      
      if (_notificationsInitialized && _myProfileId != null) {
        _notificationService.subscribeToMessages(_myProfileId!);
        _notificationService.subscribeToNotifications(_myProfileId!);
        logger.info('✅ Client subscribed to notifications for: $_myProfileId');
      }
    } catch (e) {
      logger.error('Error loading profile ID', e);
    }
  }

  @override
  void dispose() {
    // Clear deep link callbacks to prevent memory leaks
    DeepLinkHandler().clearCallbacks();
    _notificationService.unsubscribeAll();
    super.dispose();
  }

  // Search for services
  Future<void> _performSearch(BuildContext context, WidgetRef ref, String query) async {
    if (query.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a service name to search'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Search for services (case-insensitive)
      final supabase = Supabase.instance.client;
      final results = await supabase
          .from('service_categories')
          .select('id, name, description')
          .ilike('name', '%${query.trim()}%');

      // Close loading dialog
      if (context.mounted) Navigator.of(context).pop();

      if (results.isEmpty) {
        // Service not found - show dialog with suggestion option
        if (context.mounted) {
          _showServiceNotFoundDialog(context, query.trim());
        }
      } else {
        // Services found - navigate to service list with filter
        if (context.mounted) {
          _showSearchResultsDialog(context, results, query.trim());
        }
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) Navigator.of(context).pop();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showServiceNotFoundDialog(BuildContext context, String searchQuery) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, color: Colors.orange, size: 24),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Service Not Available',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sorry, "$searchQuery" is not yet available on our platform.',
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            const Text(
              'Would you like to suggest this service?',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _suggestService(context, searchQuery);
            },
            icon: const Icon(Icons.lightbulb_outline, size: 18),
            label: const Text('Suggest Service', style: TextStyle(fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
    );
  }

  void _showSearchResultsDialog(BuildContext context, List<dynamic> results, String searchQuery) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Found ${results.length} service(s)'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: results.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final service = results[index];
              return ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: Text(
                  service['name'] as String,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: service['description'] != null
                    ? Text(service['description'] as String)
                    : null,
                onTap: () {
                  Navigator.of(context).pop();
                  // Navigate to services list filtered by this service
                  final serviceName = service['name'] as String;
                  // URL encode the category to handle spaces and special characters
                  final encodedCategory = Uri.encodeComponent(serviceName);
                  context.push('/services?category=$encodedCategory');
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Get the first service category name to filter by
              final firstServiceName = results.isNotEmpty 
                  ? results[0]['name'] as String 
                  : searchQuery;
              // URL encode the category to handle spaces and special characters
              final encodedCategory = Uri.encodeComponent(firstServiceName);
              context.push('/services?category=$encodedCategory');
            },
            child: const Text('Browse'),
          ),
        ],
      ),
    );
  }

  Future<void> _suggestService(BuildContext context, String serviceName) async {
    final TextEditingController descriptionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suggest a Service'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Service: $serviceName',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Why do you need this service? (Optional)',
                border: OutlineInputBorder(),
                hintText: 'Tell us more about this service...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Save suggestion to database and create admin notification
              try {
                final supabase = Supabase.instance.client;
                final userId = supabase.auth.currentUser?.id;
                
                logger.debug('🔔 [SUGGESTION] User ID: $userId');
                
                if (userId != null) {
                  // Get user's name for the notification
                  final userProfile = await supabase
                      .from('profiles')
                      .select('full_name')
                      .eq('id', userId)
                      .maybeSingle();
                  
                  final userName = userProfile?['full_name'] as String? ?? 'A user';
                  final description = descriptionController.text.trim();
                  
                  logger.debug('🔔 [SUGGESTION] User: $userName, Service: $serviceName');
                  
                  // Create admin notification
                  final result = await supabase.rpc('create_admin_notification', params: {
                    'p_type': 'service_suggestion',
                    'p_title': 'New Service Suggestion',
                    'p_message': '$userName suggested: "$serviceName"${description.isNotEmpty ? ' - $description' : ''}',
                    'p_metadata': {
                      'service_name': serviceName,
                      'description': description,
                      'user_id': userId,
                      'user_name': userName,
                    },
                  });
                  
                  logger.debug('🔔 [SUGGESTION] RPC Result: $result');
                  
                  Navigator.of(context).pop();
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Thank you! Your suggestion has been submitted.'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                }
              } catch (e) {
                logger.error('❌ [SUGGESTION] Error', e);
                Navigator.of(context).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error submitting suggestion: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(userProfileProvider);

    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.white),
          title: userProfile.when(
            data: (profile) => Text(
              'Welcome, ${profile?.firstNameOrFull ?? "User"}!',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            loading: () => const Text('Welcome!'),
            error: (_, __) => const Text('Welcome!'),
          ),
          actions: [
            // Messages bell with unread badge
            Consumer(
              builder: (context, ref, child) {
                final unreadAsync = ref.watch(clientUnreadMessagesCountProvider);
                final unreadCount = unreadAsync.when(
                  data: (count) => count,
                  loading: () => 0,
                  error: (_, __) => 0,
                );

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_none),
                      tooltip: 'Messages',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ConversationsScreen(),
                          ),
                        );
                      },
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unreadCount > 9 ? '9+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            // Existing overflow menu
            IconButton(
              icon: const Icon(Icons.more_vert),
              color: Colors.white,
              tooltip: 'Menu',
              onPressed: () {
                showMenu(
                  context: context,
                  position: RelativeRect.fromLTRB(
                    MediaQuery.of(context).size.width,
                    kToolbarHeight,
                    0,
                    0,
                  ),
                  items: [
                    const PopupMenuItem(
                      value: 'profile',
                      child: Row(
                        children: [
                          Icon(Icons.person),
                          SizedBox(width: 8),
                          Text('Profile'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout),
                          SizedBox(width: 8),
                          Text('Logout'),
                        ],
                      ),
                    ),
                  ],
                ).then((value) async {
                  if (value != null) {
                    switch (value) {
                      case 'profile':
                        context.push('/profile');
                        break;
                      case 'logout':
                        await ref.read(authStateProvider.notifier).signOut();
                        if (context.mounted) {
                          context.go('/login');
                        }
                        break;
                    }
                  }
                });
              },
            ),
          ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // HERO SECTION - Eye-catching gradient banner
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.teal.shade700,
                    Colors.teal.shade500,
                    Colors.cyan.shade400,
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                  child: Column(
                    children: [
                      const AppLogo(width: 180),
                      const SizedBox(height: 24),
                      const Text(
                        'Find Trusted Local Services in Namibia',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'From plumbers to photographers, book skilled professionals near you in seconds',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      
                      // SEARCH BAR - Prominent placement
                      Builder(
                        builder: (context) {
                          final TextEditingController searchController = TextEditingController();
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: searchController,
                              decoration: InputDecoration(
                                hintText: 'What service do you need?',
                                hintStyle: TextStyle(color: Colors.grey.shade400),
                                prefixIcon: const Icon(Icons.search, color: Colors.teal, size: 28),
                                suffixIcon: Container(
                                  margin: const EdgeInsets.all(6),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      _performSearch(context, ref, searchController.text);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text('Search', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                              ),
                              onSubmitted: (String searchQuery) {
                                _performSearch(context, ref, searchQuery);
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // QUICK ACTIONS - Prominent CTA buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/services'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.grid_view_rounded, size: 24),
                      label: const Text(
                        'Browse All Services',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // My Bookings Button with Badge
                  Consumer(
                    builder: (context, ref, child) {
                      final pendingCount = ref.watch(clientPendingBookingsCountProvider);
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const MyBookingsScreen(),
                                  ),
                                );
                                Future.delayed(const Duration(milliseconds: 500), () {
                                  ref.invalidate(clientPendingBookingsCountProvider);
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                foregroundColor: Colors.teal,
                                side: const BorderSide(color: Colors.teal, width: 2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.calendar_today, size: 24),
                              label: const Text(
                                'My Bookings',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          pendingCount.when(
                            data: (count) => count > 0
                                ? Positioned(
                                    right: 12,
                                    top: -8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        count > 9 ? '9+' : '$count',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 48),
            
            // HOW IT WORKS SECTION
            Container(
              width: double.infinity,
              color: Colors.grey.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
              child: Column(
                children: [
                  const Text(
                    'How It Works',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Book a service in 3 simple steps',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  _buildHowItWorksStep(
                    '1',
                    'Browse Services',
                    'Search for the service you need or browse categories',
                    Icons.search_rounded,
                    Colors.blue,
                    'screenshot_browse_services.png', // IMAGE TITLE
                  ),
                  const SizedBox(height: 32),
                  
                  _buildHowItWorksStep(
                    '2',
                    'Choose a Provider',
                    'View provider profiles, ratings, and videos to find your perfect match',
                    Icons.person_search_rounded,
                    Colors.orange,
                    'screenshot_provider_profile.png', // IMAGE TITLE
                  ),
                  const SizedBox(height: 32),
                  
                  _buildHowItWorksStep(
                    '3',
                    'Book & Connect',
                    'Schedule a booking, chat with your provider, and get the job done',
                    Icons.check_circle_rounded,
                    Colors.green,
                    'screenshot_booking_chat.png', // IMAGE TITLE
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 48),
            
            // WHY CHOOSE US SECTION
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const Text(
                    'Why Choose HireMeBuddy?',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  _buildFeatureCard(
                    Icons.verified_user_rounded,
                    'Verified Professionals',
                    'All service providers are verified with ID and background checks',
                    Colors.teal,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildFeatureCard(
                    Icons.star_rounded,
                    'Ratings & Reviews',
                    'Real reviews from real customers help you make informed decisions',
                    Colors.amber,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildFeatureCard(
                    Icons.video_library_rounded,
                    'Video Portfolios',
                    'Watch providers showcase their skills before you book',
                    Colors.purple,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildFeatureCard(
                    Icons.chat_bubble_rounded,
                    'Direct Messaging',
                    'Chat with providers to discuss your needs and get quotes',
                    Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildFeatureCard(
                    Icons.payment_rounded,
                    'Secure Payments',
                    'Pay securely through the app with multiple payment options',
                    Colors.green,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 48),
            
            // POPULAR SERVICES PREVIEW
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.teal.shade50,
                    Colors.cyan.shade50,
                  ],
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
              child: Column(
                children: [
                  const Text(
                    'Popular Services',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'What Namibians are booking right now',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildServiceChip('Plumbing', Icons.plumbing_rounded),
                      _buildServiceChip('Electrical', Icons.electrical_services_rounded),
                      _buildServiceChip('Cleaning', Icons.cleaning_services_rounded),
                      _buildServiceChip('Painting', Icons.format_paint_rounded),
                      _buildServiceChip('Gardening', Icons.yard_rounded),
                      _buildServiceChip('Photography', Icons.camera_alt_rounded),
                      _buildServiceChip('Catering', Icons.restaurant_rounded),
                      _buildServiceChip('Tutoring', Icons.school_rounded),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  ElevatedButton(
                    onPressed: () => context.push('/services'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'View All Services',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 48),
          ],
        ),
      ),
      ),
    );
  }

  // Helper widget: How It Works step with image placeholder
  Widget _buildHowItWorksStep(
    String stepNumber,
    String title,
    String description,
    IconData icon,
    Color color,
    String imageName,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step number badge
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                stepNumber,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                // Screenshot placeholder - Add your image here
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_outlined, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text(
                          imageName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Add screenshot here',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget: Feature card
  Widget _buildFeatureCard(IconData icon, String title, String description, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget: Service chip
  Widget _buildServiceChip(String label, IconData icon) {
    return ActionChip(
      avatar: Icon(icon, size: 20, color: Colors.teal.shade700),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.teal.shade700,
        ),
      ),
      backgroundColor: Colors.white,
      side: BorderSide(color: Colors.teal.shade200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      onPressed: () {
        context.push('/services?category=${Uri.encodeComponent(label)}');
      },
    );
  }
}
