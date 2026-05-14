import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:taxi_rider_app/assistants/assistant_methods.dart';
import 'package:taxi_rider_app/widgets/progressdialog.dart';

import '../main.dart';
import 'mainscreen.dart';
import 'registerscreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  static const String idScreen = "login";

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailTextEditingController =
      TextEditingController();
  final TextEditingController passwordTextEditingController =
      TextEditingController();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  @override
  void dispose() {
    emailTextEditingController.dispose();
    passwordTextEditingController.dispose();
    super.dispose();
  }

  Future<void> loginUser(BuildContext context) async {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return const ProgressDialog(
          message: "Se autentifica. Va rugam asteptati",
        );
      },
      barrierDismissible: false,
    );

    final UserCredential credential;
    try {
      credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: emailTextEditingController.text,
        password: passwordTextEditingController.text,
      );
    } catch (errMsg) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      AssistantMethods.displayToastMessage("Error: $errMsg", context);
      return;
    }

    final firebaseUser = credential.user;
    if (firebaseUser != null) {
      await userRef.child(firebaseUser.uid).get().then((DataSnapshot snap) {
        if (snap.value != null) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            MainScreen.idScreen,
            (route) => false,
          );

          AssistantMethods.displayToastMessage(
            "Sunteti conectact la contul dvs.",
            context,
          );
          return;
        }

        Navigator.pop(context);
        _firebaseAuth.signOut();
        AssistantMethods.displayToastMessage(
          "Acest utilizator nu exista in baza de date",
          context,
        );
      });
      return;
    }

    Navigator.pop(context);
    AssistantMethods.displayToastMessage(
      "Va rugam sa verificati credentialele dvs si sa incercati din nou.",
      context,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
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
                      final bool emailValid = RegExp(
                        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
                      ).hasMatch(emailTextEditingController.text);
                      if (!emailValid) {
                        AssistantMethods.displayToastMessage(
                          "Te rugam sa introduci o adresa de email valida.",
                          context,
                        );
                        return;
                      } else if (passwordTextEditingController.text.isEmpty) {
                        AssistantMethods.displayToastMessage(
                          "Te rugam sa introduci o parola valida.",
                          context,
                        );
                        return;
                      }

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
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  RegisterScreen.idScreen,
                  (route) => false,
                );
              },
              child: const SizedBox(
                height: 50,
                child: Center(
                  child: Text(
                    "Nu ai cont? Inregistreaza-te aici.",
                    style: TextStyle(
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
}
