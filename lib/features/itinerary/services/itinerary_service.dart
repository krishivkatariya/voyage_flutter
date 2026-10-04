import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:voyage_flutter/models/activity.dart';

class ItineraryServiceException implements Exception {
  const ItineraryServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ItineraryService {
  ItineraryService({
    FirebaseFirestore? firestore,
    firebase_auth.FirebaseAuth? firebaseAuth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final firebase_auth.FirebaseAuth _firebaseAuth;

  CollectionReference<Map<String, dynamic>> _activities(String tripId) =>
      _firestore.collection('trips').doc(tripId).collection('activities');

  Future<String> createActivity({
    required String tripId,
    required String title,
    required String placeName,
    required DateTime date,
    required String startTime,
    required String endTime,
    String? description,
    double? latitude,
    double? longitude,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const ItineraryServiceException(
        'Sign in before adding an activity.',
      );
    }

    final reference = _activities(tripId).doc();
    final activity = Activity(
      activityId: reference.id,
      tripId: tripId,
      title: title.trim(),
      placeName: placeName.trim(),
      date: date,
      startTime: startTime,
      endTime: endTime,
      description: _normalizeDescription(description),
      latitude: latitude,
      longitude: longitude,
      createdBy: user.uid,
    );

    try {
      await _firestore.runTransaction((transaction) async {
        final tripReference = _firestore.collection('trips').doc(tripId);
        final tripSnapshot = await transaction.get(tripReference);
        if (!tripSnapshot.exists) {
          throw const ItineraryServiceException(
            'The selected trip no longer exists.',
          );
        }
        transaction.set(reference, activity.toMap());
      });
      return reference.id;
    } on ItineraryServiceException {
      rethrow;
    } on FirebaseException catch (error, stackTrace) {
      Error.throwWithStackTrace(_serviceException(error), stackTrace);
    }
  }

  Stream<List<Activity>> getActivities({required String tripId}) {
    return _activities(tripId).snapshots().map((snapshot) {
      final activities = snapshot.docs
          .map(
            (document) => Activity.fromMap(
              document.data(),
              activityId: document.id,
              tripId: tripId,
            ),
          )
          .toList();
      activities.sort(_compareActivities);
      return activities;
    });
  }

  Future<Activity?> getActivity({
    required String tripId,
    required String activityId,
  }) async {
    try {
      final snapshot = await _activities(tripId).doc(activityId).get();
      final data = snapshot.data();
      if (!snapshot.exists || data == null) {
        return null;
      }
      return Activity.fromMap(data, activityId: snapshot.id, tripId: tripId);
    } on FirebaseException catch (error, stackTrace) {
      Error.throwWithStackTrace(_serviceException(error), stackTrace);
    } on FormatException catch (error, stackTrace) {
      debugPrint('Invalid activity data at $tripId/$activityId: $error');
      Error.throwWithStackTrace(
        const ItineraryServiceException('Activity data could not be read.'),
        stackTrace,
      );
    } on TypeError catch (error, stackTrace) {
      debugPrint('Invalid activity data at $tripId/$activityId: $error');
      Error.throwWithStackTrace(
        const ItineraryServiceException('Activity data could not be read.'),
        stackTrace,
      );
    }
  }

  Future<void> updateActivity({required Activity activity}) async {
    _requireCurrentUser();
    try {
      await _activities(
        activity.tripId,
      ).doc(activity.activityId).update(activity.toMap());
    } on FirebaseException catch (error, stackTrace) {
      Error.throwWithStackTrace(_serviceException(error), stackTrace);
    }
  }

  Future<void> deleteActivity({
    required String tripId,
    required String activityId,
  }) async {
    _requireCurrentUser();
    try {
      await _activities(tripId).doc(activityId).delete();
    } on FirebaseException catch (error, stackTrace) {
      Error.throwWithStackTrace(_serviceException(error), stackTrace);
    }
  }

  firebase_auth.User _requireCurrentUser() {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const ItineraryServiceException(
        'Sign in to manage itinerary activities.',
      );
    }
    return user;
  }

  static int _compareActivities(Activity first, Activity second) {
    final dateOrder = DateTime(
      first.date.year,
      first.date.month,
      first.date.day,
    ).compareTo(DateTime(second.date.year, second.date.month, second.date.day));
    if (dateOrder != 0) {
      return dateOrder;
    }
    final firstTime = _parseTimeMinutes(first.startTime);
    final secondTime = _parseTimeMinutes(second.startTime);
    return firstTime.compareTo(secondTime);
  }

  static int _parseTimeMinutes(String value) {
    final parts = value.split(':');
    if (parts.length != 2) {
      return 0;
    }
    return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
  }

  String? _normalizeDescription(String? description) {
    final value = description?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  ItineraryServiceException _serviceException(FirebaseException error) {
    debugPrint('Itinerary operation failed (${error.code}): ${error.message}');
    switch (error.code) {
      case 'permission-denied':
        return const ItineraryServiceException(
          'You do not have permission to access this activity.',
        );
      case 'unavailable':
      case 'network-request-failed':
        return const ItineraryServiceException(
          'Could not reach the itinerary service. Check your connection.',
        );
      case 'not-found':
        return const ItineraryServiceException(
          'This activity no longer exists.',
        );
      default:
        return const ItineraryServiceException(
          'The activity could not be saved. Please try again.',
        );
    }
  }

  static String userMessage(Object error) {
    if (error is ItineraryServiceException) {
      return error.message;
    }
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'You do not have permission to access this activity.';
        case 'unavailable':
        case 'network-request-failed':
          return 'Could not reach the itinerary service. Check your connection.';
        case 'not-found':
          return 'This activity no longer exists.';
        default:
          return 'The itinerary could not be loaded. Please try again.';
      }
    }
    if (error is FormatException || error is TypeError) {
      return 'Activity data could not be read.';
    }
    return 'Something went wrong while loading the itinerary.';
  }
}
