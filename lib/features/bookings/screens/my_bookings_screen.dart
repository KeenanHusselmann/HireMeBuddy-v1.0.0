import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/services/booking_service.dart';
import '../../../shared/services/review_service.dart';
import '../../../shared/models/booking.dart';
import 'add_review_screen.dart';
import 'payment_screen.dart';

// Provider for checking review status by booking ID
final reviewStatusProvider = FutureProvider.family.autoDispose<bool, String>((ref, bookingId) async {
  try {
    final review = await ReviewService().getReviewByBookingId(bookingId);
    return review != null;
  } catch (e) {
    print('Error checking review status: $e');
    return false; // Default to no review on error
  }
});

// Real-time stream provider for client bookings
final clientBookingsProvider = StreamProvider.autoDispose<List<Booking>>((ref) async* {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;
  
  if (userId == null) {
    yield [];
    return;
  }
  
  // Get client profile ID first
  final profile = await supabase
      .from('profiles')
      .select('id')
      .eq('user_id', userId)
      .maybeSingle();
  
  if (profile == null) {
    yield [];
    return;
  }
  
  final clientId = profile['id'] as String;
  print('🔴 [CLIENT BOOKINGS] Setting up real-time stream for client: $clientId');
  
  await for (final bookings in supabase
      .from('bookings')
      .stream(primaryKey: ['id'])) {
    // Filter for bookings for this client
    final clientBookings = bookings
        .where((booking) => booking['client_id'] == clientId)
        .map((json) => Booking.fromJson(json))
        .toList();
    
    // Sort by booking date descending
    clientBookings.sort((a, b) => b.bookingDate.compareTo(a.bookingDate));
    
    print('🟢 [CLIENT BOOKINGS] Real-time update: ${clientBookings.length} bookings');
    yield clientBookings;
  }
});

class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});

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
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(clientBookingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(clientBookingsProvider);
            },
          ),
        ],
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
                  ref.invalidate(clientBookingsProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (bookings) {
          if (bookings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No bookings yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Book a service provider to get started',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(clientBookingsProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final booking = bookings[index];
                final statusColor = _getStatusColor(booking.status.value);
                final statusIcon = _getStatusIcon(booking.status.value);

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: InkWell(
                    onTap: () {
                      // TODO: Navigate to booking details
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Booking details coming soon!'),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status Badge
                          Row(
                            children: [
                              Container(
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
                              const Spacer(),
                              Text(
                                'N\$${booking.totalPrice.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal.shade700,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Date and Time
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 20,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('EEEE, MMMM d, yyyy')
                                    .format(booking.bookingDate),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 20,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${booking.bookingTime} (${booking.durationHours} ${booking.durationHours == 1 ? 'hour' : 'hours'})',
                                style: const TextStyle(fontSize: 15),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          Row(
                            children: [
                              Icon(
                                Icons.attach_money,
                                size: 20,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'N\$${booking.hourlyRate.toStringAsFixed(2)}/hour',
                                style: const TextStyle(fontSize: 15),
                              ),
                            ],
                          ),

                          if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.note,
                                  size: 20,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    booking.notes!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 16),

                          // Actions
                          if (booking.status == BookingStatus.completed)
                            Consumer(
                              builder: (context, ref, child) {
                                // Check review status using named provider
                                final hasReviewAsync = ref.watch(reviewStatusProvider(booking.id));
                                
                                return hasReviewAsync.when(
                                  data: (hasReview) {
                                    return Column(
                                      children: [
                                        // Pay Provider button
                                        SizedBox(
                                          width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () async {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => PaymentScreen(
                                                booking: booking,
                                                providerName: 'Provider', // TODO: Add provider name
                                              ),
                                            ),
                                          );
                                          
                                          if (result == true) {
                                            ref.invalidate(clientBookingsProvider);
                                          }
                                        },
                                        icon: const Icon(Icons.payments),
                                        label: const Text('Pay Provider'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.teal,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    // Review button
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed: hasReview ? null : () async {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => AddReviewScreen(
                                                bookingId: booking.id,
                                                providerId: booking.providerId,
                                                providerName: 'Provider', // TODO: Add provider name to booking
                                              ),
                                            ),
                                          );
                                          
                                          if (result == true) {
                                            ref.invalidate(clientBookingsProvider);
                                            ref.invalidate(reviewStatusProvider(booking.id));
                                          }
                                        },
                                        icon: Icon(hasReview ? Icons.check_circle : Icons.rate_review),
                                        label: Text(hasReview ? 'Review Submitted' : 'Write Review'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: hasReview ? Colors.green : null,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                              loading: () => Column(
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => PaymentScreen(
                                              booking: booking,
                                              providerName: 'Provider',
                                            ),
                                          ),
                                        );
                                        
                                        if (result == true) {
                                          ref.invalidate(clientBookingsProvider);
                                        }
                                      },
                                      icon: const Icon(Icons.payments),
                                      label: const Text('Pay Provider'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.teal,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: null,
                                      icon: const Icon(Icons.rate_review),
                                      label: const Text('Loading...'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              error: (error, stack) {
                                // Show buttons even on error (assume no review exists)
                                return Column(
                                  children: [
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () async {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => PaymentScreen(
                                                booking: booking,
                                                providerName: 'Provider',
                                              ),
                                            ),
                                          );
                                          
                                          if (result == true) {
                                            ref.invalidate(clientBookingsProvider);
                                          }
                                        },
                                        icon: const Icon(Icons.payments),
                                        label: const Text('Pay Provider'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.teal,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed: () async {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => AddReviewScreen(
                                                bookingId: booking.id,
                                                providerId: booking.providerId,
                                                providerName: 'Provider',
                                              ),
                                            ),
                                          );
                                          
                                          if (result == true) {
                                            ref.invalidate(clientBookingsProvider);
                                          }
                                        },
                                        icon: const Icon(Icons.rate_review),
                                        label: const Text('Write Review'),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                                );
                              },
                            )
                          else if (booking.status == BookingStatus.pending)
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Cancel Booking'),
                                          content: const Text(
                                            'Are you sure you want to cancel this booking?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('No'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: const Text('Yes'),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirm == true) {
                                        try {
                                          final bookingService = BookingService();
                                          await bookingService.cancelBooking(booking.id);
                                          ref.invalidate(clientBookingsProvider);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Booking cancelled'),
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
                                    icon: const Icon(Icons.cancel_outlined),
                                    label: const Text('Cancel Booking'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                    ),
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
            ),
          );
        },        ),      ),
    );
  }
}
