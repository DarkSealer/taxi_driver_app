import 'package:taxi_rider_app/core/result/result.dart';
import 'package:taxi_rider_app/models/address.dart';
import 'package:taxi_rider_app/models/place_predictions.dart';

abstract class PlacesRepository {
  Future<AppResult<List<PlacePredictions>>> autocomplete(String input);

  Future<AppResult<Address>> placeDetails(String placeId);
}
