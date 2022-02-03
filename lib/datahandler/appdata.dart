import 'package:flutter/cupertino.dart';
import 'package:taxi_rider_app/models/history.dart';

import '/models/address.dart';

class AppData extends ChangeNotifier {
  late Address? pickUpLocation = null;
  late Address? dropOffLocation = null;

  String earnings = "0";
  int tripCounter = 0;
  List<String> tripHistoryKeys = [];
  List<History> tripHistoryDataList = [];

  void updatePickUpLocationAddress(Address pickUpAddress) {
    pickUpLocation = pickUpAddress;
    notifyListeners();
  }

  void updateDropOffLocationAddress(Address dropOffAddress) {
    dropOffLocation = dropOffAddress;
    notifyListeners();
  }

  void updateEarnings(String updatedEarnings) {
    earnings = updatedEarnings;
    notifyListeners();
  }

  void updateTripsCounter(int tripsCounter) {
    tripCounter = tripsCounter;
    notifyListeners();
  }

  void updateTripKeys(List<String> newKeys) {
    tripHistoryKeys = newKeys;
    notifyListeners();
  }

  void updateTripData(History eachHistory) {
    tripHistoryDataList.add(eachHistory);
    notifyListeners();
  }
}
