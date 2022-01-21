import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '/widgets/progressDialog.dart';

import '../main.dart';
import 'registerscreen.dart';
import 'mainscreen.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({Key? key}) : super(key: key);

  static const String idScreen = "login";

  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        // width: double.infinity,
        child: Column(
          children: <Widget>[
            const SizedBox(
              height: 35,
            ),
            const Image(
              image: AssetImage("images/logo.png"),
              width: 390,
              height: 250,
              alignment: Alignment.center,
            ),
            const SizedBox(
              height: 1,
            ),
            const Text(
              "Autentificare ca Pasager",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontFamily: "Bolt",
                fontWeight: FontWeight.w900,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: <Widget>[
                  const SizedBox(
                    height: 1,
                  ),
                  TextField(
                    controller: emailTextEditingController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: "Email",
                      labelStyle: TextStyle(
                        fontSize: 14,
                      ),
                      hintStyle: TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),
                  TextField(
                    controller: passwordTextEditingController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Parola",
                      labelStyle: TextStyle(
                        fontSize: 14,
                      ),
                      hintStyle: TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(
                    height: 20.0,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // print("Login Clicked");

                      // check the fields
                      bool emailValid = RegExp(
                              r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                          .hasMatch(emailTextEditingController.text);
                      if (!emailValid) {
                        displayToastMessage(
                          "Te rugam sa introduci o adresa de email valida.",
                          context,
                        );
                        return;
                      } else if (passwordTextEditingController.text.isEmpty) {
                        displayToastMessage(
                          "Te rugam sa introduci o parola valida.",
                          context,
                        );
                        return;
                      }

                      // call login method
                      loginUser(context);
                    },
                    child: const SizedBox(
                      height: 50,
                      child: Center(
                        child: Text(
                          "Autentificare",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontFamily: "Bold",
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                // print("Register Clicked");
                Navigator.pushNamedAndRemoveUntil(
                    context, RegisterScreen.idScreen, (route) => false);
              },
              child: const SizedBox(
                height: 50,
                child: Center(
                  child: Text(
                    "Nu ai cont? Inregistreaza-te aici.",
                    style: TextStyle(
                      // color: Colors.white,
                      fontSize: 16,
                      fontFamily: "Bold",
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  final _firebaseAuth = FirebaseAuth.instance;

  void loginUser(BuildContext context) async {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return ProgressDialog(message: "Se autentifica. Va rugam asteptati");
        },
        barrierDismissible: false);

    final firebaseUser = (await _firebaseAuth
            .signInWithEmailAndPassword(
      email: emailTextEditingController.text,
      password: passwordTextEditingController.text,
    )
            .catchError((errMsg) {
      Navigator.pop(context); // close the loading widget
      displayToastMessage("Error: $errMsg", context);
    }))
        .user;

    if (firebaseUser != null) // user logged in
    {
      print("User connected");

      //     await userRef.once().then((DataSnapshot snapshot) {
      //   print('Data : ${snapshot.value}');
      // });

      await userRef
          .child("users")
          .child(firebaseUser.uid)
          .get()
          .then((DataSnapshot snap) {
        if (snap.value != null) {
          Navigator.pushNamedAndRemoveUntil(
              context, MainScreen.idScreen, (route) => false);

          // afiseaza mesaj de autentificare
          displayToastMessage("Sunteti conectact la contul dvs.", context);
          return;
        }

        Navigator.pop(context);
        _firebaseAuth.signOut();
        displayToastMessage(
            "Acest utilizator nu exista in baza de date", context);
      });
      return;
    }

    Navigator.pop(context);
    // error occured - display error message
    displayToastMessage(
        "Va rugam sa verificati credentialele dvs si sa incercati din nou.",
        context);
    // displayToastMessage(
    // "A aparut o eroare. Va rugam sa incercati din nou",
    // context);
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
