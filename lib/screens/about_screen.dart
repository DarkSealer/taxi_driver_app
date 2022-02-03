import 'package:flutter/material.dart';
import 'package:taxi_rider_app/screens/mainscreen.dart';

class AboutScreen extends StatefulWidget {
  static const String idScreen = 'about';
  const AboutScreen({Key? key}) : super(key: key);

  @override
  _AboutScreenState createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        children: [
          Container(
            height: 220,
            child: Center(
              child: Image.asset('images/uberx.png'),
            ),
          ),
          // app name + info about you / company

          Padding(
            padding: const EdgeInsets.only(
              top: 30,
              left: 24,
              right: 24,
            ),
            child: Column(
              children: [
                const Text(
                  'App Name',
                  style: TextStyle(
                    fontSize: 90,
                    fontFamily: 'Signatra',
                  ),
                ),
                const SizedBox(
                  height: 30,
                ),
                const Text(
                  'This app has been developed by Geek-Tec, '
                  'a romanian tech company focused on developing mobile apps '
                  'for businesses all around the world.',
                  style: TextStyle(
                      fontFamily: 'Brand', fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(
                  height: 40,
                ),
                FlatButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                        context, MainScreen.idScreen, (route) => false);
                  },
                  child: const Text(
                    'Go Back',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
