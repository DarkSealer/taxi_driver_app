import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_geofire/flutter_geofire.dart';

import '/main.dart';
import '/screens/loginscreen.dart';
import '/configmaps.dart';
import 'mainscreen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black87,
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                userCurrentInfo!.name,
                style: const TextStyle(
                  fontSize: 65,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Signatra',
                ),
              ),
              const SizedBox(
                height: 20,
                width: 200,
                child: Divider(
                  color: Colors.white,
                ),
              ),
              const SizedBox(
                height: 40,
              ),
              InfoCard(
                text: userCurrentInfo!.phone,
                icon: Icons.phone,
                onPressed: () {
                  print('this is phone');
                },
              ),
              InfoCard(
                text: userCurrentInfo!.email,
                icon: Icons.email,
                onPressed: () {
                  print('this is email');
                },
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
                    color: Colors.white,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
        ));
  }
}

class InfoCard extends StatelessWidget {
  final String text;
  final IconData icon;
  Function onPressed;
  InfoCard(
      {Key? key,
      required this.text,
      required this.icon,
      required this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed(),
      child: Card(
        color: Colors.white,
        margin: const EdgeInsets.symmetric(
          horizontal: 25,
          vertical: 10,
        ),
        child: ListTile(
          leading: Icon(
            icon,
            color: Colors.black87,
          ),
          title: Text(
            text,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 16,
              fontFamily: 'Brand',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
