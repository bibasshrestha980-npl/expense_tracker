import 'package:intl/intl.dart';
import 'package:nepali_utils/nepali_utils.dart';

String bsDate(DateTime date) =>
    '${NepaliDateFormat.yMMMMd().format(toBs(date))} BS';

String formatBsAndAdDate(DateTime date) =>
    '${bsDate(date)} (${DateFormat.yMMMd().format(date)})';

String formatBsAndAdMonth(DateTime anchor) =>
    '${NepaliDateFormat.yMMMM().format(toBs(anchor))} BS (${DateFormat.yMMMM().format(anchor)} AD)';

class CalendarPeriod {
  final DateTime anchor;
  final bool nepali;
  CalendarPeriod(this.anchor, {this.nepali = false});
  DateTime get start {
    if (!nepali) return DateTime(anchor.year, anchor.month);
    final bs = toBs(anchor);
    return NepaliDateTime(bs.year, bs.month).toDateTime();
  }

  DateTime shifted(int delta) {
    if (!nepali) return DateTime(anchor.year, anchor.month + delta);
    final bs = toBs(anchor);
    final index = bs.year * 12 + bs.month - 1 + delta;
    return NepaliDateTime(index ~/ 12, index % 12 + 1).toDateTime();
  }

  DateTime get end => shifted(1);
  int get days => nepali
      ? toBs(anchor).totalDays
      : DateTime(anchor.year, anchor.month + 1, 0).day;
  DateTime day(int number) =>
      DateTime(start.year, start.month, start.day + number - 1);
  int dayNumber(DateTime value) => nepali ? toBs(value).day : value.day;
  bool contains(DateTime value) =>
      !value.isBefore(start) && value.isBefore(end);
  String get label => nepali
      ? '${NepaliDateFormat.yMMMM().format(toBs(anchor))} BS'
      : '${DateFormat.yMMMM().format(anchor)} AD';
}

// Convert civil dates using the package's BS month table. UTC day arithmetic
// avoids historical timezone-offset differences on Windows and other hosts.
NepaliDateTime toBs(DateTime date) {
  var year = date.year + 56;
  var month = 1;
  final base = NepaliDateTime(year).toDateTime();
  var remaining = DateTime.utc(
    date.year,
    date.month,
    date.day,
  ).difference(DateTime.utc(base.year, base.month, base.day)).inDays;
  while (remaining >= NepaliDateTime(year, month).totalDays) {
    remaining -= NepaliDateTime(year, month).totalDays;
    month++;
    if (month == 13) {
      month = 1;
      year++;
    }
  }
  return NepaliDateTime(year, month, remaining + 1);
}
