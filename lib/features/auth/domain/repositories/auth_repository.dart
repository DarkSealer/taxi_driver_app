import 'package:firebase_auth/firebase_auth.dart';
import 'package:taxi_rider_app/core/result/result.dart';
import 'package:taxi_rider_app/features/auth/domain/entities/app_user.dart';

abstract class AuthRepository {
  User? get currentUser;

  Future<AppResult<UserCredential>> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AppResult<UserCredential>> registerWithEmail({
    required String email,
    required String password,
  });

  Future<void> signOut();
}

abstract class UserProfileRepository {
  Future<AppResult<bool>> profileExists(String uid);

  Future<AppResult<AppUser?>> fetchProfile(String uid);

  Future<AppResult<void>> saveProfile(String uid, AppUserDraft draft);
}
