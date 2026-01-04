import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

// Model for waiting list entry
class WaitingListEntry {
  final String id;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final String userType;
  final String? serviceCategory;
  final String? location;
  final String? message;
  final DateTime createdAt;
  final bool subscribedToUpdates;
  final String status;

  WaitingListEntry({
    required this.id,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    required this.userType,
    this.serviceCategory,
    this.location,
    this.message,
    required this.createdAt,
    required this.subscribedToUpdates,
    required this.status,
  });

  factory WaitingListEntry.fromJson(Map<String, dynamic> json) {
    return WaitingListEntry(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'],
      phoneNumber: json['phone_number'],
      userType: json['user_type'],
      serviceCategory: json['service_category'],
      location: json['location'],
      message: json['message'],
      createdAt: DateTime.parse(json['created_at']),
      subscribedToUpdates: json['subscribed_to_updates'] ?? true,
      status: json['status'] ?? 'pending',
    );
  }
}

// Provider for waiting list data
final waitingListProvider = StreamProvider.autoDispose<List<WaitingListEntry>>((ref) async* {
  final supabase = Supabase.instance.client;
  
  await for (final data in supabase
      .from('waiting_list')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)) {
    yield data.map((json) => WaitingListEntry.fromJson(json)).toList();
  }
});

class WaitingListScreen extends ConsumerStatefulWidget {
  const WaitingListScreen({super.key});

  @override
  ConsumerState<WaitingListScreen> createState() => _WaitingListScreenState();
}

class _WaitingListScreenState extends ConsumerState<WaitingListScreen> {
  String _filterType = 'all';
  String _filterStatus = 'all';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final waitingListAsync = ref.watch(waitingListProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.list_alt, size: 32, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Landing Page Waiting List',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Manage sign-ups from hiremebuddy.app',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Stats Cards
          waitingListAsync.when(
            data: (entries) => _buildStatsCards(entries),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Filters
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<String>(
                    value: _filterType,
                    decoration: const InputDecoration(
                      labelText: 'User Type',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Types')),
                      DropdownMenuItem(value: 'provider', child: Text('Providers')),
                      DropdownMenuItem(value: 'client', child: Text('Clients')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _filterType = value!;
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<String>(
                    value: _filterStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Status')),
                      DropdownMenuItem(value: 'pending', child: Text('Pending')),
                      DropdownMenuItem(value: 'contacted', child: Text('Contacted')),
                      DropdownMenuItem(value: 'converted', child: Text('Converted')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _filterStatus = value!;
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: 300,
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Search by name or email',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // Data Table
          Expanded(
            child: waitingListAsync.when(
              data: (entries) {
                final filtered = _filterEntries(entries);
                return _buildDataTable(filtered);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading waiting list',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(List<WaitingListEntry> entries) {
    final totalCount = entries.length;
    final providerCount = entries.where((e) => e.userType == 'provider').length;
    final clientCount = entries.where((e) => e.userType == 'client').length;
    final todayCount = entries.where((e) {
      final today = DateTime.now();
      return e.createdAt.year == today.year &&
          e.createdAt.month == today.month &&
          e.createdAt.day == today.day;
    }).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildStatCard('Total Signups', totalCount.toString(), Icons.people, Colors.teal),
          const SizedBox(width: 12),
          _buildStatCard('Providers', providerCount.toString(), Icons.business_center, Colors.blue),
          const SizedBox(width: 12),
          _buildStatCard('Clients', clientCount.toString(), Icons.person, Colors.green),
          const SizedBox(width: 12),
          _buildStatCard('Today', todayCount.toString(), Icons.today, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 24, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<WaitingListEntry> _filterEntries(List<WaitingListEntry> entries) {
    return entries.where((entry) {
      // Type filter
      if (_filterType != 'all' && entry.userType != _filterType) {
        return false;
      }

      // Status filter
      if (_filterStatus != 'all' && entry.status != _filterStatus) {
        return false;
      }

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final matchesName = entry.fullName.toLowerCase().contains(_searchQuery);
        final matchesEmail = entry.email.toLowerCase().contains(_searchQuery);
        if (!matchesName && !matchesEmail) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Widget _buildDataTable(List<WaitingListEntry> entries) {
    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No entries found',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Waiting list is empty or no results match your filters',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 24,
          headingRowColor: WidgetStateProperty.all(Colors.grey[50]),
          columns: const [
            DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Phone', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Service/Location', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: entries.map((entry) => _buildDataRow(entry)).toList(),
        ),
      ),
    );
  }

  DataRow _buildDataRow(WaitingListEntry entry) {
    return DataRow(
      cells: [
        DataCell(
          Text(entry.fullName, style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
        DataCell(Text(entry.email)),
        DataCell(Text(entry.phoneNumber ?? '-')),
        DataCell(_buildTypeBadge(entry.userType)),
        DataCell(Text(entry.serviceCategory ?? entry.location ?? '-')),
        DataCell(_buildStatusBadge(entry.status)),
        DataCell(Text(DateFormat('MMM d, y').format(entry.createdAt))),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (entry.status != 'contacted')
                IconButton(
                  icon: const Icon(Icons.phone, size: 18),
                  tooltip: 'Mark as Contacted',
                  onPressed: () => _updateStatus(entry.id, 'contacted'),
                  color: Colors.blue,
                ),
              if (entry.status != 'converted')
                IconButton(
                  icon: const Icon(Icons.check_circle, size: 18),
                  tooltip: 'Mark as Converted',
                  onPressed: () => _updateStatus(entry.id, 'converted'),
                  color: Colors.green,
                ),
              IconButton(
                icon: const Icon(Icons.info, size: 18),
                tooltip: 'View Details',
                onPressed: () => _showDetailsDialog(entry),
                color: Colors.grey[600],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypeBadge(String type) {
    final color = type == 'provider' ? Colors.blue : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        type.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'contacted':
        color = Colors.blue;
        break;
      case 'converted':
        color = Colors.green;
        break;
      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _updateStatus(String id, String newStatus) async {
    try {
      await Supabase.instance.client
          .from('waiting_list')
          .update({'status': newStatus})
          .eq('id', id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to $newStatus'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDetailsDialog(WaitingListEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(entry.fullName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Email', entry.email),
              _buildDetailRow('Phone', entry.phoneNumber ?? 'Not provided'),
              _buildDetailRow('Type', entry.userType),
              if (entry.serviceCategory != null)
                _buildDetailRow('Service Category', entry.serviceCategory!),
              if (entry.location != null)
                _buildDetailRow('Location', entry.location!),
              if (entry.message != null && entry.message!.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Message:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(entry.message!),
              ],
              const SizedBox(height: 12),
              _buildDetailRow('Subscribed', entry.subscribedToUpdates ? 'Yes' : 'No'),
              _buildDetailRow('Status', entry.status),
              _buildDetailRow('Signed Up', DateFormat('MMM d, y - h:mm a').format(entry.createdAt)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
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
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
