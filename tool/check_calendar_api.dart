import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:expense_tracker/services/nepali_calendar_api.dart';

Future<void> main() async {
  final client = http.Client();
  try {
    final api = NepaliCalendarApi(client: client);
    for (final period in [(2073, 1), (2076, 2), (2083, 6)]) {
      final data = await api.load(period.$1, period.$2);
      stdout.writeln(
        '${period.$1}/${period.$2}: ${data == null ? 'not published' : '${data.days.length} days from ${data.source}'}',
      );
    }
  } finally {
    client.close();
  }
}
