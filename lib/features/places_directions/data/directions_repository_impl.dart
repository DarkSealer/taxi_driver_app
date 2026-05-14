import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:taxi_rider_app/core/config/app_config.dart';
import 'package:taxi_rider_app/core/error/failures.dart';
import 'package:taxi_rider_app/core/result/result.dart';
import 'package:taxi_rider_app/features/places_directions/domain/repositories/directions_repository.dart';
import 'package:taxi_rider_app/models/direction_details.dart';

class DirectionsRepositoryImpl implements DirectionsRepository {
  DirectionsRepositoryImpl(this._config, this._client);

  final AppConfig _config;
  final http.Client _client;

  @override
  Future<AppResult<DirectionDetails>> getRoute({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    final keyIssue = _config.validateMapsKey();
    if (keyIssue != null) {
      return FailureResult(keyIssue);
    }
    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=$originLat,$originLng&destination=$destLat,$destLng&key=${_config.mapsApiKey}';
    try {
      final res = await _client.get(Uri.parse(url));
      if (res.statusCode != 200) {
        return FailureResult(NetworkFailure('Directions HTTP ${res.statusCode}'));
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['routes'] == null || (data['routes'] as List).isEmpty) {
        return const FailureResult(ServerFailure('No routes returned'));
      }
      final leg = data['routes'][0]['legs'][0] as Map<String, dynamic>;
      final details = DirectionDetails(
        distanceValue: leg['distance']['value'] as int,
        durationValue: leg['duration']['value'] as int,
        distanceText: leg['distance']['text'] as String,
        durationText: leg['duration']['text'] as String,
        encodedPoints:
            data['routes'][0]['overview_polyline']['points'] as String,
      );
      return Success(details);
    } catch (e) {
      return FailureResult(NetworkFailure('Directions request failed: $e'));
    }
  }
}
