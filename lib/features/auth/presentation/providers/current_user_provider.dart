import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taxi_rider_app/core/error/failures.dart';
import 'package:taxi_rider_app/core/result/result.dart';
import 'package:taxi_rider_app/features/auth/domain/entities/app_user.dart';
import 'package:taxi_rider_app/features/auth/presentation/providers/auth_providers.dart';

class CurrentUserNotifier extends StateNotifier<AppUser?> {
  CurrentUserNotifier(this._ref) : super(null);

  final Ref _ref;

  Future<void> loadFromRemote() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      state = null;
      return;
    }
    final repo = _ref.read(userProfileRepositoryProvider);
    final result = await repo.fetchProfile(uid);
    if (result is FailureResult<AppUser?, Failure>) {
      state = null;
      return;
    }
    state = (result as Success<AppUser?, Failure>).value;
  }

  void clear() => state = null;
}

final currentUserProvider =
    StateNotifierProvider<CurrentUserNotifier, AppUser?>((ref) {
  return CurrentUserNotifier(ref);
});
