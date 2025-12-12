import 'package:shared_preferences/shared_preferences.dart';

class AdminSettingsService {
  static const String _tableViewKey = 'admin_table_view_enabled';
  static const String _themeModeKey = 'admin_theme_mode';
  static const String _itemsPerPageKey = 'admin_items_per_page';
  static const String _dateFormatKey = 'admin_date_format';
  static const String _autoRefreshKey = 'admin_auto_refresh_enabled';
  static const String _refreshIntervalKey = 'admin_refresh_interval';
  static const String _notificationsKey = 'admin_notifications_enabled';
  static const String _exportFormatKey = 'admin_export_format';
  static const String _compactViewKey = 'admin_compact_view';

  // Table view preference
  Future<bool> getTableViewPreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_tableViewKey) ?? true;
  }

  Future<void> setTableViewPreference(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tableViewKey, enabled);
  }

  // Theme mode (light, dark, system)
  Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeModeKey) ?? 'light';
  }

  Future<void> setThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode);
  }

  // Items per page
  Future<int> getItemsPerPage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_itemsPerPageKey) ?? 20;
  }

  Future<void> setItemsPerPage(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_itemsPerPageKey, count);
  }

  // Date format
  Future<String> getDateFormat() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_dateFormatKey) ?? 'MMM dd, yyyy';
  }

  Future<void> setDateFormat(String format) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dateFormatKey, format);
  }

  // Auto refresh
  Future<bool> getAutoRefreshEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoRefreshKey) ?? false;
  }

  Future<void> setAutoRefreshEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoRefreshKey, enabled);
  }

  // Refresh interval (in seconds)
  Future<int> getRefreshInterval() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_refreshIntervalKey) ?? 30;
  }

  Future<void> setRefreshInterval(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_refreshIntervalKey, seconds);
  }

  // Notifications
  Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsKey) ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, enabled);
  }

  // Export format
  Future<String> getExportFormat() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_exportFormatKey) ?? 'csv';
  }

  Future<void> setExportFormat(String format) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_exportFormatKey, format);
  }

  // Compact view
  Future<bool> getCompactView() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_compactViewKey) ?? false;
  }

  Future<void> setCompactView(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_compactViewKey, enabled);
  }

  // Clear all settings
  Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tableViewKey);
    await prefs.remove(_themeModeKey);
    await prefs.remove(_itemsPerPageKey);
    await prefs.remove(_dateFormatKey);
    await prefs.remove(_autoRefreshKey);
    await prefs.remove(_refreshIntervalKey);
    await prefs.remove(_notificationsKey);
    await prefs.remove(_exportFormatKey);
    await prefs.remove(_compactViewKey);
  }
}
