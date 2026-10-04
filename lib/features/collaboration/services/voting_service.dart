import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:voyage_flutter/models/vote.dart';

class VotingServiceException implements Exception {
  const VotingServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class VoteStatus {
  const VoteStatus({required this.count, required this.hasVoted});

  factory VoteStatus.fromVoterIds(
    Iterable<String> voterIds,
    String currentUserId,
  ) {
    final ids = voterIds.toList();
    return VoteStatus(count: ids.length, hasVoted: ids.contains(currentUserId));
  }

  final int count;
  final bool hasVoted;
}

class VotingService {
  VotingService({
    FirebaseFirestore? firestore,
    firebase_auth.FirebaseAuth? firebaseAuth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final firebase_auth.FirebaseAuth _firebaseAuth;

  DocumentReference<Map<String, dynamic>> _trip(String tripId) =>
      _firestore.collection('trips').doc(tripId);

  DocumentReference<Map<String, dynamic>> _activity(
    String tripId,
    String activityId,
  ) => _trip(tripId).collection('activities').doc(activityId);

  CollectionReference<Map<String, dynamic>> _votes(
    String tripId,
    String activityId,
  ) => _activity(tripId, activityId).collection('votes');

  Future<bool> isTripMember({
    required String tripId,
    required String userId,
  }) async {
    try {
      final tripSnapshot = await _trip(tripId).get();
      if (!tripSnapshot.exists) {
        throw const VotingServiceException('This trip no longer exists.');
      }
      final memberSnapshot = await _trip(
        tripId,
      ).collection('members').doc(userId).get();
      return memberSnapshot.exists;
    } on VotingServiceException {
      rethrow;
    } on FirebaseException catch (error, stackTrace) {
      Error.throwWithStackTrace(_serviceException(error), stackTrace);
    }
  }

  Future<bool> hasVoted({
    required String tripId,
    required String activityId,
    required String userId,
  }) async {
    try {
      return (await _votes(tripId, activityId).doc(userId).get()).exists;
    } on FirebaseException catch (error, stackTrace) {
      Error.throwWithStackTrace(_serviceException(error), stackTrace);
    }
  }

  Future<int> getVoteCount({
    required String tripId,
    required String activityId,
  }) async {
    try {
      final snapshot = await _votes(tripId, activityId).get();
      return snapshot.size;
    } on FirebaseException catch (error, stackTrace) {
      Error.throwWithStackTrace(_serviceException(error), stackTrace);
    }
  }

  Stream<VoteStatus> watchVoteStatus({
    required String tripId,
    required String activityId,
    required String userId,
  }) {
    return _votes(tripId, activityId).snapshots().map(
      (snapshot) => VoteStatus.fromVoterIds(
        snapshot.docs.map((document) => document.id),
        userId,
      ),
    );
  }

  Future<void> addVote({
    required String tripId,
    required String activityId,
  }) async {
    final user = _requireCurrentUser();
    final tripReference = _trip(tripId);
    final activityReference = _activity(tripId, activityId);
    final memberReference = tripReference.collection('members').doc(user.uid);
    final voteReference = _votes(tripId, activityId).doc(user.uid);

    try {
      await _firestore.runTransaction((transaction) async {
        final tripSnapshot = await transaction.get(tripReference);
        if (!tripSnapshot.exists) {
          throw const VotingServiceException('This trip no longer exists.');
        }
        final activitySnapshot = await transaction.get(activityReference);
        if (!activitySnapshot.exists) {
          throw const VotingServiceException(
            'This activity no longer exists in this trip.',
          );
        }
        final memberSnapshot = await transaction.get(memberReference);
        if (!memberSnapshot.exists) {
          throw const VotingServiceException(
            'You must be a member of this trip to vote.',
          );
        }
        final voteSnapshot = await transaction.get(voteReference);
        if (voteSnapshot.exists) {
          throw const VotingServiceException(
            'You have already voted for this activity.',
          );
        }

        transaction.set(
          voteReference,
          Vote(voterId: user.uid, votedAt: DateTime.now()).toMap(),
        );
      });
    } on VotingServiceException {
      rethrow;
    } on FirebaseException catch (error, stackTrace) {
      Error.throwWithStackTrace(_serviceException(error), stackTrace);
    }
  }

  Future<void> removeVote({
    required String tripId,
    required String activityId,
  }) async {
    final user = _requireCurrentUser();
    final tripReference = _trip(tripId);
    final activityReference = _activity(tripId, activityId);
    final memberReference = tripReference.collection('members').doc(user.uid);
    final voteReference = _votes(tripId, activityId).doc(user.uid);

    try {
      await _firestore.runTransaction((transaction) async {
        final tripSnapshot = await transaction.get(tripReference);
        if (!tripSnapshot.exists) {
          throw const VotingServiceException('This trip no longer exists.');
        }
        final activitySnapshot = await transaction.get(activityReference);
        if (!activitySnapshot.exists) {
          throw const VotingServiceException(
            'This activity no longer exists in this trip.',
          );
        }
        final memberSnapshot = await transaction.get(memberReference);
        if (!memberSnapshot.exists) {
          throw const VotingServiceException(
            'You must be a member of this trip to vote.',
          );
        }
        final voteSnapshot = await transaction.get(voteReference);
        if (!voteSnapshot.exists) {
          throw const VotingServiceException(
            'You have not voted for this activity.',
          );
        }

        transaction.delete(voteReference);
      });
    } on VotingServiceException {
      rethrow;
    } on FirebaseException catch (error, stackTrace) {
      Error.throwWithStackTrace(_serviceException(error), stackTrace);
    }
  }

  firebase_auth.User _requireCurrentUser() {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const VotingServiceException('Sign in before voting.');
    }
    return user;
  }

  VotingServiceException _serviceException(FirebaseException error) {
    debugPrint('Voting operation failed (${error.code}): ${error.message}');
    return VotingServiceException(userMessage(error));
  }

  static String userMessage(Object error) {
    if (error is VotingServiceException) {
      return error.message;
    }
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'You do not have permission to view or change these votes.';
        case 'unavailable':
        case 'network-request-failed':
          return 'Could not reach the voting service. Check your connection.';
        case 'not-found':
          return 'This trip or activity could not be found.';
        default:
          return 'The voting operation failed. Please try again.';
      }
    }
    return 'Something went wrong while loading votes.';
  }
}
