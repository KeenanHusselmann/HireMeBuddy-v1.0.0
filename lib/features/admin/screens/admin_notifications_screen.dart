import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'provider_documents_review_screen.dart';

// Provider for admin notifications stream
final adminNotificationsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final supabase = Supabase.instance.client;
  
  return supabase
      .from('admin_notifications')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false);
});

// Provider for unread count
final adminUnreadNotificationsCountProvider = StreamProvider.autoDispose<int>((ref) async* {
  final supabase = Supabase.instance.client;
  
  await for (final notifications in supabase
      .from('admin_notifications')
      .stream(primaryKey: ['id'])) {
    final unreadCount = notifications.where((n) => n['is_read'] == false).length;
    yield unreadCount;
  }
});

class AdminNotificationsScreen extends ConsumerWidget {
  const AdminNotificationsScreen({super.key});

  Future<void> _markAsRead(String notificationId) async {
    try {
      await Supabase.instance.client
          .from('admin_notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await Supabase.instance.client
          .from('admin_notifications')
          .update({'is_read': true})
          .eq('is_read', false);
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await Supabase.instance.client
          .from('admin_notifications')
          .delete()
          .eq('id', notificationId);
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'service_suggestion':
        return Icons.lightbulb_outline;
      case 'new_provider':
        return Icons.person_add;
      case 'new_booking':
        return Icons.calendar_today;
      case 'system':
        return Icons.info_outline;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'service_suggestion':
        return Colors.orange;
      case 'new_provider':
      case 'documents_pending':
        return Colors.blue;
      case 'new_booking':
        return Colors.green;
      case 'system':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  void _handleNotificationTap(BuildContext context, Map<String, dynamic> notification) {
    final type = notification['type'] as String;
    final metadata = notification['metadata'] as Map<String, dynamic>?;

    switch (type) {
      case 'new_provider':
      case 'documents_pending':
        // Navigate to provider documents review
        if (metadata != null && metadata['provider_id'] != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProviderDocumentsReviewScreen(
                providerId: metadata['provider_id'] as String,
              ),
            ),
          );
        }
        break;
      case 'service_suggestion':
        // Could navigate to services management
        break;
      case 'new_booking':
        // Could navigate to bookings management
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(adminNotificationsProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color(0xFF2C3E50),
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: _markAllAsRead,
            icon: const Icon(Icons.done_all, color: Colors.white),
            label: const Text(
              'Mark All Read',
              style: TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
            ],
          ),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final isRead = notification['is_read'] as bool;
              final type = notification['type'] as String;
              final title = notification['title'] as String;
              final message = notification['message'] as String;
              final createdAt = DateTime.parse(notification['created_at'] as String);
              final notificationId = notification['id'] as String;

              return Dismissible(
                key: Key(notificationId),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) {
                  _deleteNotification(notificationId);
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: isRead ? 0 : 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isRead ? Colors.transparent : _getNotificationColor(type).withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  color: isRead ? Colors.white : _getNotificationColor(type).withOpacity(0.05),
                  child: InkWell(
                    onTap: () {
                      if (!isRead) {
                        _markAsRead(notificationId);
                      }
                      // Handle notification tap based on type
                      _handleNotificationTap(context, notification);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _getNotificationColor(type).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getNotificationIcon(type),
                              color: _getNotificationColor(type),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (!isRead)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: _getNotificationColor(type),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  message,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 14,
                                      color: Colors.grey.shade500,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      timeago.format(createdAt),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
