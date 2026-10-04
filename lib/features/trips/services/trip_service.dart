import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:voyage_flutter/models/trip.dart';

class TripServiceException implements Exception {
  const TripServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class TripService {
  TripService({
    FirebaseFirestore? firestore,
    firebase_auth.FirebaseAuth? firebaseAuth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final firebase_auth.FirebaseAuth _firebaseAuth;

  CollectionReference<Map<String, dynamic>> get _trips =>
      _firestore.collection('trips');

  Future<String> createTrip({
    required String tripName,
    required String destination,
    required DateTime startDate,
    required DateTime endDate,
    required TripType tripType,
    String? description,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const TripServiceException('Sign in before creating a trip.');
    }

    final tripReference = _trips.doc();
    final trip = Trip(
      tripId: tripReference.id,
      ownerId: user.uid,
      tripName: tripName.trim(),
      destination: destination.trim(),
      startDate: startDate,
      endDate: endDate,
      tripType: tripType,
      description: _normalizeDescription(description),
    );

    try {
      await tripReference.set(trip.toMap());
      return tripReference.id;
    } on FirebaseException catch (error, stackTrace) {
      Error.throwWithStackTrace(_serviceException(error), stackTrace);
    }
  }

  Stream<List<Trip>> getUserTrips({required String ownerId}) {
    return _trips
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (document) =>
                        Trip.fromMap(document.data(), tripId: document.id),
                  )
                  .toList()
                ..sort((a, b) => a.startDate.compareTo(b.startDate)),
        );
  }

  Future<Trip?> getTrip({required String tripId}) async {
    try {
      final snapshot = await _trips.doc(tripId).get();
      final data = snapshot.data();
      if (!snapshot.exists || data == null) {
        return null;
      }
      return Trip.fromMap(data, tripId: snapshot.id);
    } on FirebaseException catch (error, stackTrace) {
      Error.throwWithStackTrace(_serviceException(error), stackTrace);
    } on FormatException catch (error, stackTrace) {
      debugPrint('Invalid trip data for $tripId: $error');
      Error.throwWithStackTrace(
        const TripServiceException('Trip data could not be read.'),
        stackTrace,
      );
    } on TypeError catch (error, stackTrace) {
      debugPrint('Invalid trip data for $tripId: $error');
      Error.throwWithStackTrace(
        const TripServiceException('Trip data could not be read.'),
        stackTrace,
      );
    }
  }

  Future<void> updateTrip({required Trip trip}) async {
    final user = _requireCurrentUser();
    final reference = _trips.doc(trip.tripId);

    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(reference);
        _requireOwner(snapshot.data(), user.uid);
        transaction.update(reference, {
          'tripName': trip.tripName.trim(),
          'destination': trip.destination.trim(),
          'startDate': Timestamp.fromDate(trip.startDate),
          'endDate': Timestamp.fromDate(trip.endDate),
          'tripType': trip.tripType.label,
          'description': _normalizeDescription(trip.description),
        });
      });
    } on TripServiceException {
      rethrow;
    } on FirebaseException catch (error, stackTrace) {
      Error.throwWithStackTrace(_serviceException(error), stackTrace);
    }
  }

  Future<void> deleteTrip({required String tripId}) async {
    final user = _requireCurrentUser();
    final reference = _trips.doc(tripId);

    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(reference);
        _requireOwner(snapshot.data(), user.uid);
        transaction.delete(reference);
      });
    } on TripServiceException {
      rethrow;
    } on FirebaseException catch (error, stackTrace) {
      Error.throwWithStackTrace(_serviceException(error), stackTrace);
    }
  }

  static String userMessage(Object error) {
    if (error is TripServiceException) {
      return error.message;
    }
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'You do not have permission to access this trip.';
        case 'unavailable':
        case 'network-request-failed':
          return 'Could not reach the trip service. Check your connection.';
        case 'not-found':
          return 'This trip no longer exists.';
        default:
          return 'The trip could not be loaded. Please try again.';
      }
    }
    if (error is FormatException || error is TypeError) {
      return 'Trip data could not be read.';
    }
    return 'Something went wrong while loading this trip.';
  }

  firebase_auth.User _requireCurrentUser() {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const TripServiceException('Sign in to manage trips.');
    }
    return user;
  }

  void _requireOwner(Map<String, dynamic>? data, String userId) {
    if (data == null) {
      throw const TripServiceException('This trip no longer exists.');
    }
    if (data['ownerId'] != userId) {
      throw const TripServiceException('Only the trip owner can do this.');
    }
  }

  String? _normalizeDescription(String? description) {
    final value = description?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  TripServiceException _serviceException(FirebaseException error) {
    debugPrint('Trip operation failed (${error.code}): ${error.message}');
    return TripServiceException(userMessage(error));
  }
}
