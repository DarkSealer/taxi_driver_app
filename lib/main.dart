import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taxi_rider_app/screens/about_screen.dart';

import '/screens/mainscreen.dart';
import '/screens/loginscreen.dart';
import '/screens/registerscreen.dart';
import 'datahandler/appdata.dart';

DatabaseReference userRef = FirebaseDatabase.instance.ref().child("users");
DatabaseReference driversRef = FirebaseDatabase.instance.ref().child("drivers");
DatabaseReference newRequestRef =
    FirebaseDatabase.instance.ref().child("rideRequests");

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppData(),
      child: MaterialApp(
        title: 'Taxi Rider App',
        theme: ThemeData(
          fontFamily: "Bolt",
          primarySwatch: Colors.blue,
        ),
        initialRoute: FirebaseAuth.instance.currentUser == null
            ? LoginScreen.idScreen
            : MainScreen.idScreen,
        routes: {
          MainScreen.idScreen: (context) => const MainScreen(),
          RegisterScreen.idScreen: (context) => const RegisterScreen(),
          LoginScreen.idScreen: (context) => const LoginScreen(),
          AboutScreen.idScreen: (context) => const AboutScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }

  void displayToastMessage(String msg, BuildContext context) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(
        content: Text(msg),
        action: SnackBarAction(
            label: 'OK', onPressed: scaffold.hideCurrentSnackBar),
      ),
    );
  }
}
