class ProviderProfile {
  final String id;
  final String bio;
  final List<String> skills;
  final double hourlyRate;
  final bool isVerified;
  final bool isAvailable;
  final double averageRating;
  final int totalReviews;
  final int completedJobs;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProviderProfile({
    required this.id,
    required this.bio,
    required this.skills,
    required this.hourlyRate,
    required this.isVerified,
    required this.isAvailable,
    required this.averageRating,
    required this.totalReviews,
    required this.completedJobs,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProviderProfile.fromJson(Map<String, dynamic> json) {
    return ProviderProfile(
      id: json['id'] as String,
      bio: json['bio'] as String,
      skills: (json['skills'] as List<dynamic>).cast<String>(),
      hourlyRate: (json['hourly_rate'] as num).toDouble(),
      isVerified: json['is_verified'] as bool? ?? false,
      isAvailable: json['is_available'] as bool? ?? true,
      averageRating: (json['rating_average'] as num?)?.toDouble() ?? (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: json['total_reviews'] as int? ?? 0,
      completedJobs: json['total_jobs'] as int? ?? (json['completed_jobs'] as int? ?? 0),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bio': bio,
      'skills': skills,
      'hourly_rate': hourlyRate,
      'is_verified': isVerified,
      'is_available': isAvailable,
      'average_rating': averageRating,
      'total_reviews': totalReviews,
      'completed_jobs': completedJobs,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
