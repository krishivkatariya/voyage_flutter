import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:voyage_flutter/features/collaboration/services/member_validators.dart';
import 'package:voyage_flutter/models/trip_member.dart';

class CollaborationServiceException implements Exception {
  const CollaborationServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CollaborationService {
  CollaborationService({
    FirebaseFirestore? firestore,
    firebase_auth.FirebaseAuth? firebaseAuth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final firebase_auth.FirebaseAuth _firebaseAuth;

  DocumentReference<Map<String, dynamic>> _trip(String tripId) =>
      _firestore.collection('trips').doc(tripId);

  CollectionReference<Map<String, dynamic>> _members(String tripId) =>
      _trip(tripId).collection('members');

  Future<List<TripMember>> getMembers({required String tripId}) async {
    final currentUser = _requireCurrentUser();
    try {
      final tripSnapshot = await _trip(tripId).get();
      final tripData = tripSnapshot.data();
      if (!tripSnapshot.exists || tripData == null) {
        throw const CollaborationServiceException(
          'This trip no longer exists.',
        );
      }

      final ownerId = tripData['ownerId'];
      if (ownerId is! String || ownerId.isEmpty) {
        throw const CollaborationServiceException(
          'Trip owner information could not be read.',
        );
      }

      final memberSnapshot = await _members(tripId).get();
      final membersById = <String, TripMember>{};
      for (final document in memberSnapshot.docs) {
        final member = TripMember.fromMap(document.data(), userId: document.id);
        membersById[document.id] = TripMember(
          userId: member.userId,
          name: member.name,
          email: member.email,
          role: document.id == ownerId ? 'owner' : 'member',
        );
      }

      if (currentUser.uid != ownerId &&
          !membersById.containsKey(currentUser.uid)) {
        throw const CollaborationServiceException(
          'You must be a trip member to view this list.',
        );
      }

      if (!membersById.containsKey(ownerId)) {
        membersById[ownerId] = TripMember(
          userId: ownerId,
          name: 'Trip owner',
          role: 'owner',
        );
      }

      final members = membersById.values.toList()
        ..sort((first, second) {
          if (first.role == 'owner') {
            return second.role == 'owner' ? 0 : -1;
          }
          if (second.role == 'owner') {
            return 1;
          }
          return first.name.toLowerCase().compareTo(second.name.toLowerCase());
        });
      return members;
    } on CollaborationServiceException {
      rethrow;
    } on FirebaseException catch (error, stackTrace) {
      Error.throwWithStackTrace(_serviceException(error), stackTrace);
    } on TypeError catch (error, stackTrace) {
      debugPrint('Invalid member data for trip $tripId: $error');
      Error.throwWithStackTrace(
        const CollaborationServiceException(
          'Member information could not be read.',
        ),
        stackTrace,
      );
    }
  }

  Future<TripMember?> getMember({
    required String tripId,
    required String userId,
  }) async {
    _requireCurrentUser();
    try {
      final snapshot = await _members(tripId).doc(userId).get();
      final data = snapshot.data();
      if (!snapshot.exists || data == null) {
        final tripSnapshot = await _trip(tripId).get();
        final ownerId = tripSnapshot.data()?['ownerId'];
        if (ownerId == userId && tripSnapshot.exists) {
          return TripMember(
            userId: userId,
            name: 'Trip owner',
            role: 'owner',
          );
        }
        return null;
      }
      return TripMember.fromMap(data, userId: snapshot.id);
    } on FirebaseException catch (error, stackTrace) {
      Error.throwWithStackTrace(_serviceException(error), stackTrace);
    }
  }

  Future<void> addMemberByEmail({
    required String tripId,
    required String email,
  }) async {
    final currentUser = _requireCurrentUser();
    final normalizedEmail = MemberValidators.normalizeEmail(email);
    try {
      await _requireTripOwner(tripId, currentUser.uid);

      // Email lookup runs against the authenticated, non-sensitive
      // `userDirectory` index; the private `users/{userId}` profile of another
      // account is never read from the client.
      final matches = await _firestore
          .collection('userDirectory')
          .where('emailLowercase', isEqualTo: normalizedEmail)
          .limit(1)
          .get();
      if (matches.docs.isEmpty) {
        throw const CollaborationServiceException(
          'User not found. They must register for Voyage first.',
        );
      }

      final directoryDocument = matches.docs.first;
      final targetId = directoryDocument.id;
      final userData = directoryDocument.data();
      final targetMemberReference = _members(tripId).doc(targetId);
      final memberName = userData['name'];
      final memberEmail = userData['email'];
      final member = TripMember(
        userId: targetId,
        name: memberName is String && memberName.trim().isNotEmpty
            ? memberName.trim()
            : memberEmail as String? ?? normalizedEmail,
        email: memberEmail as String? ?? normalizedEmail,
        role: 'member',
      );

      await _firestore.runTransaction((transaction) async {
        final tripSnapshot = await transaction.get(_trip(tripId));
        _verifyOwner(tripSnapshot.data(), tripSnapshot.exists, currentUser.uid);
        final memberSnapshot = await transaction.get(targetMemberReference);
        if (memberSnapshot.exists) {
          throw const CollaborationServiceException(
            'User is already a member of this trip.',
          );
        }
        transaction.set(targetMemberReference, member.toMap());
      });
    } on CollaborationServiceException {
      rethrow;
    } on FirebaseException catch (error, stackTrace) {
      Error.throwWithStackTrace(_serviceException(error), stackTrace);
    }
  }

  Future<void> removeMember({
    required String tripId,
    required String userId,
  }) async {
    final currentUser = _requireCurrentUser();
    if (userId == currentUser.uid) {
      throw const CollaborationServiceException(
        'You cannot remove yourself from this trip.',
      );
    }

    try {
      final tripReference = _trip(tripId);
      final memberReference = _members(tripId).doc(userId);
      await _firestore.runTransaction((transaction) async {
        final tripSnapshot = await transaction.get(tripReference);
        final tripData = tripSnapshot.data();
        _verifyOwner(tripData, tripSnapshot.exists, currentUser.uid);
        if (tripData?['ownerId'] == userId) {
          throw const CollaborationServiceException(
            'The trip owner cannot be removed.',
          );
        }
        final memberSnapshot = await transaction.get(memberReference);
        if (!memberSnapshot.exists) {
          throw const CollaborationServiceException(
            'This user is no longer a member of the trip.',
          );
        }
        transaction.delete(memberReference);
      });
    } on CollaborationServiceException {
      rethrow;
    } on FirebaseException catch (error, stackTrace) {
      Error.throwWithStackTrace(_serviceException(error), stackTrace);
    }
  }

  Future<void> _requireTripOwner(String tripId, String userId) async {
    final snapshot = await _trip(tripId).get();
    _verifyOwner(snapshot.data(), snapshot.exists, userId);
  }

  void _verifyOwner(
    Map<String, dynamic>? data,
    bool tripExists,
    String currentUserId,
  ) {
    if (!tripExists || data == null) {
      throw const CollaborationServiceException('This trip no longer exists.');
    }
    if (data['ownerId'] != currentUserId) {
      throw const CollaborationServiceException(
        'Only the trip owner can manage members.',
      );
    }
  }

  firebase_auth.User _requireCurrentUser() {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const CollaborationServiceException(
        'Sign in to view or manage trip members.',
      );
    }
    return user;
  }

  CollaborationServiceException _serviceException(FirebaseException error) {
    debugPrint(
      'Collaboration operation failed (${error.code}): ${error.message}',
    );
    return CollaborationServiceException(userMessage(error));
  }

  static String userMessage(Object error) {
    if (error is CollaborationServiceException) {
      return error.message;
    }
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'You do not have permission to view or manage these members.';
        case 'unavailable':
        case 'network-request-failed':
          return 'Could not reach the member service. Check your connection.';
        case 'not-found':
          return 'This trip or user could not be found.';
        default:
          return 'The member operation failed. Please try again.';
      }
    }
    if (error is TypeError) {
      return 'Member information could not be read.';
    }
    return 'Something went wrong while loading members.';
  }
}
