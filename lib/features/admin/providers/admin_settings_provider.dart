import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/admin_settings_service.dart';

final adminSettingsServiceProvider = Provider((ref) => AdminSettingsService());

final tableViewEnabledProvider = StateNotifierProvider<TableViewNotifier, bool>((ref) {
  return TableViewNotifier(ref.read(adminSettingsServiceProvider));
});

class TableViewNotifier extends StateNotifier<bool> {
  final AdminSettingsService _settingsService;

  TableViewNotifier(this._settingsService) : super(true) {
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    state = await _settingsService.getTableViewPreference();
  }

  Future<void> toggleTableView(bool enabled) async {
    state = enabled;
    await _settingsService.setTableViewPreference(enabled);
  }
}
