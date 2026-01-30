import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'provider_chat_screen.dart';
import '../../../shared/services/message_service.dart';

class ConversationsScreen extends ConsumerStatefulWidget {
  const ConversationsScreen({super.key});

  @override
  ConsumerState<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends ConsumerState<ConversationsScreen> {
  final _messageService = MessageService();
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;
  bool _isProvider = false;
  String? _myProfileId;
  int _unreadCount = 0;

  // Helper to get theme color based on provider status
  Color get _themeColor => _isProvider ? Colors.deepOrange.shade600 : Colors.teal.shade600;
  Color get _themeColorLight => _isProvider ? Colors.deepOrange.shade100 : Colors.teal.shade100;
  Color get _themeColorDark => _isProvider ? Colors.deepOrange.shade700 : Colors.teal.shade700;
  Color get _themeColorBase => _isProvider ? Colors.deepOrange : Colors.teal;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Get my profile ID
      final myProfile = await Supabase.instance.client
          .from('profiles')
          .select('id, role')
          .eq('user_id', user.id)
          .single();
      
      _myProfileId = myProfile['id'] as String;
      _isProvider = myProfile['role'] == 'provider';

      // Get all conversations (unique contacts)
      final messagesResponse = await Supabase.instance.client
          .from('chat_messages')
          .select('''
            *,
            sender:sender_id(id, full_name, avatar_url, user_id),
            receiver:receiver_id(id, full_name, avatar_url, user_id)
          ''')
          .or('sender_id.eq.$_myProfileId,receiver_id.eq.$_myProfileId')
          .order('created_at', ascending: false);

      // Group by contact and get the latest message
      final Map<String, Map<String, dynamic>> conversationsMap = {};
      
      for (final message in (messagesResponse as List)) {
        final senderId = message['sender_id'] as String;
        final receiverId = message['receiver_id'] as String;
        final contactId = senderId == _myProfileId ? receiverId : senderId;
        
        if (!conversationsMap.containsKey(contactId)) {
          final contact = senderId == _myProfileId
              ? message['receiver'] as Map<String, dynamic>
              : message['sender'] as Map<String, dynamic>;
          
          // Count unread messages from this contact
          final unreadCount = await Supabase.instance.client
              .from('chat_messages')
              .select('id')
              .eq('sender_id', contactId)
              .eq('receiver_id', _myProfileId!)
              .eq('read', false)
              .count(CountOption.exact);
          
          conversationsMap[contactId] = {
            'contact': contact,
            'lastMessage': message['content'],
            'lastMessageTime': message['created_at'],
            'unreadCount': unreadCount.count,
          };
        }
      }

      // Get total unread count
      final totalUnread = await _messageService.getUnreadCount();

      setState(() {
        _conversations = conversationsMap.values.toList()
          ..sort((a, b) => DateTime.parse(b['lastMessageTime'] as String)
              .compareTo(DateTime.parse(a['lastMessageTime'] as String)));
        _unreadCount = totalUnread;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading conversations: $e')),
        );
      }
    }
  }

  String _formatTime(String timestamp) {
    final dateTime = DateTime.parse(timestamp);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat('EEE').format(dateTime);
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen until we know if user is provider (prevents color flash)
    if (_isLoading && _myProfileId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _themeColor,
        foregroundColor: Colors.white,
        title: const Text('Messages'),
        actions: [
          if (_unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading && _myProfileId != null
          ? Center(child: CircularProgressIndicator(color: _themeColorBase))
          : _conversations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.forum_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No conversations yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Messages from clients will appear here',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadConversations,
                  child: ListView.builder(
                    itemCount: _conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = _conversations[index];
                      final contact = conversation['contact'] as Map<String, dynamic>;
                      final contactName = contact['full_name'] as String? ?? 'Client';
                      final lastMessage = conversation['lastMessage'] as String;
                      final time = _formatTime(conversation['lastMessageTime'] as String);
                      final unreadCount = conversation['unreadCount'] as int;

                      return ListTile(
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: _themeColorLight,
                              backgroundImage: contact['avatar_url'] != null
                                  ? NetworkImage(contact['avatar_url'])
                                  : null,
                              child: contact['avatar_url'] == null
                                  ? Text(
                                      contactName.substring(0, 1).toUpperCase(),
                                      style: TextStyle(
                                        color: _themeColorDark,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    )
                                  : null,
                            ),
                            if (unreadCount > 0)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 20,
                                    minHeight: 20,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$unreadCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        title: Text(
                          contactName,
                          style: TextStyle(
                            fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                            color: unreadCount > 0 ? Colors.black87 : Colors.grey.shade600,
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              time,
                              style: TextStyle(
                                fontSize: 12,
                                color: unreadCount > 0 ? Colors.teal : Colors.grey.shade600,
                                fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProviderChatScreen(client: contact),
                            ),
                          );
                          // Reload conversations after returning from chat
                          _loadConversations();
                        },
                      );
                    },
                  ),
                ),
    );
  }
}

