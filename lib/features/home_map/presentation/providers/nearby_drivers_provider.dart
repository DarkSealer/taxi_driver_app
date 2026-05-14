import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taxi_rider_app/models/nearby_available_drivers.dart';

/// In-memory list of nearby drivers from Geofire (presentation + map layer).
class NearbyDriversNotifier extends StateNotifier<List<NearbyAvailableDrivers>> {
  NearbyDriversNotifier() : super(const []);

  void onKeyEntered(NearbyAvailableDrivers driver) {
    state = [...state, driver];
  }

  void onKeyExited(String key) {
    final idx = state.indexWhere((e) => e.key == key);
    if (idx < 0) {
      return;
    }
    final next = [...state]..removeAt(idx);
    state = next;
  }

  void onKeyMoved(NearbyAvailableDrivers driver) {
    final idx = state.indexWhere((e) => e.key == driver.key);
    if (idx < 0) {
      state = [...state, driver];
      return;
    }
    final next = [...state];
    next[idx] = driver;
    state = next;
  }

  void clear() {
    state = const [];
  }
}

final nearbyDriversProvider =
    StateNotifierProvider<NearbyDriversNotifier, List<NearbyAvailableDrivers>>(
  (ref) => NearbyDriversNotifier(),
);
