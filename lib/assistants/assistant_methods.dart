import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:taxi_rider_app/main.dart';
import 'package:taxi_rider_app/models/history.dart';

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
      st3 = response["results"][0]["address_components"][5]
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

    print("This little shit failed");

    return placeAddress;
  }

  static Future<DirectionDetails?> obtainDirectionsDetails(
      LatLng initialPosition, LatLng finalPosition) async {
    String directionUrl =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${initialPosition.latitude},${initialPosition.longitude}&destination=${finalPosition.latitude},${finalPosition.longitude}&key=$mapKey";

    var res = await RequestAssistant.getRequest(directionUrl);

    if (res == "failed") {
      print("This shit failed");
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
    firebaseUser = (await FirebaseAuth.instance.currentUser)!;
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

  static Future<void> sendNotificationToDriver(
    String token,
    context,
    String ride_request_id,
  ) async {
    var destination =
        Provider.of<AppData>(context, listen: false).dropOffLocation;

    if (token == null) {
      print('Unable to send FCM message, no token exists.');
      return;
    }

    try {
      await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': serverToken,
        },
        body: constructFCMPayload(token, ride_request_id),
      );
      print('FCM request for device sent!');
    } catch (e) {
      print(e);
    }
  }

  static String constructFCMPayload(String token, String rideRequestId) {
    var res = jsonEncode({
      'token': token,
      'notification': {
        "body": "You have a new ride request! Tap here to view in the app.",
        "title": "New Ride Request"
      },
      "priority": "high",
      'data': {
        "click_action": "FLUTTER_NOTIFIATION_CLICK",
        "id": "1",
        "status": "done",
        "ride_request_id": rideRequestId,
      },
      'to': token,
    });

    print(res.toString());
    return res;
  }

  static void displayToastMessage(String msg, BuildContext context) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(
        content: Text(msg),
        action: SnackBarAction(
            label: 'OK', onPressed: scaffold.hideCurrentSnackBar),
      ),
    );
  }

  static String formatTripDate(String date) {
    DateTime dateTime = DateTime.parse(date);
    String formattedDate =
        '${DateFormat.MMMd().format(dateTime)}, ${DateFormat.y().format(dateTime)} - ${DateFormat.jm().format(dateTime)}';
    return formattedDate;
  }

  static void retrieveHistoryInfo(context) {
    // retrieve and display Trip History
    // sorteaza istoricum clientului dupa nume
    print('IN Retrieve History Info');
    newRequestRef.orderByChild('rider_name').get().then((snap) {
      // update total number of trip counts to provider
      if (snap.value != null) {
        Map<dynamic, dynamic> keys = snap.value as Map<dynamic, dynamic>;
        int tripCounter = keys.length;
        Provider.of<AppData>(context, listen: false)
            .updateTripsCounter(tripCounter);

        // update trip keys to provider
        List<String> tripHistoryKeys = [];
        keys.forEach((key, value) {
          tripHistoryKeys.add(key);
        });
        Provider.of<AppData>(context, listen: false)
            .updateTripKeys(tripHistoryKeys);
        obtainTripRequestHistoryData(context);
      }
    });
  }

  // TODO - De modificat modul de verificare al istoricului pentru user ASAP
  static void obtainTripRequestHistoryData(context) {
    var keys = Provider.of<AppData>(context, listen: false).tripHistoryKeys;

    print('In ObtainTraipRequestHistory');
    for (String key in keys) {
      newRequestRef.child(key).get().then((snap) {
        if (snap.value != null) {
          newRequestRef.child(key).child('rider_name').get().then((snapshot) {
            String name = snapshot.value.toString();

            if (name == userCurrentInfo!.name) {
              var history = History.fromSnapshot(snap);
              Provider.of<AppData>(context, listen: false)
                  .updateTripData(history);
            }
          });
        }
      });
    }
  }
}
