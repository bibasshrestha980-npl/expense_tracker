import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:expense_tracker/services/nepali_calendar_api.dart';

void main() {
  test(
    '2083 current source loads nested month rows without stale archives',
    () async {
      var requests = 0;
      final api = NepaliCalendarApi(
        client: MockClient((request) async {
          requests++;
          expect(request.url.host, 'raw.githubusercontent.com');
          return http.Response.bytes(
            utf8.encode(
              jsonEncode([
                [
                  {
                    'bs': '2083-06-01',
                    'tithi': 'षष्ठी',
                    'events': 'विश्वकर्मा पूजा',
                    'holiday': false,
                  },
                  {
                    'bs': '2083-06-02',
                    'tithi': 'सप्तमी',
                    'events': '--',
                    'holiday': false,
                  },
                  {'bs': '2083-07-01', 'events': 'Different month'},
                ],
              ]),
            ),
            200,
          );
        }),
      );
      final month = await api.load(2083, 6);
      expect(month!.days.length, 2);
      expect(month.days[1]!.event, 'विश्वकर्मा पूजा');
      expect(month.days[2]!.event, isEmpty);
      expect(month.source, contains('sajanm'));
      expect(requests, 1);
    },
  );
  test(
    'Original API parses padding, unicode and holidays and caches requests',
    () async {
      var calls = 0;
      final api = NepaliCalendarApi(
        client: MockClient((request) async {
          calls++;
          expect(request.url.host, 'bibhuticoder.github.io');
          return http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'Baishakh': [
                  {'np': ''},
                  {
                    'np': '१',
                    'tithi': ' सप्तमी ',
                    'event': 'नयाँ वर्ष',
                    'holiday': true,
                  },
                ],
              }),
            ),
            200,
          );
        }),
      );
      final result = await api.load(2073, 1);
      expect(result!.days.length, 1);
      expect(result.days[1]!.event, 'नयाँ वर्ष');
      expect(result.days[1]!.holiday, isTrue);
      await api.load(2073, 1);
      expect(calls, 1);
    },
  );
  test('Deprecated-source 404 falls back to successor format', () async {
    final api = NepaliCalendarApi(
      client: MockClient(
        (r) async => r.url.host == 'bibhuticoder.github.io'
            ? http.Response('', 404)
            : http.Response.bytes(
                utf8.encode(
                  jsonEncode({
                    'days': [
                      {'n': '२', 't': 'तृतीया', 'f': 'Festival', 'h': false},
                    ],
                  }),
                ),
                200,
              ),
      ),
    );
    final result = await api.load(2076, 2);
    expect(result!.days[2]!.tithi, 'तृतीया');
    expect(result.source, contains('the-value-crew'));
  });
  test('Missing year is distinct from request failure and can retry', () async {
    final absent = NepaliCalendarApi(
      client: MockClient((_) async => http.Response('', 404)),
    );
    expect(await absent.load(2083, 6), isNull);
    var broken = true;
    final api = NepaliCalendarApi(
      client: MockClient(
        (r) async => http.Response(
          broken
              ? 'bad json'
              : (r.url.host == 'raw.githubusercontent.com' ? '[]' : '{}'),
          200,
        ),
      ),
    );
    await expectLater(api.load(2083, 6), throwsStateError);
    broken = false;
    expect(await api.load(2083, 6), isNull);
  });
}
