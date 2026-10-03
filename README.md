# fred_data

Typed, defensive parsing for observations returned by the Federal Reserve
Economic Data (FRED) API.

The parser retains FRED's missing (`.`) observations as nullable values, parses
calendar dates at midnight UTC, and rejects malformed metadata, dates, and
non-finite numeric values.

## Usage

```dart
import 'package:fred_data/fred_data.dart';

final page = FredObservationPage.fromJson(decodedResponse);
for (final observation in page.observations) {
  print('${observation.date}: ${observation.value ?? 'unavailable'}');
}
```
