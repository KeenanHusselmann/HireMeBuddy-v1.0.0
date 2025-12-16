import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/services/booking_service.dart';
import '../../../shared/services/review_service.dart';
import '../../../shared/models/booking.dart';
import '../../../shared/models/booking_with_provider.dart';
import 'add_review_screen.dart';
import 'payment_screen.dart';
import 'client_booking_detail_screen.dart';

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

// Real-time stream provider for client bookings with provider details
final clientBookingsProvider = StreamProvider.autoDispose<List<BookingWithProvider>>((ref) async* {
  final bookingService = BookingService();
  
  await for (final bookings in bookingService.getClientBookingsWithProviderDetails()) {
    print('🟢 [CLIENT BOOKINGS] Real-time update: ${bookings.length} bookings with provider details');
    yield bookings;
  }
});

class MyBookingsScreen extends ConsumerStatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  ConsumerState<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends ConsumerState<MyBookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // Track bookings that were just paid in this session so the UI updates instantly
  final Set<String> _locallyPaidBookings = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<BookingWithProvider> _filterBookings(List<BookingWithProvider> bookings, int tabIndex) {
    switch (tabIndex) {
      case 0: // All
        return bookings;
      case 1: // Pending
        return bookings.where((b) => b.booking.status == BookingStatus.pending).toList();
      case 2: // Confirmed (Accepted)
        return bookings.where((b) => b.booking.status == BookingStatus.confirmed).toList();
      case 3: // Completed
        return bookings.where((b) => b.booking.status == BookingStatus.completed).toList();
      default:
        return bookings;
    }
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
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
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
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Accepted'),
            Tab(text: 'Completed'),
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
                  ref.invalidate(clientBookingsProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (bookings) {
          // Sort bookings by date received (createdAt descending)
          final sortedBookings = [...bookings]
            ..sort((a, b) => b.booking.createdAt.compareTo(a.booking.createdAt));

          return TabBarView(
            controller: _tabController,
            children: [
              // All tab
              _buildBookingsList(sortedBookings, sortedBookings, isAllTab: true),
              // Pending tab
              _buildBookingsList(sortedBookings, _filterBookings(sortedBookings, 1)),
              // Accepted tab
              _buildBookingsList(sortedBookings, _filterBookings(sortedBookings, 2)),
              // Completed tab
              _buildBookingsList(sortedBookings, _filterBookings(sortedBookings, 3)),
            ],
          );
        },
      ),
    ));
  }

  Widget _buildBookingsList(List<BookingWithProvider> allBookings, List<BookingWithProvider> filteredBookings, {bool isAllTab = false}) {
    // Show status category cards for "All" tab
    if (isAllTab) {
      final pendingCount = allBookings.where((b) => b.booking.status == BookingStatus.pending).length;
      final confirmedCount = allBookings.where((b) => b.booking.status == BookingStatus.confirmed).length;
      final completedCount = allBookings.where((b) => b.booking.status == BookingStatus.completed).length;
      final cancelledCount = allBookings.where((b) => b.booking.status == BookingStatus.cancelled).length;

      return RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(clientBookingsProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Booking Categories',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'See a quick summary of your new booking updates by status.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              Column(
                children: [
                  _buildStatusCard(
                    title: 'Pending',
                    count: pendingCount,
                    icon: Icons.schedule,
                    color: Colors.orange,
                    onTap: () => _tabController.animateTo(1),
                    showBadge: pendingCount > 0,
                  ),
                  const SizedBox(height: 12),
                  _buildStatusCard(
                    title: 'Accepted',
                    count: confirmedCount,
                    icon: Icons.check_circle,
                    color: Colors.green,
                    onTap: () => _tabController.animateTo(2),
                    showBadge: confirmedCount > 0,
                  ),
                  const SizedBox(height: 12),
                  _buildStatusCard(
                    title: 'Completed',
                    count: completedCount,
                    icon: Icons.done_all,
                    color: Colors.blue,
                    onTap: () => _tabController.animateTo(3),
                    showBadge: completedCount > 0,
                  ),
                  const SizedBox(height: 12),
                  _buildStatusCard(
                    title: 'Cancelled',
                    count: cancelledCount,
                    icon: Icons.cancel,
                    color: Colors.red,
                    onTap: null,
                    showBadge: cancelledCount > 0,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (filteredBookings.isEmpty) {
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
        itemCount: filteredBookings.length,
        itemBuilder: (context, index) {
          final booking = filteredBookings[index];
          final statusColor = _getStatusColor(booking.booking.status.value);
          final statusIcon = _getStatusIcon(booking.booking.status.value);

          // Show detailed card
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Job Number and Status Badge
                  Row(
                    children: [
                      // Job Number
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade700,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          booking.booking.jobNumber,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
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
                              booking.booking.status.value.toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Total Price - Displayed prominently on its own line
                  Row(
                    children: [
                      Icon(
                        Icons.payments,
                        size: 24,
                        color: Colors.teal.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Total: ',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'N\$${booking.booking.totalPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade700,
                        ),
                      ),
                    ],
                  ),

                          const SizedBox(height: 16),

                          // Provider Info Section
                          InkWell(
                            onTap: () {
                              // Navigate to booking detail screen with completion info
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ClientBookingDetailScreen(
                                    bookingWithProvider: booking,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade700.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.teal.shade700.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: Colors.teal.shade700,
                                    backgroundImage: booking.providerAvatar != null
                                        ? NetworkImage(booking.providerAvatar!)
                                        : null,
                                    child: booking.providerAvatar == null
                                        ? Text(
                                            booking.providerName.isNotEmpty
                                                ? booking.providerName[0].toUpperCase()
                                                : 'P',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Provider',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade700,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          booking.providerName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (booking.providerPhone != null)
                                          Text(
                                            booking.providerPhone!,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: Colors.grey.shade700,
                                  ),
                                ],
                              ),
                            ),
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
                                    .format(booking.booking.bookingDate),
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
                                '${booking.booking.bookingTime} (${booking.booking.durationHours} ${booking.booking.durationHours == 1 ? 'hour' : 'hours'})',
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
                                'N\$${booking.booking.hourlyRate.toStringAsFixed(2)}/hour',
                                style: const TextStyle(fontSize: 15),
                              ),
                            ],
                          ),

                          if (booking.booking.notes != null && booking.booking.notes!.isNotEmpty) ...[
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
                                    booking.booking.notes!,
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
                          if (booking.booking.status == BookingStatus.completed)
                            Consumer(
                              builder: (context, ref, child) {
                                final hasReviewAsync = ref.watch(reviewStatusProvider(booking.booking.id));
                                final paymentStatusAsync = ref.watch(bookingPaymentStatusProvider(booking.booking.id));
                                
                                return paymentStatusAsync.when(
                                  data: (paymentStatus) {
                                    return hasReviewAsync.when(
                                      data: (hasReview) {
                                        final isPaid = paymentStatus == 'paid' ||
                                            _locallyPaidBookings.contains(booking.booking.id);
                                        return Column(
                                          children: [
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            onPressed: isPaid
                                                ? null
                                                : () async {
                                                    final result = await Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) => PaymentScreen(
                                                          booking: booking.booking,
                                                          providerName: booking.providerName,
                                                          providerPhone: booking.providerPhone,
                                                        ),
                                                      ),
                                                    );
                                                    if (result == true) {
                                                      // Mark as paid locally so the UI updates instantly
                                                      setState(() {
                                                        _locallyPaidBookings.add(booking.booking.id);
                                                      });
                                                      // Also refresh remote providers for consistency
                                                      ref.invalidate(clientBookingsProvider);
                                                      ref.invalidate(bookingPaymentStatusProvider(booking.booking.id));
                                                    }
                                                  },
                                            icon: Icon(
                                              isPaid
                                                  ? Icons.check_circle
                                                  : Icons.payments,
                                            ),
                                            label: Text(
                                              isPaid
                                                  ? 'Provider Paid'
                                                  : 'Pay Provider',
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  isPaid
                                                      ? Colors.grey.shade300
                                                      : Colors.teal,
                                              foregroundColor:
                                                  isPaid
                                                      ? Colors.grey.shade700
                                                      : Colors.white,
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                            ),
                                          ),
                                        ),
                                            const SizedBox(height: 8),
                                            SizedBox(
                                              width: double.infinity,
                                              child: OutlinedButton.icon(
                                                onPressed: hasReview ? null : () async {
                                                  final result = await Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) => AddReviewScreen(
                                                        bookingId: booking.booking.id,
                                                        providerId: booking.booking.providerId,
                                                        providerName: booking.providerName,
                                                      ),
                                                    ),
                                                  );
                                                  if (result == true) {
                                                    ref.invalidate(clientBookingsProvider);
                                                    ref.invalidate(reviewStatusProvider(booking.booking.id));
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
                                      loading: () => const CircularProgressIndicator(),
                                      error: (error, stack) => const SizedBox(),
                                    );
                                  },
                                  loading: () => const CircularProgressIndicator(),
                                  error: (error, stack) => const SizedBox(),
                                );
                              },
                            ),
                          if (booking.booking.status == BookingStatus.pending)
                            OutlinedButton.icon(
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Cancel Booking'),
                                    content: const Text('Are you sure you want to cancel this booking?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('No'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('Yes'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  try {
                                    final bookingService = BookingService();
                                    await bookingService.cancelBooking(booking.booking.id);
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }


  Widget _buildStatusCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
    required bool showBadge,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Row(
            children: [
              // Icon on the left
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              // Text content in the middle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$count ${count == 1 ? 'booking' : 'bookings'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Badge on the right
              if (showBadge && count > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}