import 'package:flutter/foundation.dart';

import '../models/usage_entry.dart';
import '../models/usage_period.dart';
import '../services/usage_tracking_service.dart';

class UsageController extends ChangeNotifier {
  UsageController(this._trackingService) {
    _trackingService.addListener(_onUsageChanged);
  }

  final UsageTrackingService _trackingService;
  late final VoidCallback _onUsageChanged = notifyListeners;
  UsagePeriod _period = UsagePeriod.month;

  UsagePeriod get period => _period;

  int get todayBytes => _trackingService.todayBytes;
  int get monthlyBytes => _trackingService.monthlyBytes;
  int get totalBytes => _trackingService.totalBytes;

  int get selectedTotalBytes {
    return switch (_period) {
      UsagePeriod.today => todayBytes,
      UsagePeriod.month => monthlyBytes,
      UsagePeriod.allTime => totalBytes,
    };
  }

  List<UsageEntry> get entries {
    final list = _trackingService.entries.where((entry) {
      return switch (_period) {
        UsagePeriod.today => entry.todayBytes > 0,
        UsagePeriod.month => entry.monthlyBytes > 0,
        UsagePeriod.allTime => entry.totalBytes > 0,
      };
    }).toList();
    list.sort((a, b) => usageFor(b).compareTo(usageFor(a)));
    return list;
  }

  int usageFor(UsageEntry entry) {
    return switch (_period) {
      UsagePeriod.today => entry.todayBytes,
      UsagePeriod.month => entry.monthlyBytes,
      UsagePeriod.allTime => entry.totalBytes,
    };
  }

  void setPeriod(UsagePeriod period) {
    if (_period == period) return;
    _period = period;
    notifyListeners();
  }

  Future<void> clear() => _trackingService.clear();

  @override
  void dispose() {
    _trackingService.removeListener(_onUsageChanged);
    super.dispose();
  }
}
