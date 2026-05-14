import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class RideSessionUiState {
  const RideSessionUiState({
    this.statusRide = '',
    this.carDetailsDriver = '',
    this.driverName = '',
    this.driverPhone = '',
    this.rideStatusLabel = 'Driver is Coming',
    this.carRideType = '',
    this.driverRequestTimeoutSeconds = 30,
  });

  static const int initialDriverRequestTimeout = 30;

  final String statusRide;
  final String carDetailsDriver;
  final String driverName;
  final String driverPhone;
  final String rideStatusLabel;
  final String carRideType;
  final int driverRequestTimeoutSeconds;

  RideSessionUiState copyWith({
    String? statusRide,
    String? carDetailsDriver,
    String? driverName,
    String? driverPhone,
    String? rideStatusLabel,
    String? carRideType,
    int? driverRequestTimeoutSeconds,
  }) {
    return RideSessionUiState(
      statusRide: statusRide ?? this.statusRide,
      carDetailsDriver: carDetailsDriver ?? this.carDetailsDriver,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      rideStatusLabel: rideStatusLabel ?? this.rideStatusLabel,
      carRideType: carRideType ?? this.carRideType,
      driverRequestTimeoutSeconds:
          driverRequestTimeoutSeconds ?? this.driverRequestTimeoutSeconds,
    );
  }
}

class RideSessionNotifier extends StateNotifier<RideSessionUiState> {
  RideSessionNotifier() : super(const RideSessionUiState());

  void reset() {
    state = const RideSessionUiState();
  }

  void setCarRideType(String type) {
    state = state.copyWith(carRideType: type);
  }

  void setStatusRide(String v) {
    state = state.copyWith(statusRide: v);
  }

  void setDriverDetails({
    String? carDetails,
    String? name,
    String? phone,
    String? rideLabel,
  }) {
    state = state.copyWith(
      carDetailsDriver: carDetails,
      driverName: name,
      driverPhone: phone,
      rideStatusLabel: rideLabel,
    );
  }

  void setRideStatusLabel(String label) {
    state = state.copyWith(rideStatusLabel: label);
  }

  void resetDriverRequestTimeout() {
    state = state.copyWith(
      driverRequestTimeoutSeconds: RideSessionUiState.initialDriverRequestTimeout,
    );
  }

  void decrementDriverRequestTimeout() {
    state = state.copyWith(
      driverRequestTimeoutSeconds: state.driverRequestTimeoutSeconds - 1,
    );
  }
}

final rideSessionProvider =
    StateNotifierProvider<RideSessionNotifier, RideSessionUiState>((ref) {
  return RideSessionNotifier();
});
