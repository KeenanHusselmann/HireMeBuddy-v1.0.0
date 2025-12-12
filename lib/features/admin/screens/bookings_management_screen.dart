import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../services/admin_service.dart';
import '../providers/admin_settings_provider.dart';

final bookingsListProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final adminService = AdminService();
  return await adminService.getAllBookings();
});

class BookingsManagementScreen extends ConsumerWidget {
  const BookingsManagementScreen({super.key});

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(bookingsListProvider);

    return bookingsAsync.when(
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
              onPressed: () => ref.invalidate(bookingsListProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (bookings) {
        if (bookings.isEmpty) {
          return const Center(
            child: Text('No bookings found'),
          );
        }

        final isTableView = ref.watch(tableViewEnabledProvider);

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(bookingsListProvider),
          child: isTableView ? _buildTableView(bookings, context, ref) : _buildCardView(bookings, context, ref),
        );
      },
    );
  }

  Widget _buildTableView(List<Map<String, dynamic>> bookings, BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            const Color(0xFF2C3E50).withOpacity(0.1),
          ),
          columnSpacing: 20,
          columns: const [
            DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Client', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Provider', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Time', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: bookings.map((booking) {
            final status = booking['status'] as String;
            final statusColor = _getStatusColor(status);
            final clientInfo = booking['profiles'] as Map<String, dynamic>?;
            final providerInfo = booking['provider_profiles'] as Map<String, dynamic>?;

            return DataRow(
              cells: [
                DataCell(Text('#${booking['id'].toString().substring(0, 8)}')),
                DataCell(Text(clientInfo?['full_name'] ?? 'Unknown')),
                DataCell(Text(providerInfo?['business_name'] ?? 'Unknown')),
                DataCell(Text(DateFormat('MMM d, yyyy').format(DateTime.parse(booking['booking_date'])))),
                DataCell(Text(booking['booking_time'] ?? 'N/A')),
                DataCell(Text('N\$${(booking['total_price'] as num?)?.toStringAsFixed(2) ?? '0.00'}')),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility, size: 20),
                        onPressed: () {
                          _showBookingDetails(context, booking);
                        },
                        tooltip: 'View Details',
                      ),
                      if (status == 'pending')
                        IconButton(
                          icon: const Icon(Icons.check_circle, size: 20, color: Colors.green),
                          onPressed: () async {
                            await _updateBookingStatus(ref, booking['id'], 'confirmed');
                          },
                          tooltip: 'Confirm',
                        ),
                      if (status != 'cancelled' && status != 'completed')
                        IconButton(
                          icon: const Icon(Icons.cancel, size: 20, color: Colors.red),
                          onPressed: () async {
                            await _updateBookingStatus(ref, booking['id'], 'cancelled');
                          },
                          tooltip: 'Cancel',
                        ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCardView(List<Map<String, dynamic>> bookings, BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        final status = booking['status'] as String;
        final statusColor = _getStatusColor(status);
        final clientInfo = booking['profiles'] as Map<String, dynamic>?;
        final providerInfo = booking['provider_profiles'] as Map<String, dynamic>?;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'N\$${(booking['total_price'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(),
                if (clientInfo != null)
                  Text(
                    'Client: ${clientInfo['full_name'] ?? 'Unknown'}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                if (providerInfo != null)
                  Text(
                    'Provider: ${providerInfo['business_name'] ?? 'Unknown'}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                Text(
                  'Date: ${DateFormat('MMM d, yyyy').format(DateTime.parse(booking['booking_date']))}',
                ),
                Text('Time: ${booking['booking_time'] ?? 'N/A'}'),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showBookingDetails(context, booking),
                      icon: const Icon(Icons.visibility, size: 18),
                      label: const Text('View'),
                    ),
                    if (status == 'pending')
                      TextButton.icon(
                        onPressed: () async {
                          await _updateBookingStatus(ref, booking['id'], 'confirmed');
                        },
                        icon: const Icon(Icons.check_circle, size: 18),
                        label: const Text('Confirm'),
                        style: TextButton.styleFrom(foregroundColor: Colors.green),
                      ),
                    if (status != 'cancelled' && status != 'completed')
                      TextButton.icon(
                        onPressed: () async {
                          await _updateBookingStatus(ref, booking['id'], 'cancelled');
                        },
                        icon: const Icon(Icons.cancel, size: 18),
                        label: const Text('Cancel'),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showBookingDetails(BuildContext context, Map<String, dynamic> booking) {
    final clientInfo = booking['profiles'] as Map<String, dynamic>?;
    final providerInfo = booking['provider_profiles'] as Map<String, dynamic>?;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Booking Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Booking ID', '#${booking['id'].toString().substring(0, 8)}'),
              _buildDetailRow('Client', clientInfo?['full_name'] ?? 'Unknown'),
              _buildDetailRow('Provider', providerInfo?['business_name'] ?? 'Unknown'),
              _buildDetailRow('Date', DateFormat('MMM d, yyyy').format(DateTime.parse(booking['booking_date']))),
              _buildDetailRow('Time', booking['booking_time'] ?? 'N/A'),
              _buildDetailRow('Amount', 'N\$${(booking['total_price'] as num?)?.toStringAsFixed(2) ?? '0.00'}'),
              _buildDetailRow('Status', booking['status']),
              if (booking['special_requirements'] != null)
                _buildDetailRow('Requirements', booking['special_requirements']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Future<void> _updateBookingStatus(WidgetRef ref, String bookingId, String newStatus) async {
    final adminService = AdminService();
    try {
      await adminService.updateBookingStatus(bookingId, newStatus);
      ref.invalidate(bookingsListProvider);
    } catch (e) {
      // Handle error
      print('Error updating booking status: $e');
    }
  }
}
