import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        children: [
          SizedBox(
            height: 220,
            child: Center(
              child: Image.asset('images/uberx.png'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 30, left: 24, right: 24),
            child: Column(
              children: [
                const Text(
                  'App Name',
                  style: TextStyle(
                    fontSize: 90,
                    fontFamily: 'Signatra',
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'This app has been developed by Geek-Tec, '
                  'a romanian tech company focused on developing mobile apps '
                  'for businesses all around the world.',
                  style: TextStyle(
                    fontFamily: 'Brand',
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                TextButton(
                  onPressed: () => context.go('/home'),
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Go Back',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                    ),
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
