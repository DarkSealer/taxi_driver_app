import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:taxi_rider_app/core/error/failures.dart';
import 'package:taxi_rider_app/core/result/result.dart';
import 'package:taxi_rider_app/features/auth/domain/entities/app_user.dart';
import 'package:taxi_rider_app/features/auth/domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);

  final FirebaseAuth _auth;

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Future<AppResult<UserCredential>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return Success(cred);
    } on FirebaseAuthException catch (e) {
      return FailureResult(AuthFailure(e.message ?? 'Sign-in failed'));
    } catch (e) {
      return FailureResult(AuthFailure('$e'));
    }
  }

  @override
  Future<AppResult<UserCredential>> registerWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return Success(cred);
    } on FirebaseAuthException catch (e) {
      return FailureResult(AuthFailure(e.message ?? 'Registration failed'));
    } catch (e) {
      return FailureResult(AuthFailure('$e'));
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();
}

class FirebaseUserProfileRepository implements UserProfileRepository {
  FirebaseUserProfileRepository(this._usersRoot);

  final DatabaseReference _usersRoot;

  @override
  Future<AppResult<bool>> profileExists(String uid) async {
    try {
      final snap = await _usersRoot.child(uid).get();
      return Success(snap.exists && snap.value != null);
    } catch (e) {
      return FailureResult(ServerFailure('Profile check failed: $e'));
    }
  }

  @override
  Future<AppResult<AppUser?>> fetchProfile(String uid) async {
    try {
      final snap = await _usersRoot.child(uid).get();
      if (!snap.exists || snap.value == null) {
        return const Success(null);
      }
      final map = Map<dynamic, dynamic>.from(snap.value! as Map);
      return Success(AppUser.fromRtdb(uid, map));
    } catch (e) {
      return FailureResult(ServerFailure('Failed to load profile: $e'));
    }
  }

  @override
  Future<AppResult<void>> saveProfile(String uid, AppUserDraft draft) async {
    try {
      await _usersRoot.child(uid).set(draft.toRtdbMap());
      return const Success(null);
    } catch (e) {
      return FailureResult(ServerFailure('Failed to save profile: $e'));
    }
  }
}
