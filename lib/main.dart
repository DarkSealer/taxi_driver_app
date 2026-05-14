import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taxi_rider_app/app/app.dart';
import 'package:taxi_rider_app/core/config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.load();
  await Firebase.initializeApp();
  runApp(
    const ProviderScope(
      child: TaxiRiderApp(),
    ),
  );
}
