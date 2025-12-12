class UserInfo {
  final String id;
  final String fullName;
  final String? email;
  final String? phone;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserInfo({
    required this.id,
    required this.fullName,
    this.email,
    this.phone,
    required this.createdAt,
    this.updatedAt,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? 'Unknown',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }
}
