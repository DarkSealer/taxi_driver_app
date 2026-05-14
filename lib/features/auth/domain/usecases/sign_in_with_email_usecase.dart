import 'package:firebase_auth/firebase_auth.dart';
import 'package:taxi_rider_app/core/error/failures.dart';
import 'package:taxi_rider_app/core/result/result.dart';
import 'package:taxi_rider_app/features/auth/domain/entities/app_user.dart';
import 'package:taxi_rider_app/features/auth/domain/repositories/auth_repository.dart';

class SignInWithEmailUseCase {
  SignInWithEmailUseCase(this._auth, this._profiles);

  final AuthRepository _auth;
  final UserProfileRepository _profiles;

  Future<AppResult<void>> call({
    required String email,
    required String password,
  }) async {
    final credResult = await _auth.signInWithEmail(
      email: email,
      password: password,
    );
    if (credResult is FailureResult<UserCredential, Failure>) {
      return FailureResult(credResult.error);
    }
    final cred = (credResult as Success<UserCredential, Failure>).value;
    final uid = cred.user?.uid;
    if (uid == null) {
      return const FailureResult(AuthFailure('No user returned'));
    }
    final existsResult = await _profiles.profileExists(uid);
    if (existsResult is FailureResult<bool, Failure>) {
      return FailureResult(existsResult.error);
    }
    final exists = (existsResult as Success<bool, Failure>).value;
    if (!exists) {
      await _auth.signOut();
      return const FailureResult(
        AuthFailure('This account is not registered in the database'),
      );
    }
    return const Success(null);
  }
}

class RegisterPassengerUseCase {
  RegisterPassengerUseCase(this._auth, this._profiles);

  final AuthRepository _auth;
  final UserProfileRepository _profiles;

  Future<AppResult<void>> call({
    required String email,
    required String password,
    required AppUserDraft draft,
  }) async {
    final credResult = await _auth.registerWithEmail(
      email: email,
      password: password,
    );
    if (credResult is FailureResult<UserCredential, Failure>) {
      return FailureResult(credResult.error);
    }
    final cred = (credResult as Success<UserCredential, Failure>).value;
    final uid = cred.user?.uid;
    if (uid == null) {
      return const FailureResult(AuthFailure('No user returned'));
    }
    final save = await _profiles.saveProfile(uid, draft);
    if (save is FailureResult<void, Failure>) {
      return FailureResult(save.error);
    }
    return const Success(null);
  }
}
