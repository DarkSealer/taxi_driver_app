import 'dart:developer' as developer;

/// Thin wrapper so logging can be mocked or filtered in tests.
abstract class AppLogger {
  void debug(String message, {String? name});

  void warning(String message, {String? name, Object? error});
}

class DeveloperAppLogger implements AppLogger {
  const DeveloperAppLogger();

  @override
  void debug(String message, {String? name}) {
    developer.log(message, name: name ?? 'App');
  }

  @override
  void warning(String message, {String? name, Object? error}) {
    developer.log(
      message,
      name: name ?? 'App',
      error: error,
      level: 900,
    );
  }
}
