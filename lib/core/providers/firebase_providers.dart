import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firebaseDatabaseProvider = Provider<FirebaseDatabase>(
  (ref) => FirebaseDatabase.instance,
);

final usersDatabaseRefProvider = Provider<DatabaseReference>(
  (ref) => ref.watch(firebaseDatabaseProvider).ref().child('users'),
);

final driversDatabaseRefProvider = Provider<DatabaseReference>(
  (ref) => ref.watch(firebaseDatabaseProvider).ref().child('drivers'),
);

final rideRequestsDatabaseRefProvider = Provider<DatabaseReference>(
  (ref) => ref.watch(firebaseDatabaseProvider).ref().child('rideRequests'),
);
