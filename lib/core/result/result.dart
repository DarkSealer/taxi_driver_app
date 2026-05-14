import 'package:taxi_rider_app/core/error/failures.dart';

/// Simple Result type without external dependencies.
sealed class Result<T, E> {
  const Result();

  bool get isSuccess => this is Success<T, E>;
  bool get isFailure => this is FailureResult<T, E>;

  R fold<R>(R Function(E error) onFailure, R Function(T value) onSuccess) {
    final self = this;
    if (self is Success<T, E>) {
      return onSuccess(self.value);
    }
    if (self is FailureResult<T, E>) {
      return onFailure(self.error);
    }
    throw StateError('Unknown Result');
  }
}

final class Success<T, E> extends Result<T, E> {
  const Success(this.value);

  final T value;
}

final class FailureResult<T, E> extends Result<T, E> {
  const FailureResult(this.error);

  final E error;
}

/// Shorthand for app failures.
typedef AppResult<T> = Result<T, Failure>;

extension AppResultX<T> on AppResult<T> {
  T? get valueOrNull => fold((_) => null, (v) => v);
  Failure? get failureOrNull => fold((e) => e, (_) => null);
}
