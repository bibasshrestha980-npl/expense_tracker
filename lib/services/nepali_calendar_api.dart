import 'dart:convert';

import 'package:http/http.dart' as http;

class CalendarDayInfo {
  final int day;
  final String tithi, event;
  final bool holiday;
  const CalendarDayInfo({
    required this.day,
    required this.tithi,
    required this.event,
    required this.holiday,
  });
}

class CalendarMonthInfo {
  final Map<int, CalendarDayInfo> days;
  final String source;
  const CalendarMonthInfo(this.days, this.source);
}

class NepaliCalendarApi {
  final http.Client client;
  NepaliCalendarApi({http.Client? client}) : client = client ?? http.Client();
  static final shared = NepaliCalendarApi();
  final _cache = <String, CalendarMonthInfo>{};
  final _pending = <String, Future<CalendarMonthInfo?>>{};
  static const monthKeys = [
    'Baishakh',
    'Jestha',
    'Ashadh',
    'Shrawan',
    'Bhadra',
    'Ashwin',
    'Kartik',
    'Mangsir',
    'Poush',
    'Magh',
    'Falgun',
    'Chaitra',
  ];

  Future<CalendarMonthInfo?> load(
    int year,
    int month, {
    bool refresh = false,
  }) async {
    if (month < 1 || month > 12) throw ArgumentError.value(month);
    final key = '$year/$month';
    if (refresh) _cache.remove(key);
    if (_cache.containsKey(key)) return _cache[key];
    if (_pending.containsKey(key)) return _pending[key];
    final request = _fetch(year, month);
    _pending[key] = request;
    try {
      final result = await request;
      if (result != null) {
        if (_cache.length >= 24) _cache.remove(_cache.keys.first);
        _cache[key] = result;
      }
      return result;
    } finally {
      _pending.remove(key);
    }
  }

  Future<CalendarMonthInfo?> _fetch(int year, int month) async {
    final urls = [
      'https://bibhuticoder.github.io/nepali-calendar-api/api/$year.json',
      'https://the-value-crew.github.io/nepali-calendar-api/data/$year/$month.json',
      'https://raw.githubusercontent.com/sajanm/nepali-lunar-calendar-events/master/$year.json',
    ];
    Object? failure;
    // Current years should not wait for two known-stale archive requests.
    final order = year > 2076 ? [2, 0, 1] : [0, 1, 2];
    for (final index in order) {
      try {
        final response = await client
            .get(Uri.parse(urls[index]))
            .timeout(const Duration(seconds: 10));
        if (response.statusCode == 404) continue;
        if (response.statusCode != 200) {
          throw StateError('Calendar request failed');
        }
        final json = jsonDecode(utf8.decode(response.bodyBytes));
        if (index == 2) {
          if (json is! List) {
            throw const FormatException('Expected calendar year');
          }
          final days = <int, CalendarDayInfo>{};
          // Source versions contain either a flat year or arrays of months.
          final rows = json.expand<dynamic>(
            (value) => value is List ? value : [value],
          );
          for (final row in rows) {
            if (row is! Map) continue;
            final parts = '${row['bs']}'.split('-');
            if (parts.length != 3 ||
                int.tryParse(parts[0]) != year ||
                int.tryParse(parts[1]) != month) {
              continue;
            }
            final day = int.tryParse(parts[2]);
            if (day == null || day < 1 || day > 32) continue;
            String clean(dynamic value) {
              if (value is! String || value.trim() == '--') return '';
              return value.trim();
            }

            days[day] = CalendarDayInfo(
              day: day,
              tithi: clean(row['tithi']),
              event: clean(row['events'] ?? row['event']),
              holiday: row['holiday'] == true,
            );
          }
          if (days.isEmpty) continue;
          return CalendarMonthInfo(days, 'sajanm/nepali-lunar-calendar-events');
        }
        if (json is! Map<String, dynamic>) {
          throw const FormatException('Expected calendar object');
        }
        final rows = index == 0
            ? (json[monthKeys[month - 1]] ??
                  (month == 1 ? json['Baisakh'] : null))
            : json['days'];
        if (rows == null) continue;
        if (rows is! List) throw const FormatException('Expected days');
        final days = <int, CalendarDayInfo>{};
        for (final row in rows) {
          if (row is! Map) continue;
          final day = parseDay(row[index == 0 ? 'np' : 'n']);
          if (day == null || day < 1 || day > 32) continue;
          String field(String name) =>
              row[name] is String ? (row[name] as String).trim() : '';
          days[day] = CalendarDayInfo(
            day: day,
            tithi: field(index == 0 ? 'tithi' : 't'),
            event: field(index == 0 ? 'event' : 'f'),
            holiday: row[index == 0 ? 'holiday' : 'h'] == true,
          );
        }
        if (days.isEmpty) continue;
        return CalendarMonthInfo(
          days,
          index == 0
              ? 'bibhuticoder/nepali-calendar-api'
              : 'the-value-crew/nepali-calendar-api',
        );
      } catch (error) {
        failure = error;
      }
    }
    if (failure != null) {
      throw StateError('Calendar details could not be loaded.');
    }
    return null;
  }

  static int? parseDay(dynamic value) {
    var text = '$value'.trim();
    const digits = '०१२३४५६७८९';
    for (var i = 0; i < digits.length; i++) {
      text = text.replaceAll(digits[i], '$i');
    }
    return int.tryParse(text);
  }
}
