import 'package:firebase_database/firebase_database.dart';

class History {
  String paymentMethod = '';
  String createdAt = '';
  String status = '';
  String fares = '';
  String dropOff = '';
  String pickUp = '';

  History({
    required this.paymentMethod,
    required this.createdAt,
    required this.status,
    required this.fares,
    required this.dropOff,
    required this.pickUp,
  });

  History.fromSnapshot(DataSnapshot snapshot) {
    var values = snapshot.value as Map<dynamic, dynamic>;
    paymentMethod = values['payment_method'];
    createdAt = values['created_at'];
    status = values['status'];
    fares = values['fares'];
    dropOff = values['dropoff_address'];
    pickUp = values['pickup_address'];
  }
}
