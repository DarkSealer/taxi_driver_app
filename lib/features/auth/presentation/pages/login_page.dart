import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taxi_rider_app/assistants/assistant_methods.dart';
import 'package:taxi_rider_app/core/error/failures.dart';
import 'package:taxi_rider_app/core/result/result.dart';
import 'package:taxi_rider_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:taxi_rider_app/features/auth/presentation/providers/current_user_provider.dart';
import 'package:taxi_rider_app/widgets/progressdialog.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ProgressDialog(
        message: 'Se autentifica. Va rugam asteptati',
      ),
    );
    final result = await ref.read(signInWithEmailUseCaseProvider).call(
          email: _email.text,
          password: _password.text,
        );
    if (!mounted) {
      return;
    }
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    if (result is FailureResult<void, Failure>) {
      AssistantMethods.displayToastMessage(
        result.error.message,
        context,
      );
      return;
    }
    await ref.read(currentUserProvider.notifier).loadFromRemote();
    if (!mounted) {
      return;
    }
    AssistantMethods.displayToastMessage(
      'Sunteti conectat la contul dvs.',
      context,
    );
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            const SizedBox(height: 35),
            const Image(
              image: AssetImage('images/logo.png'),
              width: 390,
              height: 250,
              alignment: Alignment.center,
            ),
            const SizedBox(height: 1),
            const Text(
              'Autentificare ca Pasager',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontFamily: 'Bolt',
                fontWeight: FontWeight.w900,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(fontSize: 14),
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Parola',
                      labelStyle: TextStyle(fontSize: 14),
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      final emailValid = RegExp(
                        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
                      ).hasMatch(_email.text);
                      if (!emailValid) {
                        AssistantMethods.displayToastMessage(
                          'Te rugam sa introduci o adresa de email valida.',
                          context,
                        );
                        return;
                      }
                      if (_password.text.isEmpty) {
                        AssistantMethods.displayToastMessage(
                          'Te rugam sa introduci o parola valida.',
                          context,
                        );
                        return;
                      }
                      _login();
                    },
                    child: const SizedBox(
                      height: 50,
                      child: Center(
                        child: Text(
                          'Autentificare',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontFamily: 'Bold',
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
              onPressed: () => context.go('/register'),
              child: const SizedBox(
                height: 50,
                child: Center(
                  child: Text(
                    'Nu ai cont? Inregistreaza-te aici.',
                    style: TextStyle(fontSize: 16, fontFamily: 'Bold'),
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
