import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:taxi_rider_app/core/config/app_config.dart';
import 'package:taxi_rider_app/core/error/failures.dart';
import 'package:taxi_rider_app/core/result/result.dart';
import 'package:taxi_rider_app/features/places_directions/domain/repositories/geocoding_repository.dart';
import 'package:taxi_rider_app/models/address.dart';

class GeocodingRepositoryImpl implements GeocodingRepository {
  GeocodingRepositoryImpl(this._config, this._client);

  final AppConfig _config;
  final http.Client _client;

  @override
  Future<AppResult<Address>> reverseGeocode(
    double latitude,
    double longitude,
  ) async {
    final keyIssue = _config.validateMapsKey();
    if (keyIssue != null) {
      return FailureResult(keyIssue);
    }
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=${_config.mapsApiKey}';
    try {
      final res = await _client.get(Uri.parse(url));
      if (res.statusCode != 200) {
        return FailureResult(NetworkFailure('Geocode HTTP ${res.statusCode}'));
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) {
        return const FailureResult(ServerFailure('No geocode results'));
      }
      final first = results[0] as Map<String, dynamic>;
      final comps = first['address_components'] as List<dynamic>;
      final st1 = comps.length > 3 ? comps[3]['long_name'] : '';
      final st2 = comps.length > 1 ? comps[1]['long_name'] : '';
      final st3 = comps.length > 5 ? comps[5]['long_name'] : '';
      final placeId = first['place_id'] as String;
      final placeAddress = '$st1, $st2, $st3';
      return Success(
        Address(
          placeFormattedAddress: placeAddress,
          placeName: placeAddress,
          placeId: placeId,
          latitude: latitude,
          longitude: longitude,
        ),
      );
    } catch (e) {
      return FailureResult(NetworkFailure('Geocode failed: $e'));
    }
  }
}
