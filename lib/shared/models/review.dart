class Review {
  final String id;
  final String bookingId;
  final String clientId;
  final String providerId;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.bookingId,
    required this.clientId,
    required this.providerId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['review_id'] ?? json['id'] as String,
      bookingId: json['review_booking_id'] ?? json['booking_id'] as String,
      clientId: json['review_client_id'] ?? json['client_id'] as String,
      providerId: json['review_provider_id'] ?? json['provider_id'] as String,
      rating: json['review_rating'] ?? json['rating'] as int,
      comment: json['review_comment'] ?? json['comment'] as String?,
      createdAt: DateTime.parse(json['review_created_at'] ?? json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'client_id': clientId,
      'provider_id': providerId,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
