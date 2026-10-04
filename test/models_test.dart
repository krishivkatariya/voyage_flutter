import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyage_flutter/models/trip.dart';
import 'package:voyage_flutter/models/user.dart';

void main() {
  group('User', () {
    test('reads a missing profile image as null and omits the document ID', () {
      const user = User(
        userId: 'auth-uid',
        name: 'Traveler',
        email: 'traveler@example.com',
      );

      final restored = User.fromMap(user.toMap(), userId: user.userId);

      expect(restored.userId, 'auth-uid');
      expect(restored.profileImage, isNull);
      expect(user.toMap(), isNot(contains('userId')));
    });
  });

  group('Trip', () {
    test('serializes dates and restores Firestore timestamps', () {
      final trip = Trip(
        tripId: 'firestore-document-id',
        ownerId: 'auth-uid',
        tripName: 'Weekend',
        destination: 'Example destination',
        startDate: DateTime.utc(2026, 10, 4),
        endDate: DateTime.utc(2026, 10, 6),
        tripType: TripType.group,
      );

      final data = trip.toMap();
      final restored = Trip.fromMap(data, tripId: trip.tripId);

      expect(data['startDate'], isA<Timestamp>());
      expect(restored.tripId, 'firestore-document-id');
      expect(restored.startDate.isAtSameMomentAs(trip.startDate), isTrue);
      expect(restored.endDate.isAtSameMomentAs(trip.endDate), isTrue);
      expect(restored.tripType, TripType.group);
      expect(data, isNot(contains('tripId')));
    });

    test('accepts date strings and case-insensitive trip type values', () {
      final trip = Trip.fromMap({
        'ownerId': 'auth-uid',
        'tripName': 'Solo trip',
        'destination': 'Example destination',
        'startDate': '2026-10-04T00:00:00.000Z',
        'endDate': '2026-10-06T00:00:00.000Z',
        'tripType': 'solo',
      }, tripId: 'firestore-document-id');

      expect(trip.tripType, TripType.solo);
      expect(trip.startDate, DateTime.utc(2026, 10, 4));
    });
  });
}
