import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/models/booking_with_provider.dart';

class ClientBookingDetailScreen extends StatelessWidget {
  final BookingWithProvider bookingWithProvider;

  const ClientBookingDetailScreen({
    super.key,
    required this.bookingWithProvider,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.teal;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'accepted':
        return Icons.check_circle;
      case 'in_progress':
        return Icons.work;
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
    final booking = bookingWithProvider.booking;
    final statusColor = _getStatusColor(booking.status.value);
    final statusIcon = _getStatusIcon(booking.status.value);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header Section with Status and Price
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.teal.shade600,
                      Colors.teal.shade400,
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            booking.status.value.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'N\$${booking.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total Amount',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),

              // Content Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Provider Information Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.person,
                                  color: Colors.teal.shade600,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'PROVIDER INFORMATION',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.teal.shade100,
                                  backgroundImage: bookingWithProvider.providerAvatar != null
                                      ? NetworkImage(bookingWithProvider.providerAvatar!)
                                      : null,
                                  child: bookingWithProvider.providerAvatar == null
                                      ? Text(
                                          bookingWithProvider.providerName[0].toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.teal.shade700,
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
                                        bookingWithProvider.providerName,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      if (bookingWithProvider.providerPhone != null)
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.phone,
                                              size: 16,
                                              color: Colors.grey.shade600,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              bookingWithProvider.providerPhone!,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Booking Details Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.event,
                                  color: Colors.teal.shade600,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'BOOKING DETAILS',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            _buildDetailRow(
                              Icons.calendar_today,
                              'Date',
                              DateFormat('EEEE, MMMM d, yyyy').format(booking.bookingDate),
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              Icons.access_time,
                              'Time',
                              '${booking.bookingTime} (${booking.durationHours} hour${booking.durationHours > 1 ? 's' : ''})',
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              Icons.payments,
                              'Rate',
                              'N\$${booking.hourlyRate.toStringAsFixed(2)}/hour',
                            ),
                            if (booking.jobLocation != null && booking.jobLocation!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _buildDetailRow(
                                Icons.location_on,
                                'Location',
                                booking.jobLocation!,
                              ),
                            ],
                            if (booking.jobInstructions != null && booking.jobInstructions!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _buildDetailRow(
                                Icons.description,
                                'Instructions',
                                booking.jobInstructions!,
                              ),
                            ],
                            if (booking.clientBudget != null) ...[
                              const SizedBox(height: 12),
                              _buildDetailRow(
                                Icons.account_balance_wallet,
                                'Your Budget',
                                'N\$${booking.clientBudget!.toStringAsFixed(2)}',
                              ),
                            ],
                            if (booking.secondaryContact != null && booking.secondaryContact!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _buildDetailRow(
                                Icons.contact_phone,
                                'Secondary Contact',
                                booking.secondaryContact!,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Job Completion Report (only for completed bookings)
                    if (booking.status.value == 'completed') ...[
                      const SizedBox(height: 16),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.task_alt,
                                    color: Colors.green.shade600,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'JOB COMPLETION REPORT',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              
                              // Completed timestamp
                              if (booking.completedAt != null) ...[
                                Row(
                                  children: [
                                    Icon(
                                      Icons.schedule,
                                      size: 18,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Completed: ${DateFormat('MMM d, yyyy \'at\' h:mm a').format(booking.completedAt!)}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade700,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Work Completed
                              if (booking.workCompleted != null && booking.workCompleted!.isNotEmpty) ...[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.done_all,
                                      size: 20,
                                      color: Colors.green.shade700,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Work Completed',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            booking.workCompleted!,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Issues/Delays
                              if (booking.issuesEncountered != null && booking.issuesEncountered!.isNotEmpty) ...[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.warning_amber,
                                      size: 20,
                                      color: Colors.orange.shade700,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Issues/Delays',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            booking.issuesEncountered!,
                                            style: const TextStyle(fontSize: 15),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Completion Notes
                              if (booking.completionNotes != null && booking.completionNotes!.isNotEmpty) ...[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.note_outlined,
                                      size: 20,
                                      color: Colors.deepOrange.shade600,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Additional Notes',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            booking.completionNotes!,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],

                              // Show message if no completion details
                              if ((booking.workCompleted == null || booking.workCompleted!.isEmpty) &&
                                  (booking.issuesEncountered == null || booking.issuesEncountered!.isEmpty) &&
                                  (booking.completionNotes == null || booking.completionNotes!.isEmpty)) ...[
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Text(
                                      'No completion details provided',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],

                    // Client Notes
                    if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.note,
                                    color: Colors.teal.shade600,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'YOUR NOTES',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              Text(
                                booking.notes!,
                                style: const TextStyle(fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
