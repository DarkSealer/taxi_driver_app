import 'package:flutter/material.dart';

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
              onPressed: () {},
            ),
            InfoCard(
              text: userCurrentInfo!.email,
              icon: Icons.email,
              onPressed: () {},
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  MainScreen.idScreen,
                  (route) => false,
                );
              },
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Go Back',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;

  const InfoCard({
    Key? key,
    required this.text,
    required this.icon,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
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
