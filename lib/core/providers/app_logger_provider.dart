import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taxi_rider_app/core/logging/app_logger.dart';

final appLoggerProvider = Provider<AppLogger>(
  (ref) => const DeveloperAppLogger(),
);
