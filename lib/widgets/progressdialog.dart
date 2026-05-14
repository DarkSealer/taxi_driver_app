import 'package:flutter/material.dart';

class ProgressDialog extends StatelessWidget {
  final String message;

  const ProgressDialog({
    Key? key,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.yellow,
      child: Container(
        margin: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Row(
            children: <Widget>[
              const SizedBox(
                width: 6,
              ),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
              ),
              const SizedBox(
                width: 26,
              ),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
