import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/logger.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/services/notification_service.dart';
import '../../../shared/services/workmanager_notification_service.dart';
import '../../bookings/screens/my_bookings_screen.dart';
import '../widgets/provider_video_feed.dart';

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
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
    setState(() => _notificationsInitialized = true);
    
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _loadProfileId(user.id);
    }
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
        
        // Start WorkManager for periodic background notifications (checks every 15 minutes)
        WorkManagerNotificationService.initialize(_myProfileId!, 'client').then((_) {
          logger.info('✅ Client WorkManager background task registered for: $_myProfileId');
        }).catchError((e) {
          logger.error('❌ Client WorkManager initialization error', e);
        });
        
        logger.info('✅ Client subscribed to notifications for: $_myProfileId');
      }
    } catch (e) {
      logger.error('Error loading profile ID', e);
    }
  }

  @override
  void dispose() {
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
                  // Navigate to services list
                  context.push('/services');
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
              context.push('/services');
            },
            child: const Text('Browse All Services'),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 24.0),
              child: Column(
                children: [
                  Center(child: const AppLogo(width: 180)),
                  const SizedBox(height: 16),
                  const Text(
                    'Connecting Namibian Skills with Opportunities',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
            
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Builder(
                builder: (context) {
                  final TextEditingController searchController = TextEditingController();
                  return TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search for services...',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search, color: Colors.teal),
                        tooltip: 'Search',
                        onPressed: () {
                          _performSearch(context, ref, searchController.text);
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Colors.teal, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                    onSubmitted: (String searchQuery) {
                      _performSearch(context, ref, searchQuery);
                    },
                  );
                },
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Browse Services Button
            ElevatedButton(
              onPressed: () => context.push('/services'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Browse Services',
                style: TextStyle(fontSize: 16),
              ),
            ),
            
            const SizedBox(height: 16),

            // My Bookings Button with Badge
            Consumer(
              builder: (context, ref, child) {
                final pendingCount = ref.watch(clientPendingBookingsCountProvider);
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MyBookingsScreen(),
                          ),
                        );
                        // Refresh count after navigation
                        Future.delayed(const Duration(milliseconds: 500), () {
                          ref.invalidate(clientPendingBookingsCountProvider);
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        backgroundColor: Colors.teal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.calendar_today),
                      label: const Text(
                        'My Bookings',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    pendingCount.when(
                      data: (count) => count > 0
                          ? Positioned(
                              right: -8,
                              top: -8,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 20,
                                  minHeight: 20,
                                ),
                                child: Text(
                                  count > 9 ? '9+' : '$count',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
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
            
            const SizedBox(height: 24),
            
            // Provider Video Feed (full width, no padding)
            const ProviderVideoFeed(),
          ],
        ),
      ),
      ),
    );
  }
}
