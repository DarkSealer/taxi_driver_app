import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taxi_rider_app/models/address.dart';
import 'package:taxi_rider_app/models/history.dart';

class TripPlacesState {
  const TripPlacesState({
    this.pickUpLocation,
    this.dropOffLocation,
    this.earnings = '0',
    this.tripCounter = 0,
    this.tripHistoryKeys = const [],
    this.tripHistoryDataList = const [],
  });

  final Address? pickUpLocation;
  final Address? dropOffLocation;
  final String earnings;
  final int tripCounter;
  final List<String> tripHistoryKeys;
  final List<History> tripHistoryDataList;

  TripPlacesState copyWith({
    Address? pickUpLocation,
    Address? dropOffLocation,
    String? earnings,
    int? tripCounter,
    List<String>? tripHistoryKeys,
    List<History>? tripHistoryDataList,
    bool clearPickUp = false,
    bool clearDropOff = false,
  }) {
    return TripPlacesState(
      pickUpLocation: clearPickUp ? null : (pickUpLocation ?? this.pickUpLocation),
      dropOffLocation:
          clearDropOff ? null : (dropOffLocation ?? this.dropOffLocation),
      earnings: earnings ?? this.earnings,
      tripCounter: tripCounter ?? this.tripCounter,
      tripHistoryKeys: tripHistoryKeys ?? this.tripHistoryKeys,
      tripHistoryDataList: tripHistoryDataList ?? this.tripHistoryDataList,
    );
  }
}

class TripPlacesNotifier extends StateNotifier<TripPlacesState> {
  TripPlacesNotifier() : super(const TripPlacesState());

  void updatePickUpLocation(Address address) {
    state = state.copyWith(pickUpLocation: address);
  }

  void updateDropOffLocation(Address address) {
    state = state.copyWith(dropOffLocation: address);
  }

  void updateEarnings(String updatedEarnings) {
    state = state.copyWith(earnings: updatedEarnings);
  }

  void updateTripsCounter(int tripsCounter) {
    state = state.copyWith(tripCounter: tripsCounter);
  }

  void updateTripKeys(List<String> newKeys) {
    state = state.copyWith(tripHistoryKeys: newKeys, tripHistoryDataList: []);
  }

  void updateTripData(History eachHistory) {
    state = state.copyWith(
      tripHistoryDataList: [...state.tripHistoryDataList, eachHistory],
    );
  }

  void clearTripHistory() {
    state = state.copyWith(tripHistoryKeys: [], tripHistoryDataList: []);
  }
}

final tripPlacesProvider =
    StateNotifierProvider<TripPlacesNotifier, TripPlacesState>((ref) {
  return TripPlacesNotifier();
});
