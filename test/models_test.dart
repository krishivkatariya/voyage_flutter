import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyage_flutter/models/activity.dart';
import 'package:voyage_flutter/models/expense.dart';
import 'package:voyage_flutter/models/trip.dart';
import 'package:voyage_flutter/models/trip_member.dart';
import 'package:voyage_flutter/models/user.dart';
import 'package:voyage_flutter/models/vote.dart';

void main() {
  group('TripMember', () {
    test(
      'serializes member details and restores the UID from the document ID',
      () {
        const member = TripMember(
          userId: 'auth-user-uid',
          name: 'Voyager',
          email: 'voyager@example.com',
          role: 'member',
        );

        final restored = TripMember.fromMap(
          member.toMap(),
          userId: member.userId,
        );

        expect(restored.userId, 'auth-user-uid');
        expect(restored.id, 'auth-user-uid');
        expect(restored.name, 'Voyager');
        expect(restored.email, 'voyager@example.com');
        expect(restored.role, 'member');
      },
    );
  });

  group('Activity', () {
    test('serializes a Firestore timestamp and uses path IDs on read', () {
      final activity = Activity(
        activityId: 'generated-activity-id',
        tripId: 'generated-trip-id',
        title: 'Museum visit',
        placeName: 'City museum',
        date: DateTime.utc(2026, 10, 15),
        startTime: '09:30',
        endTime: '11:00',
        description: 'Meet at the entrance',
        latitude: 45.5,
        longitude: -73.6,
        createdBy: 'auth-uid',
      );

      final data = activity.toMap();
      final restored = Activity.fromMap(
        data,
        activityId: activity.activityId,
        tripId: activity.tripId,
      );

      expect(data['date'], isA<Timestamp>());
      expect(data, isNot(contains('activityId')));
      expect(data, isNot(contains('tripId')));
      expect(restored.activityId, activity.activityId);
      expect(restored.tripId, activity.tripId);
      expect(restored.date.isAtSameMomentAs(activity.date), isTrue);
      expect(restored.startTime, '09:30');
      expect(restored.latitude, 45.5);
      expect(restored.longitude, -73.6);
      expect(restored.createdBy, 'auth-uid');
    });
  });

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

  group('Expense', () {
    test('serializes trip and payer fields without storing document ID', () {
      const expense = Expense(
        id: 'firestore-expense-id',
        tripId: 'firestore-trip-id',
        description: 'Dinner',
        amount: 1500.5,
        paidById: 'firebase-auth-uid',
        splitMemberIds: ['payer-uid', 'member-uid'],
      );

      final data = expense.toMap();
      final restored = Expense.fromMap(
        data,
        id: expense.id,
        tripId: expense.tripId,
      );

      expect(data['tripId'], 'firestore-trip-id');
      expect(data['description'], 'Dinner');
      expect(data['amount'], 1500.5);
      expect(data['paidById'], 'firebase-auth-uid');
      expect(data['splitMemberIds'], ['payer-uid', 'member-uid']);
      expect(data, isNot(contains('id')));
      expect(restored.id, 'firestore-expense-id');
      expect(restored.tripId, 'firestore-trip-id');
      expect(restored.amount, 1500.5);
      expect(restored.paidById, 'firebase-auth-uid');
      expect(restored.splitMemberIds, ['payer-uid', 'member-uid']);
    });

    test('treats missing split member IDs as an unsplit legacy expense', () {
      final expense = Expense.fromMap(
        {'description': 'Older expense', 'amount': 10, 'paidById': 'payer-uid'},
        id: 'expense-doc-id',
        tripId: 'trip-doc-id',
      );

      expect(expense.splitMemberIds, isEmpty);
    });
  });

  group('Vote', () {
    test('serializes voter UID and timestamp', () {
      final vote = Vote(
        voterId: 'firebase-auth-uid',
        votedAt: DateTime.utc(2026, 10, 4, 12),
      );

      final data = vote.toMap();
      final restored = Vote.fromMap(data, voterId: vote.voterId);

      expect(data['userId'], 'firebase-auth-uid');
      expect(data['votedAt'], isA<Timestamp>());
      expect(restored.voterId, vote.voterId);
      expect(restored.votedAt.isAtSameMomentAs(vote.votedAt), isTrue);
    });
  });
}
