import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taxi_rider_app/core/config/app_config.dart';

final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig.instance,
);
