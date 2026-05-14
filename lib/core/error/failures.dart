/// User-visible or loggable failure in the domain / application layer.
sealed class Failure {
  const Failure(this.message);

  final String message;

  @override
  String toString() => message;
}

final class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

final class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

final class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

final class ConfigFailure extends Failure {
  const ConfigFailure(super.message);
}
