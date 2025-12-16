import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/services/booking_service.dart';
import '../../../shared/models/booking_with_client.dart';
import '../widgets/job_completion_dialog.dart';
import 'booking_detail_screen.dart';

final bookingServiceProvider = Provider<BookingService>((ref) {
  return BookingService();
});

// Provider to check if a booking has been paid
final bookingPaymentStatusProvider = FutureProvider.autoDispose.family<String, String>((ref, bookingId) async {
  final supabase = Supabase.instance.client;
  try {
    final payment = await supabase
        .from('payments')
        .select('status')
        .eq('booking_id', bookingId)
        .eq('status', 'paid')
        .maybeSingle();
    return payment != null ? 'paid' : 'pending';
  } catch (e) {
    return 'pending';
  }
});

final providerBookingsProvider = StreamProvider.autoDispose<List<BookingWithClient>>((ref) {
  final supabase = Supabase.instance.client;
  final bookingService = BookingService();
  
  // Create a stream controller to manage booking updates
  final controller = StreamController<List<BookingWithClient>>();
  
  // Debounce timer to prevent rapid successive calls
  Timer? debounceTimer;
  
  Future<void> loadBookings() async {
    // Cancel any pending debounce timer
    debounceTimer?.cancel();
    
    // Debounce: wait 500ms before actually loading
    debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      if (!controller.isClosed) {
        final bookings = await bookingService.getProviderBookingsWithClientDetails();
        if (!controller.isClosed) {
          controller.add(bookings);
        }
      }
    });
  }
  
  // Load initial data
  loadBookings();
  
  // Subscribe to real-time changes
  final subscription = supabase
      .channel('provider_bookings_realtime')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'bookings',
        callback: (payload) async {
          print('🔄 Booking change detected: ${payload.eventType}');
          // Debounced reload - prevents multiple rapid calls
          loadBookings();
        },
      )
      .subscribe();
  
  // Cleanup when provider is disposed
  ref.onDispose(() {
    debounceTimer?.cancel();
    subscription.unsubscribe();
    controller.close();
  });
  
  return controller.stream;
});

class ProviderBookingsScreen extends ConsumerStatefulWidget {
  const ProviderBookingsScreen({super.key});

  @override
  ConsumerState<ProviderBookingsScreen> createState() => _ProviderBookingsScreenState();
}

class _ProviderBookingsScreenState extends ConsumerState<ProviderBookingsScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'confirmed':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'completed':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(providerBookingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        backgroundColor: Colors.deepOrange.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(providerBookingsProvider);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
          tabs: [
            Tab(
              icon: const Icon(Icons.schedule, size: 18),
              text: 'Pending',
            ),
            Tab(
              icon: const Icon(Icons.check_circle, size: 18),
              text: 'Confirmed',
            ),
            Tab(
              icon: const Icon(Icons.done_all, size: 18),
              text: 'Completed',
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: bookingsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(providerBookingsProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (bookings) {
          // Filter bookings by status
          final pendingBookings = bookings.where((b) => b.booking.status.value == 'pending').toList();
          final confirmedBookings = bookings.where((b) => b.booking.status.value == 'confirmed').toList();
          final completedBookings = bookings.where((b) => b.booking.status.value == 'completed').toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildBookingsList(pendingBookings, ref, 'pending'),
              _buildBookingsList(confirmedBookings, ref, 'confirmed'),
              _buildBookingsList(completedBookings, ref, 'completed'),
            ],
          );
        },
        ),
      ),
    );
  }

  Widget _buildBookingsList(List<BookingWithClient> bookings, WidgetRef ref, String category) {
    if (bookings.isEmpty) {
      String message;
      IconData icon;
      
      switch (category) {
        case 'pending':
          message = 'No pending bookings';
          icon = Icons.schedule;
          break;
        case 'confirmed':
          message = 'No confirmed bookings';
          icon = Icons.check_circle;
          break;
        case 'completed':
          message = 'No completed bookings';
          icon = Icons.done_all;
          break;
        default:
          message = 'No bookings yet';
          icon = Icons.event_busy;
      }
      
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (category == 'all')
              const SizedBox(height: 8),
            if (category == 'all')
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Bookings will appear here when clients book your services',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(providerBookingsProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final bookingWithClient = bookings[index];
          final booking = bookingWithClient.booking;
          // Payment status will be checked via provider in the UI
          final statusColor = _getStatusColor(booking.status.value);
          final statusIcon = _getStatusIcon(booking.status.value);

          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookingDetailScreen(
                    bookingWithClient: bookingWithClient,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Job Number, Status Badge
                    Row(
                      children: [
                        // Job Number
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.deepOrange.shade600,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            booking.jobNumber,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Consumer(
                          builder: (context, ref, child) {
                            final paymentStatusAsync = ref.watch(bookingPaymentStatusProvider(booking.id));
                            return paymentStatusAsync.when(
                              data: (paymentStatus) {
                                final isPaid = paymentStatus == 'paid';
                                final displayStatusColor = isPaid ? Colors.grey : statusColor;
                                final displayStatusIcon = isPaid ? Icons.payments : statusIcon;
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: displayStatusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: displayStatusColor),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        displayStatusIcon,
                                        size: 16,
                                        color: displayStatusColor,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        isPaid ? 'PROVIDER PAID' : booking.status.value.toUpperCase(),
                                        style: TextStyle(
                                          color: displayStatusColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              loading: () => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: statusColor),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      statusIcon,
                                      size: 16,
                                      color: statusColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      booking.status.value.toUpperCase(),
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              error: (_, __) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: statusColor),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      statusIcon,
                                      size: 16,
                                      color: statusColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      booking.status.value.toUpperCase(),
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Total Amount (below job number to avoid overflow)
                    Text(
                      'N\$${booking.totalPrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange.shade700,
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                  // Client Information Section
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.deepOrange.shade100,
                        backgroundImage: bookingWithClient.clientProfileImage != null
                            ? NetworkImage(bookingWithClient.clientProfileImage!)
                            : null,
                        child: bookingWithClient.clientProfileImage == null
                            ? Text(
                                bookingWithClient.clientName[0].toUpperCase(),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepOrange.shade700,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CLIENT',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              bookingWithClient.clientName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (bookingWithClient.clientPhone != null && bookingWithClient.clientPhone!.isNotEmpty)
                              Row(
                                children: [
                                  Icon(
                                    Icons.phone,
                                    size: 16,
                                    color: Colors.deepOrange.shade600,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    bookingWithClient.clientPhone!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade800,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            if (bookingWithClient.clientPhone != null && 
                                bookingWithClient.clientPhone!.isNotEmpty &&
                                bookingWithClient.clientEmail != null && 
                                bookingWithClient.clientEmail!.isNotEmpty)
                              const SizedBox(height: 4),
                            if (bookingWithClient.clientEmail != null && bookingWithClient.clientEmail!.isNotEmpty)
                              Row(
                                children: [
                                  Icon(
                                    Icons.email,
                                    size: 16,
                                    color: Colors.deepOrange.shade600,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      bookingWithClient.clientEmail!,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade800,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                    const SizedBox(height: 12),

                    // Accept button for pending bookings
                    if (booking.status.value == 'pending')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            await ref.read(bookingServiceProvider).updateBookingStatus(
                              booking.id,
                              'confirmed',
                            );
                            
                            // Send notification to client using database function
                            try {
                              print('📤 Sending notification to client: ${booking.clientId}');
                              print('   Booking ID: ${booking.id}');
                              
                              final result = await Supabase.instance.client.rpc(
                                'send_notification',
                                params: {
                                  'p_user_id': booking.clientId,
                                  'p_title': 'Booking Accepted',
                                  'p_body': 'Your booking has been accepted by the provider!',
                                  'p_type': 'booking_update',
                                },
                              );
                              
                              print('✅ Acceptance notification sent via RPC: $result');
                            } catch (e, stack) {
                              print('❌ Error sending acceptance notification: $e');
                              print('Stack trace: $stack');
                            }
                            
                            ref.invalidate(providerBookingsProvider);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Booking accepted!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.check_circle),
                        label: const Text(
                          'Accept Booking',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  if (booking.status.value == 'pending')
                    const SizedBox(height: 12),

                  // Complete Job button for confirmed bookings
                  if (booking.status.value == 'confirmed')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final result = await showDialog<Map<String, String?>>(
                            context: context,
                            builder: (context) => const JobCompletionDialog(),
                          );

                          if (result != null) {
                            try {
                              await ref.read(bookingServiceProvider).updateBookingStatus(
                                booking.id,
                                'completed',
                                completionNotes: result['completionNotes'],
                                workCompleted: result['workCompleted'],
                                issuesEncountered: result['issuesEncountered'],
                              );
                              
                              // Send notification to client
                              final supabase = Supabase.instance.client;
                              await supabase.from('notifications').insert({
                                'user_id': bookingWithClient.booking.clientId,
                                'title': 'Job Completed',
                                'body': 'Your job has been completed. Please proceed with payment.',
                                'type': 'booking_completed',
                              });

                              ref.invalidate(providerBookingsProvider);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Job marked as completed! Client has been notified.'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.task_alt),
                        label: const Text(
                          'Complete Job',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  if (booking.status.value == 'confirmed')
                    const SizedBox(height: 12),

                  // Tap to view details hint
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.touch_app,
                          size: 16,
                          color: Colors.deepOrange.shade700,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Tap to view booking details',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.deepOrange.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
