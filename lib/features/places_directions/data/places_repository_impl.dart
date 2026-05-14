import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:taxi_rider_app/core/config/app_config.dart';
import 'package:taxi_rider_app/core/error/failures.dart';
import 'package:taxi_rider_app/core/result/result.dart';
import 'package:taxi_rider_app/features/places_directions/domain/repositories/places_repository.dart';
import 'package:taxi_rider_app/models/address.dart';
import 'package:taxi_rider_app/models/place_predictions.dart';

class PlacesRepositoryImpl implements PlacesRepository {
  PlacesRepositoryImpl(this._config, this._client);

  final AppConfig _config;
  final http.Client _client;

  @override
  Future<AppResult<List<PlacePredictions>>> autocomplete(String input) async {
    final keyIssue = _config.validateMapsKey();
    if (keyIssue != null) {
      return FailureResult(keyIssue);
    }
    if (input.length < 2) {
      return const Success([]);
    }
    final encoded = Uri.encodeComponent(input);
    final url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$encoded&language=${_config.placesLanguage}&types=geocode&key=${_config.mapsApiKey}&components=country:ro';
    try {
      final res = await _client.get(Uri.parse(url));
      if (res.statusCode != 200) {
        return FailureResult(NetworkFailure('Places HTTP ${res.statusCode}'));
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['status'] != 'OK') {
        return const Success([]);
      }
      final predictions = data['predictions'] as List<dynamic>? ?? [];
      final list = predictions
          .map((e) => PlacePredictions.fromJson(e as Map<String, dynamic>))
          .toList();
      return Success(list);
    } catch (e) {
      return FailureResult(NetworkFailure('Autocomplete failed: $e'));
    }
  }

  @override
  Future<AppResult<Address>> placeDetails(String placeId) async {
    final keyIssue = _config.validateMapsKey();
    if (keyIssue != null) {
      return FailureResult(keyIssue);
    }
    final url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=${_config.mapsApiKey}';
    try {
      final res = await _client.get(Uri.parse(url));
      if (res.statusCode != 200) {
        return FailureResult(NetworkFailure('Place details HTTP ${res.statusCode}'));
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['status'] != 'OK') {
        return const FailureResult(ServerFailure('Place details not OK'));
      }
      final result = data['result'] as Map<String, dynamic>;
      final loc = result['geometry']['location'] as Map<String, dynamic>;
      final address = Address(
        placeId: placeId,
        placeFormattedAddress: result['formatted_address'] as String,
        placeName: '${result['name'] ?? result['formatted_address']}',
        latitude: (loc['lat'] as num).toDouble(),
        longitude: (loc['lng'] as num).toDouble(),
      );
      return Success(address);
    } catch (e) {
      return FailureResult(NetworkFailure('Place details failed: $e'));
    }
  }
}
