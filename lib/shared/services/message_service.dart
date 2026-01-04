import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message.dart';
import '../../core/utils/logger.dart';
import 'fcm_trigger_service.dart';

class MessageService {
  final _supabase = Supabase.instance.client;
  final _logger = AppLogger();
  final _fcmTrigger = FcmTriggerService();

  // Send a message
  Future<Message> sendMessage({
    required String receiverId,
    required String content,
    String? conversationId,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get sender profile ID and name
      final senderProfile = await _supabase
          .from('profiles')
          .select('id, full_name')
          .eq('user_id', user.id)
          .single();
      
      final senderId = senderProfile['id'] as String;

      final messageData = {
        'sender_id': senderId,
        'receiver_id': receiverId,
        'content': content,
        'read': false, // Explicitly mark as unread
      };
      
      // Only add conversation_id if it's not null
      if (conversationId != null) {
        messageData['conversation_id'] = conversationId;
      }

      final response = await _supabase
          .from('chat_messages')
          .insert(messageData)
          .select()
          .single();

      _logger.info('Message sent successfully');
      
      // Trigger FCM notification to receiver
      final message = Message.fromJson(response);
      final senderName = senderProfile['full_name'] ?? 'Someone';
      
      _fcmTrigger.notifyNewMessage(
        recipientProfileId: receiverId,
        senderName: senderName,
        messageContent: content,
        messageId: message.id,
        conversationId: conversationId,
      );
      
      return message;
    } catch (e) {
      _logger.error('Error sending message', e);
      rethrow;
    }
  }

  // Get conversation between two users
  Future<List<Map<String, dynamic>>> getConversation(String otherUserId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get current user profile ID
      final myProfile = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', user.id)
          .single();
      
      final myProfileId = myProfile['id'] as String;

      // Get messages between the two users with sender/receiver details
      final response = await _supabase
          .from('chat_messages')
          .select('''
            *,
            sender:sender_id(id, full_name, avatar_url),
            receiver:receiver_id(id, full_name, avatar_url)
          ''')
          .or('sender_id.eq.$myProfileId,receiver_id.eq.$myProfileId')
          .or('sender_id.eq.$otherUserId,receiver_id.eq.$otherUserId')
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      _logger.error('Error fetching conversation', e);
      rethrow;
    }
  }

  // Mark messages as read
  Future<void> markAsRead(String senderId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get current user profile ID
      final myProfile = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', user.id)
          .single();
      
      final myProfileId = myProfile['id'] as String;

      await _supabase
          .from('chat_messages')
          .update({'read': true})
          .eq('receiver_id', myProfileId)
          .eq('sender_id', senderId);

      _logger.debug('Messages marked as read');
    } catch (e) {
      _logger.error('Error marking messages as read', e);
      rethrow;
    }
  }

  // Get unread message count
  Future<int> getUnreadCount() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return 0;

      final myProfile = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', user.id)
          .single();
      
      final myProfileId = myProfile['id'] as String;

      final response = await _supabase
          .from('chat_messages')
          .select('id')
          .eq('receiver_id', myProfileId)
          .eq('read', false)
          .count();

      return response.count;
    } catch (e) {
      _logger.error('Error getting unread count', e);
      return 0;
    }
  }

  // Subscribe to new messages
  RealtimeChannel subscribeToMessages(String profileId, Function(Map<String, dynamic>) onMessage) {
    _logger.debug('Subscribing to messages for profile: $profileId');
    
    final channel = _supabase
        .channel('chat_messages:$profileId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'receiver_id',
            value: profileId,
          ),
          callback: (payload) {
            _logger.debug('New message received: ${payload.newRecord}');
            onMessage(payload.newRecord);
          },
        )
        .subscribe((status, error) {
          _logger.debug('Messages channel status: $status');
          if (error != null) {
            _logger.error('Messages subscription error', error);
          }
        });

    return channel;
  }
}
