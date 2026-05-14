import 'package:taxi_rider_app/core/result/result.dart';
import 'package:taxi_rider_app/models/direction_details.dart';

abstract class DirectionsRepository {
  Future<AppResult<DirectionDetails>> getRoute({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  });
}
