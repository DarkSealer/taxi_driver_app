import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taxi_rider_app/assistants/assistant_methods.dart';
import 'package:taxi_rider_app/core/error/failures.dart';
import 'package:taxi_rider_app/core/result/result.dart';
import 'package:taxi_rider_app/features/auth/domain/entities/app_user.dart';
import 'package:taxi_rider_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:taxi_rider_app/features/auth/presentation/providers/current_user_provider.dart';
import 'package:taxi_rider_app/widgets/progressdialog.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ProgressDialog(
        message: 'Se inregistreaza. Va rugam asteptati.',
      ),
    );
    final draft = AppUserDraft(
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      email: _email.text.trim(),
    );
    final result = await ref.read(registerPassengerUseCaseProvider).call(
          email: _email.text,
          password: _password.text,
          draft: draft,
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
      'Felicitari. Contul dumneavoastra a fost creat cu succes',
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
            const SizedBox(height: 20),
            const Image(
              image: AssetImage('images/logo.png'),
              width: 390,
              height: 250,
              alignment: Alignment.center,
            ),
            const SizedBox(height: 1),
            const Text(
              'Inregistreaza un Pasager',
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
                    keyboardType: TextInputType.name,
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: 'Nume',
                      labelStyle: TextStyle(fontSize: 14),
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                  TextField(
                    keyboardType: TextInputType.emailAddress,
                    controller: _email,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(fontSize: 14),
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                  TextField(
                    keyboardType: TextInputType.phone,
                    controller: _phone,
                    decoration: const InputDecoration(
                      labelText: 'Telefon',
                      labelStyle: TextStyle(fontSize: 14),
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                  TextField(
                    obscureText: true,
                    controller: _password,
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
                      if (_name.text.length < 4) {
                        AssistantMethods.displayToastMessage(
                          'Numele trebuie sa contina cel putin 4 caractere',
                          context,
                        );
                        return;
                      }
                      if (!emailValid) {
                        AssistantMethods.displayToastMessage(
                          'Te rugam sa introduci o adresa de email valida',
                          context,
                        );
                        return;
                      }
                      if (_phone.text.length < 10 ||
                          _phone.text.length > 12) {
                        AssistantMethods.displayToastMessage(
                          'Te rugam sa introduci un numar de telefon valid',
                          context,
                        );
                        return;
                      }
                      if (_password.text.length < 6) {
                        AssistantMethods.displayToastMessage(
                          'Te rugam sa introduci o parola de cel putin 6 caractere',
                          context,
                        );
                        return;
                      }
                      _register();
                    },
                    child: const SizedBox(
                      height: 50,
                      child: Center(
                        child: Text(
                          'Inregistreaza Cont',
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
              onPressed: () => context.go('/login'),
              child: const SizedBox(
                height: 50,
                child: Center(
                  child: Text(
                    'Ai deja un cont? Autentifica-te aici.',
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
