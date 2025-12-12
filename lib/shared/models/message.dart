class Message {
  final String id;
  final String? bookingId;
  final String? conversationId;
  final String senderId;
  final String receiverId;
  final String content;
  final bool isRead;
  final DateTime createdAt;

  Message({
    required this.id,
    this.bookingId,
    this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.isRead,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String?,
      conversationId: json['conversation_id'] as String?,
      senderId: json['sender_id'] as String,
      receiverId: json['receiver_id'] as String,
      content: json['content'] as String? ?? json['message'] as String? ?? '',
      isRead: (json['read'] as bool?) ?? (json['is_read'] as bool?) ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (bookingId != null) 'booking_id': bookingId,
      if (conversationId != null) 'conversation_id': conversationId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
      'read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
