class AdminStats {
  final int totalUsers;
  final int activeProviders;
  final int totalBookings;
  final double totalRevenue;
  final int pendingBookings;
  final int completedToday;

  AdminStats({
    required this.totalUsers,
    required this.activeProviders,
    required this.totalBookings,
    required this.totalRevenue,
    required this.pendingBookings,
    required this.completedToday,
  });

  // Calculate growth percentages (mock for now, you can add actual logic later)
  String get usersGrowth => '+12%';
  String get providersGrowth => '+8%';
  String get bookingsGrowth => '+15%';
  String get revenueGrowth => '+22%';
}
