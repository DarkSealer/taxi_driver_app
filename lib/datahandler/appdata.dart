import 'package:flutter/cupertino.dart';

import '/models/address.dart';

class AppData extends ChangeNotifier {
  late Address? pickUpLocation = null;
  late Address? dropOffLocation = null;

  void updatePickUpLocationAddress(Address pickUpAddress) {
    pickUpLocation = pickUpAddress;
    notifyListeners();
  }

  void updateDropOffLocationAddress(Address dropOffAddress) {
    dropOffLocation = dropOffAddress;
    notifyListeners();
  }
}
