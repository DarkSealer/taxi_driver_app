import 'package:flutter/cupertino.dart';

import '/models/address.dart';

class AppData extends ChangeNotifier {
  late Address? pickUpLocation = null;

  void updatePickUpLocationAddress(Address pickupAddress) {
    pickUpLocation = pickupAddress;
    notifyListeners();
  }
}
