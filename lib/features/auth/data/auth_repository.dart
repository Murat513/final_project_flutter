import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors.dart';

// ── Repository interface ───────────────────────────────────────────────────

abstract interface class IAuthRepository {
  /// Currently signed-in user, or `null` if unauthenticated.
  User? get currentUser;

  /// Reactive stream of auth-state changes.
  Stream<User?> get authStateChanges;

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  });

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  });

  Future<void> signOut();

  Future<void> sendPasswordResetEmail(String email);
}

// ── Concrete implementation ────────────────────────────────────────────────

class AuthRepository implements IAuthRepository {
  AuthRepository(this._auth);

  final FirebaseAuth _auth;

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e);
    }
  }

  @override
  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      // Persist display name immediately so other features can read it.
      await credential.user?.updateDisplayName(displayName.trim());
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e);
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e);
    }
  }

  // ── Error mapping ────────────────────────────────────────────────────────

  /// Translates Firebase error codes into human-readable [AppException]s.
  AppException _mapFirebaseError(FirebaseAuthException e) {
    final message = switch (e.code) {
      'user-not-found' => 'No account found for this email.',
      'wrong-password' => 'Incorrect password. Please try again.',
      'invalid-credential' => 'Invalid email or password.',
      'email-already-in-use' => 'An account with this email already exists.',
      'weak-password' => 'Password must be at least 6 characters.',
      'invalid-email' => 'Please enter a valid email address.',
      'user-disabled' => 'This account has been disabled.',
      'too-many-requests' =>
      'Too many attempts. Please wait a moment and try again.',
      'network-request-failed' =>
      'Network error. Check your connection and retry.',
      _ => e.message ?? 'Authentication failed. Please try again.',
    };
    return DatabaseException(message);
  }
}

// ── Riverpod providers ─────────────────────────────────────────────────────

final firebaseAuthProvider = Provider<FirebaseAuth>(
      (_) => FirebaseAuth.instance,
);

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  return AuthRepository(ref.watch(firebaseAuthProvider));
});

/// Reactive stream of the current [User]. `null` means unauthenticated.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Convenience provider — `true` when a user is signed in.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).value != null;
});