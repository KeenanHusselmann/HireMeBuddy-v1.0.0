class ProviderInfo {
  final String id;
  final String userId;
  final String? bio;
  final bool isVerified;
  final bool isAvailable;
  final double hourlyRate;
  final DateTime createdAt;
  final String? ownerName;
  final String? email;
  final String? phone;

  ProviderInfo({
    required this.id,
    required this.userId,
    this.bio,
    required this.isVerified,
    required this.isAvailable,
    required this.hourlyRate,
    required this.createdAt,
    this.ownerName,
    this.email,
    this.phone,
  });

  String get businessName => ownerName ?? 'Unknown Provider';

  factory ProviderInfo.fromJson(Map<String, dynamic> json) {
    final profiles = json['profiles'] as Map<String, dynamic>?;
    
    return ProviderInfo(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? json['id'] as String,
      bio: json['bio'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      isAvailable: json['is_available'] as bool? ?? true,
      hourlyRate: (json['hourly_rate'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['created_at'] as String),
      ownerName: profiles?['full_name'] as String?,
      email: profiles?['email'] as String?,
      phone: profiles?['phone'] as String?,
    );
  }
}
