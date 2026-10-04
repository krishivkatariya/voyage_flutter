import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:voyage_flutter/features/expenses/services/expense_validators.dart';
import 'package:voyage_flutter/models/expense.dart';

class ExpenseServiceException implements Exception {
  const ExpenseServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ExpenseService {
  ExpenseService({
    FirebaseFirestore? firestore,
    firebase_auth.FirebaseAuth? firebaseAuth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final firebase_auth.FirebaseAuth _firebaseAuth;

  DocumentReference<Map<String, dynamic>> _trip(String tripId) =>
      _firestore.collection('trips').doc(tripId);

  CollectionReference<Map<String, dynamic>> _expenses(String tripId) =>
      _trip(tripId).collection('expenses');

  Stream<List<Expense>> watchExpenses(String tripId) async* {
    final user = _requireCurrentUser();
    try {
      final tripSnapshot = await _trip(tripId).get();
      if (!tripSnapshot.exists) {
        throw const ExpenseServiceException('This trip no longer exists.');
      }
      final memberSnapshot = await _trip(
        tripId,
      ).collection('members').doc(user.uid).get();
      if (!memberSnapshot.exists) {
        throw const ExpenseServiceException(
          'You must be a member of this trip to view its expenses.',
        );
      }

      yield* _expenses(tripId).snapshots().map((snapshot) {
        final expenses =
            snapshot.docs
                .map(
                  (document) => Expense.fromMap(
                    document.data(),
                    id: document.id,
                    tripId: tripId,
                  ),
                )
                .toList()
              ..sort(
                (first, second) => first.description.toLowerCase().compareTo(
                  second.description.toLowerCase(),
                ),
              );
        return expenses;
      });
    } on ExpenseServiceException {
      rethrow;
    } on FirebaseException catch (error, stackTrace) {
      Error.throwWithStackTrace(_serviceException(error), stackTrace);
    }
  }

  Future<String> addExpense({
    required String tripId,
    required String description,
    required double amount,
    List<String> splitMemberIds = const [],
  }) async {
    final user = _requireCurrentUser();
    _validateFields(description, amount);
    _validateSplitMemberIds(splitMemberIds);
    final expenseReference = _expenses(tripId).doc();
    final expense = Expense(
      id: expenseReference.id,
      tripId: tripId,
      description: description.trim(),
      amount: amount,
      paidById: user.uid,
      splitMemberIds: List.unmodifiable(splitMemberIds),
    );

    try {
      await _firestore.runTransaction((transaction) async {
        final tripReference = _trip(tripId);
        final tripSnapshot = await transaction.get(tripReference);
        if (!tripSnapshot.exists) {
          throw const ExpenseServiceException('This trip no longer exists.');
        }
        final memberSnapshot = await transaction.get(
          tripReference.collection('members').doc(user.uid),
        );
        if (!memberSnapshot.exists) {
          throw const ExpenseServiceException(
            'You must be a member of this trip to add an expense.',
          );
        }
        await _verifySplitMembers(transaction, tripReference, splitMemberIds);
        transaction.set(expenseReference, expense.toMap());
      });
      return expenseReference.id;
    } on ExpenseServiceException {
      rethrow;
    } on FirebaseException catch (error, stackTrace) {
      Error.throwWithStackTrace(_serviceException(error), stackTrace);
    }
  }

  Future<void> updateExpense({required Expense expense}) async {
    final user = _requireCurrentUser();
    _validateFields(expense.description, expense.amount);
    _validateSplitMemberIds(expense.splitMemberIds);
    if (expense.id.isEmpty || expense.tripId.isEmpty) {
      throw const ExpenseServiceException('Expense information is missing.');
    }
    final tripReference = _trip(expense.tripId);
    final expenseReference = _expenses(expense.tripId).doc(expense.id);

    try {
      await _firestore.runTransaction((transaction) async {
        final tripSnapshot = await transaction.get(tripReference);
        if (!tripSnapshot.exists) {
          throw const ExpenseServiceException('This trip no longer exists.');
        }
        final memberSnapshot = await transaction.get(
          tripReference.collection('members').doc(user.uid),
        );
        if (!memberSnapshot.exists) {
          throw const ExpenseServiceException(
            'You must be a member of this trip to edit expenses.',
          );
        }
        final expenseSnapshot = await transaction.get(expenseReference);
        final expenseData = expenseSnapshot.data();
        if (!expenseSnapshot.exists || expenseData == null) {
          throw const ExpenseServiceException('This expense no longer exists.');
        }
        if (expenseData['paidById'] != user.uid) {
          throw const ExpenseServiceException(
            'Only the original payer can edit this expense.',
          );
        }
        await _verifySplitMembers(
          transaction,
          tripReference,
          expense.splitMemberIds,
        );
        transaction.update(expenseReference, {
          'description': expense.description.trim(),
          'amount': expense.amount,
          'splitMemberIds': expense.splitMemberIds,
        });
      });
    } on ExpenseServiceException {
      rethrow;
    } on FirebaseException catch (error, stackTrace) {
      Error.throwWithStackTrace(_serviceException(error), stackTrace);
    }
  }

  Future<void> deleteExpense({
    required String tripId,
    required String expenseId,
  }) async {
    final user = _requireCurrentUser();
    final tripReference = _trip(tripId);
    final expenseReference = _expenses(tripId).doc(expenseId);

    try {
      await _firestore.runTransaction((transaction) async {
        final tripSnapshot = await transaction.get(tripReference);
        if (!tripSnapshot.exists) {
          throw const ExpenseServiceException('This trip no longer exists.');
        }
        final memberSnapshot = await transaction.get(
          tripReference.collection('members').doc(user.uid),
        );
        if (!memberSnapshot.exists) {
          throw const ExpenseServiceException(
            'You must be a member of this trip to delete expenses.',
          );
        }
        final expenseSnapshot = await transaction.get(expenseReference);
        final expenseData = expenseSnapshot.data();
        if (!expenseSnapshot.exists || expenseData == null) {
          throw const ExpenseServiceException('This expense no longer exists.');
        }
        if (expenseData['paidById'] != user.uid) {
          throw const ExpenseServiceException(
            'Only the original payer can delete this expense.',
          );
        }
        transaction.delete(expenseReference);
      });
    } on ExpenseServiceException {
      rethrow;
    } on FirebaseException catch (error, stackTrace) {
      Error.throwWithStackTrace(_serviceException(error), stackTrace);
    }
  }

  firebase_auth.User _requireCurrentUser() {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const ExpenseServiceException('Sign in to manage expenses.');
    }
    return user;
  }

  void _validateFields(String description, double amount) {
    final descriptionError = ExpenseValidators.validateDescription(description);
    if (descriptionError != null) {
      throw ExpenseServiceException(descriptionError);
    }
    final amountError = ExpenseValidators.validateAmountValue(amount);
    if (amountError != null) {
      throw ExpenseServiceException(amountError);
    }
  }

  void _validateSplitMemberIds(List<String> splitMemberIds) {
    if (splitMemberIds.isEmpty) {
      return;
    }
    if (splitMemberIds.any((memberId) => memberId.trim().isEmpty)) {
      throw const ExpenseServiceException('A split member ID is invalid.');
    }
    if (splitMemberIds.toSet().length != splitMemberIds.length) {
      throw const ExpenseServiceException(
        'A member can only be selected once in a split.',
      );
    }
  }

  Future<void> _verifySplitMembers(
    Transaction transaction,
    DocumentReference<Map<String, dynamic>> tripReference,
    List<String> splitMemberIds,
  ) async {
    for (final memberId in splitMemberIds) {
      final memberSnapshot = await transaction.get(
        tripReference.collection('members').doc(memberId),
      );
      if (!memberSnapshot.exists) {
        throw const ExpenseServiceException(
          'Every selected person must be a member of this trip.',
        );
      }
    }
  }

  ExpenseServiceException _serviceException(FirebaseException error) {
    debugPrint('Expense operation failed (${error.code}): ${error.message}');
    return ExpenseServiceException(userMessage(error));
  }

  static String userMessage(Object error) {
    if (error is ExpenseServiceException) {
      return error.message;
    }
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'You do not have permission to access these expenses.';
        case 'unavailable':
        case 'network-request-failed':
          return 'Could not reach the expense service. Check your connection.';
        case 'not-found':
          return 'This trip or expense could not be found.';
        default:
          return 'The expense operation failed. Please try again.';
      }
    }
    if (error is FormatException || error is TypeError) {
      return 'Expense data could not be read.';
    }
    return 'Something went wrong while loading expenses.';
  }
}
