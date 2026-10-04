import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:voyage_flutter/features/collaboration/services/member_validators.dart';
import 'package:voyage_flutter/models/user.dart' as voyage_model;

class AuthService {
  AuthService({
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  }) : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  Stream<firebase_auth.User?> get authStateChanges =>
      _firebaseAuth.authStateChanges();

  Future<firebase_auth.UserCredential> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw StateError('Firebase Authentication did not return a user.');
    }

    final profileEmail = firebaseUser.email ?? email.trim();
    final user = voyage_model.User(
      userId: firebaseUser.uid,
      name: name.trim(),
      email: profileEmail,
    );

    // The private profile and the non-sensitive directory entry are committed
    // together so a registration can never leave them out of sync. The
    // directory is what other members use for email-based lookup.
    final batch = _firestore.batch();
    batch.set(
      _firestore.collection('users').doc(firebaseUser.uid),
      user.toMap(),
    );
    batch.set(
      _firestore.collection('userDirectory').doc(firebaseUser.uid),
      {
        'userId': firebaseUser.uid,
        'email': profileEmail,
        'emailLowercase': MemberValidators.normalizeEmail(profileEmail),
        'name': user.name,
      },
    );
    await batch.commit();

    return credential;
  }

  Future<firebase_auth.UserCredential> loginUser({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> logoutUser() => _firebaseAuth.signOut();

  static String errorMessage(Object error) {
    if (error is firebase_auth.FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'An account already exists for this email.';
        case 'invalid-email':
          return 'Enter a valid email address.';
        case 'weak-password':
          return 'Choose a stronger password.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'The email or password is incorrect.';
        case 'too-many-requests':
          return 'Too many attempts. Please wait and try again.';
        case 'network-request-failed':
          return 'Network error. Check your connection and try again.';
        case 'operation-not-allowed':
          return 'Email and password sign-in is not enabled in Firebase.';
        default:
          return 'Authentication failed. Please try again.';
      }
    }

    if (error is FirebaseException) {
      if (error.code == 'permission-denied') {
        return 'Your account was created, but its profile could not be saved. '
            'Check your Firestore security rules.';
      }
      if (error.code == 'unavailable' ||
          error.code == 'network-request-failed') {
        return 'Could not reach Firestore. Check your connection and try again.';
      }
      return 'Could not save your profile. Please try again.';
    }

    return 'Something went wrong. Please try again.';
  }
}
