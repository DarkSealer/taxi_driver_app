import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:taxi_rider_app/core/providers/app_config_provider.dart';
import 'package:taxi_rider_app/features/places_directions/data/directions_repository_impl.dart';
import 'package:taxi_rider_app/features/places_directions/data/geocoding_repository_impl.dart';
import 'package:taxi_rider_app/features/places_directions/data/places_repository_impl.dart';
import 'package:taxi_rider_app/features/places_directions/domain/repositories/directions_repository.dart';
import 'package:taxi_rider_app/features/places_directions/domain/repositories/geocoding_repository.dart';
import 'package:taxi_rider_app/features/places_directions/domain/repositories/places_repository.dart';

final httpClientProvider = Provider<http.Client>(
  (ref) {
    final client = http.Client();
    ref.onDispose(client.close);
    return client;
  },
);

final geocodingRepositoryProvider = Provider<GeocodingRepository>(
  (ref) => GeocodingRepositoryImpl(
    ref.watch(appConfigProvider),
    ref.watch(httpClientProvider),
  ),
);

final directionsRepositoryProvider = Provider<DirectionsRepository>(
  (ref) => DirectionsRepositoryImpl(
    ref.watch(appConfigProvider),
    ref.watch(httpClientProvider),
  ),
);

final placesRepositoryProvider = Provider<PlacesRepository>(
  (ref) => PlacesRepositoryImpl(
    ref.watch(appConfigProvider),
    ref.watch(httpClientProvider),
  ),
);
