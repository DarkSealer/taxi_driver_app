import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '/datahandler/appdata.dart';
import '/models/address.dart';
import '/models/all_users.dart';
import '/models/direction_details.dart';

import '/assistants/requestassistant.dart';
import '/configmaps.dart';

class AssistantMethods {
  // decode the coordinate into a readable address
  static Future<String> searchCoordinateAddress(
      Position position, context) async {
    String placeAddress = "";
    String st1, st2, st3, placeId;
    String url =
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$mapKey";

    var response = await RequestAssistant.getRequest(url);

    if (response != "failed") {
      // placeAddress = response["results"][0]["formatted_address"];
      st1 = response["results"][0]["address_components"][3]
          ["long_name"]; // localitate
      st2 = response["results"][0]["address_components"][1]
          ["long_name"]; // strada
      st3 = response["results"][0]["address_components"][6]
          ["long_name"]; // cod postal
      placeId = response["results"][0]["place_id"];
      placeAddress = st1 + ", " + st2 + ", " + st3;

      Address userPickUpAddress = new Address(
          placeFormattedAddress: placeAddress,
          placeName: placeAddress,
          placeId: placeId,
          latitude: position.latitude,
          longitude: position.longitude);

      Provider.of<AppData>(context, listen: false)
          .updatePickUpLocationAddress(userPickUpAddress);
    }

    return placeAddress;
  }

  static Future<DirectionDetails?> obtainDirectionsDetails(
      LatLng initialPosition, LatLng finalPosition) async {
    String directionUrl =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${initialPosition.latitude},${initialPosition.longitude}&destination=${finalPosition.latitude},${finalPosition.longitude}&key=$mapKey";

    var res = await RequestAssistant.getRequest(directionUrl);

    if (res == "failed") {
      return null;
    }

    DirectionDetails directionDetails = DirectionDetails(
      distanceValue: res["routes"][0]["legs"][0]["distance"]["value"],
      durationValue: res["routes"][0]["legs"][0]["duration"]["value"],
      distanceText: res["routes"][0]["legs"][0]["distance"]["text"],
      durationText: res["routes"][0]["legs"][0]["duration"]["text"],
      encodedPoints: res["routes"][0]["overview_polyline"]["points"],
    );

    return directionDetails;
  }

  // TODO - de modificat valoarea initiala (0.20) pentru modificarea pretului
  static int calculateFares(DirectionDetails directionDetails) {
    // in terms of USD
    double timeTraveledFare =
        (directionDetails.durationValue / 60) * 0.20; // 0.20$ / minute
    double distanceTraveledFare =
        (directionDetails.distanceValue / 1000) * 0.20; // 0.20$ / km
    // directionDetails.durationValue * 0.20;

    double totalPriceAmount = timeTraveledFare + distanceTraveledFare;

    // 1$ = 160RS
    //double totalLocalAmount = totalPriceAmount * 160
    return totalPriceAmount.truncate();
  }

  static void getCurrentOnlineUserInfo() async {
    firebaseUser = await FirebaseAuth.instance.currentUser;
    String userId = firebaseUser!.uid;
    DatabaseReference reference =
        FirebaseDatabase.instance.ref().child("users").child(userId);

    reference.once().then((value) {
      if (value.snapshot != null) {
        userCurrentInfo = Users.fromSnapshot(value.snapshot);
      }
    });
  }

  static double createRandomNumber(int num) {
    var random = Random();
    int randNumber = random.nextInt(num);
    return randNumber.toDouble();
  }
}
