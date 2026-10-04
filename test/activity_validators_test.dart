import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyage_flutter/features/itinerary/services/activity_validators.dart';

void main() {
  group('ActivityValidators', () {
    test('requires an activity title and place name', () {
      expect(ActivityValidators.validateTitle(' '), isNotNull);
      expect(ActivityValidators.validateTitle('Museum tour'), isNull);
      expect(ActivityValidators.validatePlaceName(''), isNotNull);
      expect(ActivityValidators.validatePlaceName('City museum'), isNull);
    });

    test('requires a date', () {
      expect(ActivityValidators.validateDate(null), isNotNull);
      expect(ActivityValidators.validateDate(DateTime(2026, 10, 15)), isNull);
    });

    test('requires times and rejects an end time before start time', () {
      const start = TimeOfDay(hour: 13, minute: 0);
      const earlier = TimeOfDay(hour: 12, minute: 59);
      const sameTime = TimeOfDay(hour: 13, minute: 0);
      const later = TimeOfDay(hour: 13, minute: 1);

      expect(ActivityValidators.validateTimes(null, null), isNotNull);
      expect(ActivityValidators.validateTimes(start, null), isNotNull);
      expect(ActivityValidators.validateTimes(start, earlier), isNotNull);
      expect(ActivityValidators.validateTimes(start, sameTime), isNull);
      expect(ActivityValidators.validateTimes(start, later), isNull);
    });

    test('serializes and parses time consistently as HH:mm', () {
      const time = TimeOfDay(hour: 9, minute: 5);

      expect(ActivityValidators.serializeTime(time), '09:05');
      expect(ActivityValidators.parseTime('09:05'), time);
      expect(ActivityValidators.parseTime('25:00'), isNull);
      expect(ActivityValidators.parseTime('9am'), isNull);
    });

    test('accepts empty optional coordinates and validates bounds', () {
      expect(
        ActivityValidators.validateCoordinate(
          '',
          minimum: -90,
          maximum: 90,
          label: 'latitude',
        ),
        isNull,
      );
      expect(
        ActivityValidators.validateCoordinate(
          '91',
          minimum: -90,
          maximum: 90,
          label: 'latitude',
        ),
        isNotNull,
      );
      expect(
        ActivityValidators.validateCoordinate(
          '45.5',
          minimum: -90,
          maximum: 90,
          label: 'latitude',
        ),
        isNull,
      );
    });
  });
}
