class ServiceInfo {
  final String id;
  final String name;
  final String? description;
  final String? category;
  final int providerCount;
  final DateTime createdAt;

  ServiceInfo({
    required this.id,
    required this.name,
    this.description,
    this.category,
    required this.providerCount,
    required this.createdAt,
  });

  factory ServiceInfo.fromJson(Map<String, dynamic> json) {
    return ServiceInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      category: json['category'] as String?,
      providerCount: json['provider_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
