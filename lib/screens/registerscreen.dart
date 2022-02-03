import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:taxi_rider_app/assistants/assistant_methods.dart';

import '/main.dart';
import '/screens/mainscreen.dart';
import '/widgets/progressdialog.dart';

import '/screens/loginscreen.dart';

class RegisterScreen extends StatelessWidget {
  RegisterScreen({Key? key}) : super(key: key);

  static const String idScreen = "register";

  TextEditingController nameTextEditingController = TextEditingController();
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController phoneTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

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
              height: 20,
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
              "Inregistreaza un Pasager",
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
                    keyboardType: TextInputType.name,
                    controller: nameTextEditingController,
                    decoration: const InputDecoration(
                      labelText: "Nume",
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
                    keyboardType: TextInputType.emailAddress,
                    controller: emailTextEditingController,
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
                    keyboardType: TextInputType.phone,
                    controller: phoneTextEditingController,
                    decoration: const InputDecoration(
                      labelText: "Telefon",
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
                    obscureText: true,
                    controller: passwordTextEditingController,
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
                      // print("Register Clicked");

                      // check the fields
                      bool emailValid = RegExp(
                              r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                          .hasMatch(emailTextEditingController.text);
                      if (nameTextEditingController.text.length < 4) {
                        AssistantMethods.displayToastMessage(
                          "Numele trebuie sa contina cel putin 4 caractere",
                          context,
                        );
                        return;
                      } else if (!emailValid) {
                        AssistantMethods.displayToastMessage(
                          "Te rugam sa introduci o adresa de email valida",
                          context,
                        );
                        return;
                      } else if (phoneTextEditingController.text.length < 10 ||
                          phoneTextEditingController.text.length > 12) {
                        AssistantMethods.displayToastMessage(
                          "Te rugam sa introduci un numar de telefon valid",
                          context,
                        );
                        return;
                      } else if (passwordTextEditingController.text.length <
                          6) {
                        AssistantMethods.displayToastMessage(
                          "Te rugam sa introduci o parola de cel putin 6 caractere",
                          context,
                        );
                        return;
                      }

                      // register the user
                      registerNewUser(context);
                    },
                    child: const SizedBox(
                      height: 50,
                      child: Center(
                        child: Text(
                          "Inregistreaza Cont",
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
                print("Login Clicked");

                Navigator.pushNamedAndRemoveUntil(
                    context, LoginScreen.idScreen, (route) => false);
              },
              child: const SizedBox(
                height: 50,
                child: Center(
                  child: Text(
                    "Ai deja un cont? Autentifica-te aici.",
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

  void registerNewUser(BuildContext context) async {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return ProgressDialog(
            message: "Se inregistreaza. Va rugam asteptati.",
          );
        });
    final firebaseUser = (await _firebaseAuth
            .createUserWithEmailAndPassword(
      email: emailTextEditingController.text,
      password: passwordTextEditingController.text,
    )
            .catchError((errMesg) {
      // inchide panoul de loading
      Navigator.pop(context);
      AssistantMethods.displayToastMessage(
        "Error: $errMesg",
        context,
      );
    }))
        .user;

    if (firebaseUser != null) // user created
    {
      // save user info to database
      Map userDataMap = {
        "name": nameTextEditingController.text.trim(),
        "phone": phoneTextEditingController.text.trim(),
        "email": emailTextEditingController.text.trim(),
      };

      // print(
      //     "Name: ${nameTextEditingController.text}, Phone: ${phoneTextEditingController.text}, Email: ${emailTextEditingController.text}");

      userRef.child(firebaseUser.uid).set(userDataMap);

      // display success message
      AssistantMethods.displayToastMessage(
          "Felicitari. Contul dumneavoastra a fost creat cu succes", context);

      // load the MainScreen
      Navigator.pushNamedAndRemoveUntil(
          context, MainScreen.idScreen, (route) => false);
      return;
    }

    // inchide panoul de loading
    Navigator.pop(context);
    // error occured - display error message
    AssistantMethods.displayToastMessage(
        "Utilizatorul nu a putut fi creat", context);
  }
}
