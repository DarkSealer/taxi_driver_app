import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taxi_rider_app/core/providers/app_logger_provider.dart';
import 'package:taxi_rider_app/core/providers/firebase_providers.dart';
import 'package:taxi_rider_app/features/auth/presentation/providers/current_user_provider.dart';
import 'package:taxi_rider_app/features/trip_places/presentation/providers/trip_places_provider.dart';
import 'package:taxi_rider_app/models/history.dart';

/// Loads trip history keys and rows for the signed-in rider (legacy RTDB shape).
Future<void> syncTripHistoryForCurrentUser(WidgetRef ref) async {
  final user = ref.read(currentUserProvider);
  if (user == null) {
    return;
  }
  final log = ref.read(appLoggerProvider);
  final newRequestRef = ref.read(rideRequestsDatabaseRefProvider);
  final DataSnapshot snap;
  try {
    snap = await newRequestRef.orderByChild('rider_name').get();
  } catch (e, st) {
    log.warning(
      'Trip history query failed',
      error: '$e\n$st',
      name: 'TripHistory',
    );
    return;
  }
  if (!snap.exists || snap.value == null) {
    return;
  }
  final keys = Map<dynamic, dynamic>.from(snap.value! as Map);
  final tripCounter = keys.length;
  ref.read(tripPlacesProvider.notifier).updateTripsCounter(tripCounter);
  final tripHistoryKeys = keys.keys.map((e) => e.toString()).toList();
  ref.read(tripPlacesProvider.notifier).updateTripKeys(tripHistoryKeys);
  for (final key in tripHistoryKeys) {
    try {
      final rideSnap = await newRequestRef.child(key).get();
      if (!rideSnap.exists || rideSnap.value == null) {
        continue;
      }
      final nameSnap =
          await newRequestRef.child(key).child('rider_name').get();
      final name = nameSnap.value?.toString() ?? '';
      if (name == user.name) {
        final history = History.fromSnapshot(rideSnap);
        ref.read(tripPlacesProvider.notifier).updateTripData(history);
      }
    } catch (e) {
      log.warning('Trip history row failed for $key', error: e);
    }
  }
}
