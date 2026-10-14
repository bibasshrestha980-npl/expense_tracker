import 'package:flutter_test/flutter_test.dart';
import 'package:nepali_utils/nepali_utils.dart';
import 'package:expense_tracker/models/calendar_period.dart';

void main() {
  test('BS periods use complete Nepali months, including AD boundaries', () {
    final first = NepaliDateTime(2083, 6).toDateTime();
    final period = CalendarPeriod(first, nepali: true);
    expect(period.start, first);
    expect(period.days, NepaliDateTime(2083, 6).totalDays);
    expect(period.end, NepaliDateTime(2083, 7).toDateTime());
    expect(period.contains(period.day(period.days)), isTrue);
    expect(period.contains(period.end), isFalse);
    expect(period.dayNumber(period.day(15)), 15);
    expect(period.label, contains('2083'));
  });
  test('BS year transitions and date round trips preserve the day', () {
    final period = CalendarPeriod(
      NepaliDateTime(2083, 12).toDateTime(),
      nepali: true,
    );
    expect(period.shifted(1), NepaliDateTime(2084, 1).toDateTime());
    expect(
      CalendarPeriod(period.shifted(1), nepali: true).shifted(-1),
      period.start,
    );
    for (var i = 1; i <= period.days; i++) {
      final day = period.day(i);
      expect(toBs(day).toDateTime(), day);
    }
  });
  test('AD leap-year month stays correct', () {
    final period = CalendarPeriod(DateTime(2024, 2, 15));
    expect(period.days, 29);
    expect(period.start, DateTime(2024, 2));
    expect(period.end, DateTime(2024, 3));
  });
}
