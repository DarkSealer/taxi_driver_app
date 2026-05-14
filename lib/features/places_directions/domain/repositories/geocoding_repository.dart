import 'package:taxi_rider_app/core/result/result.dart';
import 'package:taxi_rider_app/models/address.dart';

abstract class GeocodingRepository {
  Future<AppResult<Address>> reverseGeocode(double latitude, double longitude);
}
