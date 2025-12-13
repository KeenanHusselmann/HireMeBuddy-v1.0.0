import 'package:supabase_flutter/supabase_flutter.dart';

class EarningsData {
  final double todayEarnings;
  final double weekEarnings;
  final double monthEarnings;
  final double totalEarnings;
  final int todayBookings;
  final int weekBookings;
  final int monthBookings;
  final int totalBookings;
  final double averageBookingValue;
  final Map<String, double> dailyEarningsChart; // Last 7 days
  final Map<String, double> monthlyEarningsChart; // Last 6 months

  EarningsData({
    required this.todayEarnings,
    required this.weekEarnings,
    required this.monthEarnings,
    required this.totalEarnings,
    required this.todayBookings,
    required this.weekBookings,
    required this.monthBookings,
    required this.totalBookings,
    required this.averageBookingValue,
    required this.dailyEarningsChart,
    required this.monthlyEarningsChart,
  });
}

class EarningsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<EarningsData> getEarnings(String providerId) async {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final endOfToday = startOfToday.add(const Duration(days: 1));
    final startOfWeek = startOfToday.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1);

    // Fetch all completed bookings for this provider
    final response = await _supabase
        .from('bookings')
        .select('total_price, booking_date')
        .eq('provider_id', providerId)
        .eq('status', 'completed');

    final bookings = response as List;

    // Calculate earnings
    double todayEarnings = 0;
    double weekEarnings = 0;
    double monthEarnings = 0;
    double totalEarnings = 0;
    int todayBookings = 0;
    int weekBookings = 0;
    int monthBookings = 0;
    int totalBookings = bookings.length;

    Map<String, double> dailyEarnings = {};
    Map<String, double> monthlyEarnings = {};

    for (var booking in bookings) {
      final price = (booking['total_price'] as num?)?.toDouble() ?? 0.0;
      final bookingDate = DateTime.parse(booking['booking_date'] as String);

      totalEarnings += price;

      // Today's earnings - check if booking is on today
      if (bookingDate.isAfter(startOfToday.subtract(const Duration(seconds: 1))) &&
          bookingDate.isBefore(endOfToday)) {
        todayEarnings += price;
        todayBookings++;
      }

      // This week's earnings - check if booking is within this week
      if (bookingDate.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
          bookingDate.isBefore(endOfWeek)) {
        weekEarnings += price;
        weekBookings++;
      }

      // This month's earnings - check if booking is within this month
      if (bookingDate.isAfter(startOfMonth.subtract(const Duration(seconds: 1))) &&
          bookingDate.isBefore(endOfMonth)) {
        monthEarnings += price;
        monthBookings++;
      }

      // Daily earnings chart (last 7 days)
      final dayKey = _formatDate(bookingDate);
      dailyEarnings[dayKey] = (dailyEarnings[dayKey] ?? 0) + price;

      // Monthly earnings chart (last 6 months)
      final monthKey = _formatMonth(bookingDate);
      monthlyEarnings[monthKey] = (monthlyEarnings[monthKey] ?? 0) + price;
    }

    // Fill in missing days for the last 7 days
    Map<String, double> last7DaysEarnings = {};
    for (int i = 6; i >= 0; i--) {
      final date = startOfToday.subtract(Duration(days: i));
      final key = _formatDate(date);
      last7DaysEarnings[key] = dailyEarnings[key] ?? 0.0;
    }

    // Fill in missing months for the last 6 months
    Map<String, double> last6MonthsEarnings = {};
    for (int i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final key = _formatMonth(date);
      last6MonthsEarnings[key] = monthlyEarnings[key] ?? 0.0;
    }

    final averageBookingValue = totalBookings > 0 ? totalEarnings / totalBookings : 0.0;

    return EarningsData(
      todayEarnings: todayEarnings,
      weekEarnings: weekEarnings,
      monthEarnings: monthEarnings,
      totalEarnings: totalEarnings,
      todayBookings: todayBookings,
      weekBookings: weekBookings,
      monthBookings: monthBookings,
      totalBookings: totalBookings,
      averageBookingValue: averageBookingValue,
      dailyEarningsChart: last7DaysEarnings,
      monthlyEarningsChart: last6MonthsEarnings,
    );
  }

  Stream<EarningsData> getEarningsStream(String providerId) {
    return Stream.periodic(const Duration(seconds: 5))
        .asyncMap((_) => getEarnings(providerId))
        .handleError((error) {
      print('Error fetching earnings: $error');
      return EarningsData(
        todayEarnings: 0,
        weekEarnings: 0,
        monthEarnings: 0,
        totalEarnings: 0,
        todayBookings: 0,
        weekBookings: 0,
        monthBookings: 0,
        totalBookings: 0,
        averageBookingValue: 0,
        dailyEarningsChart: {},
        monthlyEarningsChart: {},
      );
    });
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }

  String _formatMonth(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[date.month - 1];
  }

  // Calculate growth percentages
  Future<Map<String, double>> getGrowthPercentages(String providerId) async {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfYesterday = startOfToday.subtract(const Duration(days: 1));
    final startOfThisWeek = startOfToday.subtract(Duration(days: now.weekday - 1));
    final startOfLastWeek = startOfThisWeek.subtract(const Duration(days: 7));
    final startOfThisMonth = DateTime(now.year, now.month, 1);
    final startOfLastMonth = DateTime(now.year, now.month - 1, 1);

    final response = await _supabase
        .from('bookings')
        .select('total_price, booking_date')
        .eq('provider_id', providerId)
        .eq('status', 'completed');

    final bookings = response as List;

    double todayEarnings = 0;
    double yesterdayEarnings = 0;
    double thisWeekEarnings = 0;
    double lastWeekEarnings = 0;
    double thisMonthEarnings = 0;
    double lastMonthEarnings = 0;

    for (var booking in bookings) {
      final price = (booking['total_price'] as num?)?.toDouble() ?? 0.0;
      final bookingDate = DateTime.parse(booking['booking_date'] as String);

      // Today vs Yesterday
      if (bookingDate.isAfter(startOfToday.subtract(const Duration(seconds: 1)))) {
        todayEarnings += price;
      } else if (bookingDate.isAfter(startOfYesterday.subtract(const Duration(seconds: 1))) &&
          bookingDate.isBefore(startOfToday)) {
        yesterdayEarnings += price;
      }

      // This week vs Last week
      if (bookingDate.isAfter(startOfThisWeek.subtract(const Duration(seconds: 1)))) {
        thisWeekEarnings += price;
      } else if (bookingDate.isAfter(startOfLastWeek.subtract(const Duration(seconds: 1))) &&
          bookingDate.isBefore(startOfThisWeek)) {
        lastWeekEarnings += price;
      }

      // This month vs Last month
      if (bookingDate.isAfter(startOfThisMonth.subtract(const Duration(seconds: 1)))) {
        thisMonthEarnings += price;
      } else if (bookingDate.isAfter(startOfLastMonth.subtract(const Duration(seconds: 1))) &&
          bookingDate.isBefore(startOfThisMonth)) {
        lastMonthEarnings += price;
      }
    }

    double dailyGrowth = yesterdayEarnings > 0 
        ? ((todayEarnings - yesterdayEarnings) / yesterdayEarnings) * 100 
        : 0;
    double weeklyGrowth = lastWeekEarnings > 0 
        ? ((thisWeekEarnings - lastWeekEarnings) / lastWeekEarnings) * 100 
        : 0;
    double monthlyGrowth = lastMonthEarnings > 0 
        ? ((thisMonthEarnings - lastMonthEarnings) / lastMonthEarnings) * 100 
        : 0;

    return {
      'daily': dailyGrowth,
      'weekly': weeklyGrowth,
      'monthly': monthlyGrowth,
    };
  }
}
