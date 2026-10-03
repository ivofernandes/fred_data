import 'package:fred_data/fred_data.dart';
import 'package:test/test.dart';

void main() {
  group('FredObservation', () {
    test('parses values and dates without using the local timezone', () {
      final observation = FredObservation.fromJson({
        'date': '2025-01-02',
        'value': '-12.50',
        'realtime_start': '2025-01-03',
        'realtime_end': '2025-02-04',
      });
      expect(observation.date, DateTime.utc(2025, 1, 2));
      expect(observation.date.isUtc, isTrue);
      expect(observation.value, -12.5);
      expect(observation.realtimeStart, DateTime.utc(2025, 1, 3));
      expect(observation.realtimeEnd, DateTime.utc(2025, 2, 4));
    });

    test('keeps missing observations in the series', () {
      final observation = FredObservation.fromJson({
        'date': '2025-01-02',
        'value': '.',
      });
      expect(observation.value, isNull);
    });

    test('rejects non-finite values and normalized calendar dates', () {
      expect(
        () => FredObservation.fromJson({
          'date': '2025-01-02',
          'value': 'NaN',
        }),
        throwsFormatException,
      );
      expect(
        () => FredObservation.fromJson({
          'date': '2025-02-30',
          'value': '1',
        }),
        throwsFormatException,
      );
    });
  });

  group('FredObservationPage', () {
    test('parses metadata and observations', () {
      final page = FredObservationPage.fromJson({
        'count': 2,
        'offset': '0',
        'limit': 1000,
        'observations': [
          {'date': '2024-01-01', 'value': '3.25'},
          {'date': '2024-02-01', 'value': '.'},
        ],
      });
      expect(page.count, 2);
      expect(page.offset, 0);
      expect(page.limit, 1000);
      expect(page.observations, hasLength(2));
      expect(page.observations.map((item) => item.value), [3.25, null]);
    });

    test('rejects malformed response shapes and metadata', () {
      expect(
        () => FredObservationPage.fromJson({
          'count': -1,
          'offset': 0,
          'limit': 1,
          'observations': <Object?>[],
        }),
        throwsFormatException,
      );
      expect(
        () => FredObservationPage.fromJson({
          'count': 0,
          'offset': 0,
          'limit': 1,
          'observations': 'not an array',
        }),
        throwsFormatException,
      );
    });
  });
}
