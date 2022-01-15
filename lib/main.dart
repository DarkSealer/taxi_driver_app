import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/screens/mainscreen.dart';
import '/screens/loginscreen.dart';
import '/screens/registerscreen.dart';
import 'datahandler/appdata.dart';

DatabaseReference userRef = FirebaseDatabase.instance.ref();

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
        initialRoute: MainScreen.idScreen,
        routes: {
          MainScreen.idScreen: (context) => const MainScreen(),
          RegisterScreen.idScreen: (context) => RegisterScreen(),
          LoginScreen.idScreen: (context) => LoginScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
