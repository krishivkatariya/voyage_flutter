import 'package:flutter_test/flutter_test.dart';
import 'package:voyage_flutter/features/trips/services/trip_validators.dart';

void main() {
  group('TripValidators', () {
    test('requires a trip name and destination', () {
      expect(TripValidators.validateTripName(' '), isNotNull);
      expect(TripValidators.validateTripName('Weekend away'), isNull);
      expect(TripValidators.validateDestination(''), isNotNull);
      expect(TripValidators.validateDestination('Rome'), isNull);
    });

    test('validates required dates and rejects an end date before start', () {
      final start = DateTime(2026, 10, 8);
      final earlierEnd = DateTime(2026, 10, 7);

      expect(TripValidators.validateDates(null, null), isNotNull);
      expect(TripValidators.validateDates(start, null), isNotNull);
      expect(TripValidators.validateDates(start, earlierEnd), isNotNull);
      expect(
        TripValidators.validateDates(start, DateTime(2026, 10, 8)),
        isNull,
      );
      expect(
        TripValidators.validateDates(start, DateTime(2026, 10, 9)),
        isNull,
      );
    });
  });
}
