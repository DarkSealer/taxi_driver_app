import 'package:taxi_rider_app/core/error/failures.dart';

/// Runtime configuration from `--dart-define` (never commit real values).
///
/// Example:
/// `flutter run --dart-define=MAPS_API_KEY=your_key --dart-define=FCM_AUTH_HEADER=key=your_server_key`
class AppConfig {
  AppConfig._({
    required this.mapsApiKey,
    required this.fcmAuthorizationHeader,
    required this.placesLanguage,
  });

  /// Google Maps / Places / Directions web API key.
  final String mapsApiKey;

  /// Value for HTTP `Authorization` when calling legacy FCM HTTP v1 sender
  /// (e.g. `key=AAAA...`). Prefer migrating to FCM v1 API with OAuth2.
  final String fcmAuthorizationHeader;

  /// Places autocomplete language (e.g. `ro`).
  final String placesLanguage;

  static AppConfig? _instance;

  static AppConfig get instance {
    final i = _instance;
    if (i == null) {
      throw StateError('AppConfig.load() must be called before runApp');
    }
    return i;
  }

  /// Call once from `main()` before `runApp`.
  static void load() {
    _instance = AppConfig._(
      mapsApiKey: const String.fromEnvironment(
        'MAPS_API_KEY',
        defaultValue: '',
      ),
      fcmAuthorizationHeader: const String.fromEnvironment(
        'FCM_AUTH_HEADER',
        defaultValue: '',
      ),
      placesLanguage: const String.fromEnvironment(
        'PLACES_LANGUAGE',
        defaultValue: 'ro',
      ),
    );
  }

  /// Ensures maps key is present for geocoding / directions / places.
  Failure? validateMapsKey() {
    if (mapsApiKey.trim().isEmpty) {
      return const ConfigFailure(
        'Missing MAPS_API_KEY. Run with '
        '--dart-define=MAPS_API_KEY=your_key (see README).',
      );
    }
    return null;
  }
}
