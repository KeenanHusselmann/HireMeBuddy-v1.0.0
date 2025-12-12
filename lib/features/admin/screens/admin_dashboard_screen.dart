import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/admin_service.dart';
import '../models/admin_stats.dart';
import '../providers/admin_settings_provider.dart';
import 'users_management_screen.dart';
import 'providers_management_screen.dart';
import 'bookings_management_screen.dart';
import 'services_management_screen.dart';
import 'analytics_screen.dart';
import 'admin_notifications_screen.dart';

// Provider for admin unread notifications count
final adminUnreadNotificationsCountProvider = StreamProvider.autoDispose<int>((ref) async* {
  final supabase = Supabase.instance.client;
  
  await for (final notifications in supabase
      .from('admin_notifications')
      .stream(primaryKey: ['id'])) {
    final unreadCount = notifications.where((n) => n['is_read'] == false).length;
    yield unreadCount;
  }
});

// Provider for admin stats
final adminStatsProvider = FutureProvider<AdminStats>((ref) async {
  final adminService = AdminService();
  return await adminService.getDashboardStats();
});

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _selectedIndex = 0;

  final List<NavigationItem> _navigationItems = [
    NavigationItem(icon: Icons.dashboard, label: 'Dashboard', route: 'dashboard'),
    NavigationItem(icon: Icons.people, label: 'Users', route: 'users'),
    NavigationItem(icon: Icons.business_center, label: 'Providers', route: 'providers'),
    NavigationItem(icon: Icons.calendar_today, label: 'Bookings', route: 'bookings'),
    NavigationItem(icon: Icons.category, label: 'Services', route: 'services'),
    NavigationItem(icon: Icons.analytics, label: 'Analytics', route: 'analytics'),
    NavigationItem(icon: Icons.settings, label: 'Settings', route: 'settings'),
  ];

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _DashboardOverview();
      case 1:
        return const UsersManagementScreen();
      case 2:
        return const ProvidersManagementScreen();
      case 3:
        return const BookingsManagementScreen();
      case 4:
        return const ServicesManagementScreen();
      case 5:
        return AnalyticsView();
      case 6:
        return _SettingsView();
      default:
        return _DashboardOverview();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar Navigation
          NavigationRail(
            extended: MediaQuery.of(context).size.width > 1000,
            backgroundColor: const Color(0xFF2C3E50),
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.none,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  if (MediaQuery.of(context).size.width > 1000)
                    const Text(
                      'ADMIN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                ],
              ),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white70),
                    onPressed: () async {
                      // Clear login state
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove('admin_logged_in');
                      await prefs.remove('admin_email');
                      
                      if (context.mounted) {
                        context.go('/admin-login');
                      }
                    },
                    tooltip: 'Logout',
                  ),
                ),
              ),
            ),
            destinations: _navigationItems
                .map((item) => NavigationRailDestination(
                      icon: Icon(item.icon, color: Colors.white70),
                      selectedIcon: Icon(item.icon, color: Colors.white),
                      label: Text(
                        item.label,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ))
                .toList(),
          ),

          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Top App Bar
                Container(
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Text(
                          _navigationItems[_selectedIndex].label,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const Spacer(),
                        // Notifications Bell Icon with Badge
                        Consumer(
                          builder: (context, ref, child) {
                            final unreadCountAsync = ref.watch(adminUnreadNotificationsCountProvider);
                            return unreadCountAsync.when(
                              data: (count) => Badge(
                                isLabelVisible: count > 0,
                                label: Text('$count'),
                                backgroundColor: Colors.red,
                                child: IconButton(
                                  icon: const Icon(Icons.notifications),
                                  iconSize: 28,
                                  color: const Color(0xFF2C3E50),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const AdminNotificationsScreen(),
                                      ),
                                    );
                                  },
                                  tooltip: 'Notifications',
                                ),
                              ),
                              loading: () => IconButton(
                                icon: const Icon(Icons.notifications),
                                iconSize: 28,
                                color: const Color(0xFF2C3E50),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AdminNotificationsScreen(),
                                    ),
                                  );
                                },
                              ),
                              error: (_, __) => IconButton(
                                icon: const Icon(Icons.notifications),
                                iconSize: 28,
                                color: const Color(0xFF2C3E50),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AdminNotificationsScreen(),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ),

                // Content
                Expanded(
                  child: Container(
                    color: Colors.grey.shade50,
                    child: _buildContent(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final String label;
  final String route;

  NavigationItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}

// Dashboard Overview Widget
class _DashboardOverview extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(adminStatsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (stats) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Cards
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Total Users',
                    value: stats.totalUsers.toString(),
                    icon: Icons.people,
                    color: const Color(0xFF5C6BC0),
                    trend: stats.usersGrowth,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatCard(
                    title: 'Active Providers',
                    value: stats.activeProviders.toString(),
                    icon: Icons.business_center,
                    color: const Color(0xFF7E57C2),
                    trend: stats.providersGrowth,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatCard(
                    title: 'Total Bookings',
                    value: stats.totalBookings.toString(),
                    icon: Icons.calendar_today,
                    color: const Color(0xFF66BB6A),
                    trend: stats.bookingsGrowth,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatCard(
                    title: 'Revenue',
                    value: 'N\$${stats.totalRevenue.toStringAsFixed(2)}',
                    icon: Icons.attach_money,
                    color: const Color(0xFF26A69A),
                    trend: stats.revenueGrowth,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quick Actions Section
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'System Overview',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildOverviewRow(
                            'Total Users',
                            stats.totalUsers.toString(),
                            Icons.people,
                            const Color(0xFF5C6BC0),
                          ),
                          const Divider(),
                          _buildOverviewRow(
                            'Active Providers',
                            stats.activeProviders.toString(),
                            Icons.business_center,
                            const Color(0xFF7E57C2),
                          ),
                          const Divider(),
                          _buildOverviewRow(
                            'Pending Bookings',
                            stats.pendingBookings.toString(),
                            Icons.pending,
                            Colors.orange,
                          ),
                          const Divider(),
                          _buildOverviewRow(
                            'Completed Today',
                            stats.completedToday.toString(),
                            Icons.done,
                            const Color(0xFF66BB6A),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Quick Actions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _QuickActionButton(
                            icon: Icons.people,
                            label: 'View All Users',
                            color: const Color(0xFF2C3E50),
                            onTap: () {},
                          ),
                          const SizedBox(height: 8),
                          _QuickActionButton(
                            icon: Icons.business_center,
                            label: 'Manage Providers',
                            color: const Color(0xFF2C3E50),
                            onTap: () {},
                          ),
                          const SizedBox(height: 8),
                          _QuickActionButton(
                            icon: Icons.calendar_today,
                            label: 'View Bookings',
                            color: const Color(0xFF2C3E50),
                            onTap: () {},
                          ),
                          const SizedBox(height: 8),
                          _QuickActionButton(
                            icon: Icons.refresh,
                            label: 'Refresh Data',
                            color: const Color(0xFF2C3E50),
                            onTap: () => ref.invalidate(adminStatsProvider),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// Remove old _DashboardOverview and its helper method _buildRecentBookingItem

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String trend;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.trend,
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
                  child: Icon(icon, color: color, size: 28),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    trend,
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Placeholder widgets for other sections
class _SettingsView extends ConsumerStatefulWidget {
  @override
  ConsumerState<_SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<_SettingsView> {
  String _selectedTheme = 'light';
  int _itemsPerPage = 20;
  String _dateFormat = 'MMM dd, yyyy';
  bool _autoRefresh = false;
  int _refreshInterval = 30;
  bool _notifications = true;
  String _exportFormat = 'csv';
  bool _compactView = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settingsService = ref.read(adminSettingsServiceProvider);
    _selectedTheme = await settingsService.getThemeMode();
    _itemsPerPage = await settingsService.getItemsPerPage();
    _dateFormat = await settingsService.getDateFormat();
    _autoRefresh = await settingsService.getAutoRefreshEnabled();
    _refreshInterval = await settingsService.getRefreshInterval();
    _notifications = await settingsService.getNotificationsEnabled();
    _exportFormat = await settingsService.getExportFormat();
    _compactView = await settingsService.getCompactView();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isTableView = ref.watch(tableViewEnabledProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Reset Settings'),
                  content: const Text('Are you sure you want to reset all settings to defaults?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Reset', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              
              if (confirm == true && mounted) {
                final settingsService = ref.read(adminSettingsServiceProvider);
                await settingsService.resetToDefaults();
                await _loadSettings();
                ref.invalidate(tableViewEnabledProvider);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Settings reset to defaults'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.restore, size: 20),
            label: const Text('Reset to Defaults'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Display Preferences
          _buildSettingsCard(
            icon: Icons.view_module,
            title: 'Display Preferences',
            subtitle: 'Customize how data is displayed',
            children: [
              SwitchListTile(
                value: isTableView,
                onChanged: (value) {
                  ref.read(tableViewEnabledProvider.notifier).toggleTableView(value);
                  _showSuccessSnackbar(value ? 'Table View enabled' : 'Card View enabled');
                },
                title: const Text('Table View', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(isTableView ? 'Structured table format' : 'Card format'),
                secondary: _buildIconContainer(isTableView ? Icons.table_chart : Icons.view_agenda),
              ),
              const Divider(),
              SwitchListTile(
                value: _compactView,
                onChanged: (value) async {
                  setState(() => _compactView = value);
                  final settingsService = ref.read(adminSettingsServiceProvider);
                  await settingsService.setCompactView(value);
                  _showSuccessSnackbar(value ? 'Compact view enabled' : 'Comfortable view enabled');
                },
                title: const Text('Compact View', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(_compactView ? 'Reduced spacing and padding' : 'Comfortable spacing'),
                secondary: _buildIconContainer(Icons.view_compact),
              ),
              const Divider(),
              ListTile(
                leading: _buildIconContainer(Icons.format_list_numbered),
                title: const Text('Items per Page', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Currently: $_itemsPerPage items'),
                trailing: DropdownButton<int>(
                  value: _itemsPerPage,
                  items: [10, 20, 50, 100].map((count) {
                    return DropdownMenuItem(value: count, child: Text('$count'));
                  }).toList(),
                  onChanged: (value) async {
                    if (value != null) {
                      setState(() => _itemsPerPage = value);
                      final settingsService = ref.read(adminSettingsServiceProvider);
                      await settingsService.setItemsPerPage(value);
                      _showSuccessSnackbar('Items per page updated');
                    }
                  },
                ),
              ),
              const Divider(),
              ListTile(
                leading: _buildIconContainer(Icons.calendar_today),
                title: const Text('Date Format', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Currently: $_dateFormat'),
                trailing: DropdownButton<String>(
                  value: _dateFormat,
                  items: const [
                    DropdownMenuItem(value: 'MMM dd, yyyy', child: Text('Dec 11, 2025')),
                    DropdownMenuItem(value: 'dd/MM/yyyy', child: Text('11/12/2025')),
                    DropdownMenuItem(value: 'yyyy-MM-dd', child: Text('2025-12-11')),
                    DropdownMenuItem(value: 'EEEE, MMM dd', child: Text('Wednesday, Dec 11')),
                  ],
                  onChanged: (value) async {
                    if (value != null) {
                      setState(() => _dateFormat = value);
                      final settingsService = ref.read(adminSettingsServiceProvider);
                      await settingsService.setDateFormat(value);
                      _showSuccessSnackbar('Date format updated');
                    }
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Auto Refresh Settings
          _buildSettingsCard(
            icon: Icons.refresh,
            title: 'Auto Refresh',
            subtitle: 'Automatically refresh data at intervals',
            children: [
              SwitchListTile(
                value: _autoRefresh,
                onChanged: (value) async {
                  setState(() => _autoRefresh = value);
                  final settingsService = ref.read(adminSettingsServiceProvider);
                  await settingsService.setAutoRefreshEnabled(value);
                  _showSuccessSnackbar(value ? 'Auto-refresh enabled' : 'Auto-refresh disabled');
                },
                title: const Text('Enable Auto Refresh', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(_autoRefresh ? 'Data refreshes automatically' : 'Manual refresh only'),
                secondary: _buildIconContainer(Icons.autorenew),
              ),
              if (_autoRefresh) ...[
                const Divider(),
                ListTile(
                  leading: _buildIconContainer(Icons.timer),
                  title: const Text('Refresh Interval', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('Every $_refreshInterval seconds'),
                  trailing: DropdownButton<int>(
                    value: _refreshInterval,
                    items: [15, 30, 60, 120, 300].map((seconds) {
                      return DropdownMenuItem(
                        value: seconds,
                        child: Text('${seconds}s'),
                      );
                    }).toList(),
                    onChanged: (value) async {
                      if (value != null) {
                        setState(() => _refreshInterval = value);
                        final settingsService = ref.read(adminSettingsServiceProvider);
                        await settingsService.setRefreshInterval(value);
                        _showSuccessSnackbar('Refresh interval updated');
                      }
                    },
                  ),
                ),
              ],
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Appearance Settings
          _buildSettingsCard(
            icon: Icons.palette,
            title: 'Appearance',
            subtitle: 'Theme and visual preferences',
            children: [
              ListTile(
                leading: _buildIconContainer(Icons.brightness_6),
                title: const Text('Theme Mode', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(_getThemeLabel(_selectedTheme)),
                trailing: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'light', icon: Icon(Icons.light_mode, size: 18)),
                    ButtonSegment(value: 'dark', icon: Icon(Icons.dark_mode, size: 18)),
                    ButtonSegment(value: 'system', icon: Icon(Icons.settings_suggest, size: 18)),
                  ],
                  selected: {_selectedTheme},
                  onSelectionChanged: (Set<String> selected) async {
                    setState(() => _selectedTheme = selected.first);
                    final settingsService = ref.read(adminSettingsServiceProvider);
                    await settingsService.setThemeMode(selected.first);
                    _showSuccessSnackbar('Theme updated (restart may be required)');
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Notifications
          _buildSettingsCard(
            icon: Icons.notifications,
            title: 'Notifications',
            subtitle: 'Manage notification preferences',
            children: [
              SwitchListTile(
                value: _notifications,
                onChanged: (value) async {
                  setState(() => _notifications = value);
                  final settingsService = ref.read(adminSettingsServiceProvider);
                  await settingsService.setNotificationsEnabled(value);
                  _showSuccessSnackbar(value ? 'Notifications enabled' : 'Notifications disabled');
                },
                title: const Text('Enable Notifications', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(_notifications ? 'Receive alerts for important events' : 'No notifications'),
                secondary: _buildIconContainer(Icons.notifications_active),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Export Settings
          _buildSettingsCard(
            icon: Icons.file_download,
            title: 'Export Settings',
            subtitle: 'Default format for data exports',
            children: [
              ListTile(
                leading: _buildIconContainer(Icons.description),
                title: const Text('Export Format', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Default: ${_exportFormat.toUpperCase()}'),
                trailing: DropdownButton<String>(
                  value: _exportFormat,
                  items: const [
                    DropdownMenuItem(value: 'csv', child: Text('CSV')),
                    DropdownMenuItem(value: 'excel', child: Text('Excel')),
                    DropdownMenuItem(value: 'pdf', child: Text('PDF')),
                    DropdownMenuItem(value: 'json', child: Text('JSON')),
                  ],
                  onChanged: (value) async {
                    if (value != null) {
                      setState(() => _exportFormat = value);
                      final settingsService = ref.read(adminSettingsServiceProvider);
                      await settingsService.setExportFormat(value);
                      _showSuccessSnackbar('Export format updated');
                    }
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // About Section
          _buildSettingsCard(
            icon: Icons.info,
            title: 'About',
            subtitle: 'Application information',
            children: [
              _buildInfoRow('Version', '1.0.0'),
              _buildInfoRow('Platform', 'Admin Panel'),
              _buildInfoRow('Database', 'Supabase'),
              _buildInfoRow('Build', 'Production'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF2C3E50)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildIconContainer(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF2C3E50).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: const Color(0xFF2C3E50)),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getThemeLabel(String theme) {
    switch (theme) {
      case 'light':
        return 'Light theme';
      case 'dark':
        return 'Dark theme';
      case 'system':
        return 'Follow system settings';
      default:
        return 'Light theme';
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF2C3E50),
      ),
    );
  }
}

