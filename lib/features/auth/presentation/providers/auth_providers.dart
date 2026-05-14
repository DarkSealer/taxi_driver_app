import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taxi_rider_app/core/providers/firebase_providers.dart';
import 'package:taxi_rider_app/features/auth/data/firebase_auth_repository.dart';
import 'package:taxi_rider_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:taxi_rider_app/features/auth/domain/usecases/sign_in_with_email_usecase.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseAuthRepository(FirebaseAuth.instance),
);

final userProfileRepositoryProvider = Provider<UserProfileRepository>(
  (ref) => FirebaseUserProfileRepository(ref.watch(usersDatabaseRefProvider)),
);

final signInWithEmailUseCaseProvider = Provider<SignInWithEmailUseCase>(
  (ref) => SignInWithEmailUseCase(
    ref.watch(authRepositoryProvider),
    ref.watch(userProfileRepositoryProvider),
  ),
);

final registerPassengerUseCaseProvider = Provider<RegisterPassengerUseCase>(
  (ref) => RegisterPassengerUseCase(
    ref.watch(authRepositoryProvider),
    ref.watch(userProfileRepositoryProvider),
  ),
);
