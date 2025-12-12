import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/admin_service.dart';
import '../models/analytics_data.dart';
import 'admin_dashboard_screen.dart';

// Analytics Data Provider
final analyticsDataProvider = FutureProvider<AnalyticsData>((ref) async {
  final adminService = AdminService();
  return await adminService.getAnalyticsData();
});

// Analytics View Widget
class AnalyticsView extends ConsumerWidget {
  const AnalyticsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);
    final analyticsAsync = ref.watch(analyticsDataProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI Cards Row
          statsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
            data: (stats) => Row(
              children: [
                Expanded(
                  child: KPICard(
                    title: 'Total Revenue',
                    value: 'N\$${stats.totalRevenue.toStringAsFixed(2)}',
                    change: '+22%',
                    isPositive: true,
                    icon: Icons.trending_up,
                    color: const Color(0xFF26A69A),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: KPICard(
                    title: 'Avg. Booking Value',
                    value: 'N\$${stats.totalBookings > 0 ? (stats.totalRevenue / stats.totalBookings).toStringAsFixed(2) : '0.00'}',
                    change: '+8%',
                    isPositive: true,
                    icon: Icons.attach_money,
                    color: const Color(0xFF5C6BC0),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: KPICard(
                    title: 'Completion Rate',
                    value: '${stats.totalBookings > 0 ? ((stats.totalBookings - stats.pendingBookings) / stats.totalBookings * 100).toStringAsFixed(1) : '0.0'}%',
                    change: '+5%',
                    isPositive: true,
                    icon: Icons.task_alt,
                    color: const Color(0xFF66BB6A),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: KPICard(
                    title: 'Active Users',
                    value: stats.totalUsers.toString(),
                    change: '+12%',
                    isPositive: true,
                    icon: Icons.people,
                    color: const Color(0xFF7E57C2),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Charts Section
          analyticsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => Center(child: Text('Error: $error')),
            data: (analytics) => Column(
              children: [
                // Revenue & Bookings Trend
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: ChartCard(
                        title: 'Revenue Trend (Last 7 Days)',
                        child: RevenueTrendChart(data: analytics.revenueTrend),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ChartCard(
                        title: 'Bookings by Status',
                        child: BookingsStatusChart(data: analytics.bookingsByStatus),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Service Popularity & Provider Growth
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ChartCard(
                        title: 'Top Services',
                        child: TopServicesChart(data: analytics.topServices),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ChartCard(
                        title: 'Provider Growth',
                        child: ProviderGrowthChart(data: analytics.providerGrowth),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// KPI Card Widget
class KPICard extends StatelessWidget {
  final String title;
  final String value;
  final String change;
  final bool isPositive;
  final IconData icon;
  final Color color;

  const KPICard({
    super.key,
    required this.title,
    required this.value,
    required this.change,
    required this.isPositive,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPositive
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isPositive ? Icons.trending_up : Icons.trending_down,
                        color: isPositive ? Colors.green : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        change,
                        style: TextStyle(
                          color: isPositive ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Chart Card Wrapper
class ChartCard extends StatelessWidget {
  final String title;
  final Widget child;

  const ChartCard({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 300,
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

// Revenue Trend Line Chart
class RevenueTrendChart extends StatelessWidget {
  final List<DailyRevenue> data;

  const RevenueTrendChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: data.map((e) => e.revenue).reduce((a, b) => a > b ? a : b) / 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < data.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('MMM dd').format(data[value.toInt()].date),
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                return Text(
                  'N\$${value.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: data.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.revenue);
            }).toList(),
            isCurved: true,
            color: const Color(0xFF26A69A),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF26A69A).withOpacity(0.2),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final date = data[spot.x.toInt()].date;
                final revenue = spot.y;
                final bookings = data[spot.x.toInt()].bookings;
                return LineTooltipItem(
                  '${DateFormat('MMM dd').format(date)}\n',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  children: [
                    TextSpan(
                      text: 'Revenue: N\$${revenue.toStringAsFixed(2)}\n',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                    ),
                    TextSpan(
                      text: 'Bookings: $bookings',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}

// Bookings Status Pie Chart
class BookingsStatusChart extends StatelessWidget {
  final Map<String, int> data;

  const BookingsStatusChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final total = data.values.fold(0, (sum, count) => sum + count);
    final colors = {
      'pending': Colors.orange,
      'accepted': Colors.blue,
      'in_progress': Colors.purple,
      'completed': Colors.green,
      'cancelled': Colors.red,
    };

    return Column(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: data.entries.map((entry) {
                final percentage = (entry.value / total * 100);
                return PieChartSectionData(
                  color: colors[entry.key] ?? Colors.grey,
                  value: entry.value.toDouble(),
                  title: '${percentage.toStringAsFixed(1)}%',
                  radius: 100,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
              sectionsSpace: 2,
              centerSpaceRadius: 0,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: data.entries.map((entry) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colors[entry.key] ?? Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${entry.key}: ${entry.value}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

// Top Services Bar Chart
class TopServicesChart extends StatelessWidget {
  final List<ServicePopularity> data;

  const TopServicesChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final maxBookings = data.map((e) => e.bookings).reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxBookings.toDouble() * 1.2,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final service = data[groupIndex];
              return BarTooltipItem(
                '${service.name}\n',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                children: [
                  TextSpan(
                    text: 'Bookings: ${service.bookings}\n',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                  ),
                  TextSpan(
                    text: 'Revenue: N\$${service.revenue.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < data.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      data[value.toInt()].name.length > 10
                          ? '${data[value.toInt()].name.substring(0, 10)}...'
                          : data[value.toInt()].name,
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxBookings / 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
            );
          },
        ),
        barGroups: data.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.bookings.toDouble(),
                color: const Color(0xFF5C6BC0),
                width: 20,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// Provider Growth Chart
class ProviderGrowthChart extends StatelessWidget {
  final List<MonthlyGrowth> data;

  const ProviderGrowthChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final maxValue = data.map((e) => e.providers > e.users ? e.providers : e.users).reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValue.toDouble() * 1.2,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final month = data[groupIndex];
              final isProviders = rodIndex == 0;
              return BarTooltipItem(
                '${month.month}\n',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                children: [
                  TextSpan(
                    text: isProviders
                        ? 'Providers: ${month.providers}'
                        : 'Users: ${month.users}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < data.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      data[value.toInt()].month,
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxValue / 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
            );
          },
        ),
        barGroups: data.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.providers.toDouble(),
                color: const Color(0xFF7E57C2),
                width: 12,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
              BarChartRodData(
                toY: entry.value.users.toDouble(),
                color: const Color(0xFF26A69A),
                width: 12,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
