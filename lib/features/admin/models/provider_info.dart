class ProviderInfo {
  final String id;
  final String userId;
  final String? bio;
  final bool isVerified;
  final bool isAvailable;
  final double hourlyRate;
  final DateTime createdAt;
  final String? ownerName;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? documentsStatus;
  final String? idFrontUrl;
  final String? idBackUrl;
  final String? headshotUrl;
  final List<String>? servicePhotosUrls;

  ProviderInfo({
    required this.id,
    required this.userId,
    this.bio,
    required this.isVerified,
    required this.isAvailable,
    required this.hourlyRate,
    required this.createdAt,
    this.ownerName,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.documentsStatus,
    this.idFrontUrl,
    this.idBackUrl,
    this.headshotUrl,
    this.servicePhotosUrls,
  });

  String get businessName => ownerName ?? 'Unknown Provider';

  factory ProviderInfo.fromJson(Map<String, dynamic> json) {
    // Handle both old structure (querying from provider_profiles) 
    // and new structure (querying from profiles)
    final providerProfiles = json['provider_profiles'];
    final profiles = json['profiles'] as Map<String, dynamic>?;
    
    // If provider_profiles is a list, take the first element
    final providerProfile = providerProfiles is List 
        ? (providerProfiles.isNotEmpty ? providerProfiles[0] as Map<String, dynamic>? : null)
        : providerProfiles as Map<String, dynamic>?;
    
    return ProviderInfo(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? json['id'] as String,
      bio: providerProfile?['bio'] as String? ?? json['bio'] as String?,
      isVerified: providerProfile?['is_verified'] as bool? ?? json['is_verified'] as bool? ?? false,
      isAvailable: providerProfile?['is_available'] as bool? ?? json['is_available'] as bool? ?? true,
      hourlyRate: (providerProfile?['hourly_rate'] as num?)?.toDouble() ?? (json['hourly_rate'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['created_at'] as String),
      // For the current query structure (from profiles table), fields are at root level
      // For old structure (from provider_profiles), they might be in 'profiles' sub-object
      ownerName: json['full_name'] as String? ?? profiles?['full_name'] as String?,
      firstName: json['first_name'] as String? ?? profiles?['first_name'] as String?,
      lastName: json['last_name'] as String? ?? profiles?['last_name'] as String?,
      email: json['email'] as String? ?? profiles?['email'] as String?,
      phone: json['phone'] as String? ?? profiles?['phone'] as String?,
      documentsStatus: providerProfile?['documents_status'] as String?,
      idFrontUrl: providerProfile?['id_front_url'] as String?,
      idBackUrl: providerProfile?['id_back_url'] as String?,
      headshotUrl: providerProfile?['headshot_url'] as String?,
      servicePhotosUrls: (providerProfile?['service_photos_urls'] as List?)?.cast<String>(),
    );
  }
}
