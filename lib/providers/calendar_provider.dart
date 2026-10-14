import 'package:flutter/foundation.dart';

import '../services/nepali_calendar_api.dart';

class CalendarProvider extends ChangeNotifier {
  final int year, month;
  final NepaliCalendarApi api;
  CalendarMonthInfo? data;
  bool loading = true;
  String? error;
  bool _disposed = false;
  CalendarProvider(this.year, this.month, {NepaliCalendarApi? api})
    : api = api ?? NepaliCalendarApi.shared {
    reload();
  }
  Future<void> reload() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      data = await api.load(year, month, refresh: data != null);
    } catch (_) {
      error = 'Calendar details are unavailable. Check your connection and try again.';
    }
    if (_disposed) return;
    loading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
