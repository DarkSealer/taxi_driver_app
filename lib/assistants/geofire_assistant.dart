import 'package:taxi_rider_app/models/nearby_available_drivers.dart';

class GeofireAssistant {
  static List<NearbyAvailableDrivers> nearbyAvailableDriversList = [];

  static void removeDriverFromList(String key) {
    int index =
        nearbyAvailableDriversList.indexWhere((element) => element.key == key);

    nearbyAvailableDriversList.removeAt(index);
  }

  static void updateDriverNearbyLocation(NearbyAvailableDrivers driver) {
    int index = nearbyAvailableDriversList
        .indexWhere((element) => element.key == driver.key);

    nearbyAvailableDriversList[index].longitude = driver.longitude;
    nearbyAvailableDriversList[index].latitude = driver.latitude;
  }
}
