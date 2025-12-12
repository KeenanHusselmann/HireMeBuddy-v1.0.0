class AnalyticsData {
  final List<DailyRevenue> revenueTrend;
  final Map<String, int> bookingsByStatus;
  final List<ServicePopularity> topServices;
  final List<MonthlyGrowth> providerGrowth;

  AnalyticsData({
    required this.revenueTrend,
    required this.bookingsByStatus,
    required this.topServices,
    required this.providerGrowth,
  });
}

class DailyRevenue {
  final DateTime date;
  final double revenue;
  final int bookings;

  DailyRevenue({
    required this.date,
    required this.revenue,
    required this.bookings,
  });
}

class ServicePopularity {
  final String name;
  final int bookings;
  final double revenue;

  ServicePopularity({
    required this.name,
    required this.bookings,
    required this.revenue,
  });
}

class MonthlyGrowth {
  final String month;
  final int providers;
  final int users;

  MonthlyGrowth({
    required this.month,
    required this.providers,
    required this.users,
  });
}
