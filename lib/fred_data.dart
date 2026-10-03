/// Models and parsing helpers for data returned by the FRED observations API.
library;

/// An observation in a FRED series.
///
/// FRED represents unavailable values with a `.`. Such values are exposed as
/// `null` rather than being discarded, so the date alignment of a series is
/// retained.
final class FredObservation {
  const FredObservation({
    required this.date,
    required this.value,
    this.realtimeStart,
    this.realtimeEnd,
  });

  /// The observation date, at midnight UTC.
  final DateTime date;

  /// The numeric value, or `null` when FRED reports `.`.
  final double? value;

  /// The first real-time period in which this value applies, if provided.
  final DateTime? realtimeStart;

  /// The last real-time period in which this value applies, if provided.
  final DateTime? realtimeEnd;

  /// Creates an observation from a FRED JSON object.
  factory FredObservation.fromJson(Map<String, Object?> json) {
    return FredObservation(
      date: _parseDate(json['date'], 'date'),
      value: _parseValue(json['value']),
      realtimeStart: _parseOptionalDate(
        json['realtime_start'],
        'realtime_start',
      ),
      realtimeEnd: _parseOptionalDate(json['realtime_end'], 'realtime_end'),
    );
  }
}

/// A page returned by FRED's series-observations endpoint.
final class FredObservationPage {
  const FredObservationPage({
    required this.observations,
    required this.count,
    required this.offset,
    required this.limit,
  });

  final List<FredObservation> observations;
  final int count;
  final int offset;
  final int limit;

  /// Parses a decoded FRED JSON response.
  ///
  /// Metadata is accepted as either JSON numbers or decimal strings.
  factory FredObservationPage.fromJson(Map<String, Object?> json) {
    final rawObservations = json['observations'];
    if (rawObservations is! List<Object?>) {
      throw const FormatException('observations must be a JSON array');
    }

    final observations = rawObservations.map((item) {
      if (item is! Map<String, Object?>) {
        throw const FormatException('each observation must be a JSON object');
      }
      return FredObservation.fromJson(item);
    }).toList(growable: false);

    return FredObservationPage(
      observations: observations,
      count: _parseNonNegativeInt(json['count'], 'count'),
      offset: _parseNonNegativeInt(json['offset'], 'offset'),
      limit: _parseNonNegativeInt(json['limit'], 'limit'),
    );
  }
}

double? _parseValue(Object? input) {
  if (input == '.') return null;
  final value = switch (input) {
    num number => number.toDouble(),
    String text => double.tryParse(text.trim()),
    _ => null,
  };
  if (value == null || !value.isFinite) {
    throw FormatException('value must be a finite number or ".": $input');
  }
  return value;
}

DateTime? _parseOptionalDate(Object? input, String field) =>
    input == null ? null : _parseDate(input, field);

DateTime _parseDate(Object? input, String field) {
  if (input is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(input)) {
    throw FormatException('$field must use YYYY-MM-DD: $input');
  }
  final parts = input.split('-').map(int.parse).toList(growable: false);
  final result = DateTime.utc(parts[0], parts[1], parts[2]);
  // DateTime normalizes dates such as February 30, so explicitly reject them.
  if (result.year != parts[0] ||
      result.month != parts[1] ||
      result.day != parts[2]) {
    throw FormatException('$field is not a valid calendar date: $input');
  }
  return result;
}

int _parseNonNegativeInt(Object? input, String field) {
  final value = switch (input) {
    int number => number,
    String text => int.tryParse(text),
    _ => null,
  };
  if (value == null || value < 0) {
    throw FormatException('$field must be a non-negative integer: $input');
  }
  return value;
}
