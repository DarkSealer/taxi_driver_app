import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:taxi_rider_app/core/config/app_config.dart';
import 'package:taxi_rider_app/core/providers/app_logger_provider.dart';
import 'package:taxi_rider_app/features/places_directions/presentation/providers/maps_repositories_provider.dart';
import 'package:taxi_rider_app/features/trip_places/presentation/providers/trip_places_provider.dart';
import 'package:taxi_rider_app/models/direction_details.dart';

/// UI helpers and legacy integrations kept behind static methods during migration.
class AssistantMethods {
  AssistantMethods._();

  static Future<String> searchCoordinateAddress(
    WidgetRef ref,
    Position position,
  ) async {
    final repo = ref.read(geocodingRepositoryProvider);
    final result = await repo.reverseGeocode(
      position.latitude,
      position.longitude,
    );
    return result.fold(
      (failure) {
        ref.read(appLoggerProvider).warning(
              failure.message,
              name: 'Geocoding',
            );
        return '';
      },
      (address) {
        ref.read(tripPlacesProvider.notifier).updatePickUpLocation(address);
        return address.placeName;
      },
    );
  }

  static Future<DirectionDetails?> obtainDirectionsDetails(
    WidgetRef ref,
    LatLng initialPosition,
    LatLng finalPosition,
  ) async {
    final repo = ref.read(directionsRepositoryProvider);
    final result = await repo.getRoute(
      originLat: initialPosition.latitude,
      originLng: initialPosition.longitude,
      destLat: finalPosition.latitude,
      destLng: finalPosition.longitude,
    );
    return result.fold(
      (failure) {
        ref.read(appLoggerProvider).warning(
              failure.message,
              name: 'Directions',
            );
        return null;
      },
      (d) => d,
    );
  }

  /// Fare estimate in USD (same heuristic as original demo).
  static int calculateFares(DirectionDetails directionDetails) {
    final timeTraveledFare = (directionDetails.durationValue / 60) * 0.20;
    final distanceTraveledFare =
        (directionDetails.distanceValue / 1000) * 0.20;
    final totalPriceAmount = timeTraveledFare + distanceTraveledFare;
    return totalPriceAmount.truncate();
  }

  static double createRandomNumber(int num) {
    final random = Random();
    return random.nextInt(num).toDouble();
  }

  static Future<void> sendNotificationToDriver(
    String token,
    String rideRequestId,
  ) async {
    if (token.isEmpty) {
      return;
    }
    final header = AppConfig.instance.fcmAuthorizationHeader.trim();
    if (header.isEmpty) {
      return;
    }
    try {
      await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': header,
        },
        body: _constructFCMPayload(token, rideRequestId),
      );
    } catch (_) {
      // FCM request failed; avoid crashing the ride flow.
    }
  }

  static String _constructFCMPayload(String token, String rideRequestId) {
    return jsonEncode({
      'token': token,
      'notification': {
        'body': 'You have a new ride request! Tap here to view in the app.',
        'title': 'New Ride Request',
      },
      'priority': 'high',
      'data': {
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        'id': '1',
        'status': 'done',
        'ride_request_id': rideRequestId,
      },
      'to': token,
    });
  }

  static void displayToastMessage(String msg, BuildContext context) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(
        content: Text(msg),
        action: SnackBarAction(
          label: 'OK',
          onPressed: scaffold.hideCurrentSnackBar,
        ),
      ),
    );
  }

  static String formatTripDate(String date) {
    final dateTime = DateTime.parse(date);
    return '${DateFormat.MMMd().format(dateTime)}, '
        '${DateFormat.y().format(dateTime)} - '
        '${DateFormat.jm().format(dateTime)}';
  }
}
