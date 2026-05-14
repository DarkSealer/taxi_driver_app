/// High-level ride status from Realtime Database (legacy string values).
enum RidePhase {
  idle,
  searching,
  accepted,
  onRide,
  arrived,
  ended,
  unknown,
}

RidePhase ridePhaseFromStatus(String? raw) {
  switch (raw) {
    case '':
    case null:
      return RidePhase.idle;
    case 'accepted':
      return RidePhase.accepted;
    case 'onride':
      return RidePhase.onRide;
    case 'arrived':
      return RidePhase.arrived;
    case 'ended':
      return RidePhase.ended;
    default:
      return RidePhase.unknown;
  }
}
