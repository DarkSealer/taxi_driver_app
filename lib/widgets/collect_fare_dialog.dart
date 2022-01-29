import 'package:flutter/material.dart';

import '/assistants/assistant_methods.dart';

class CollectFareDialog extends StatelessWidget {
  final String paymentMethod;
  final int fareAmount;
  const CollectFareDialog(
      {Key? key, required this.paymentMethod, required this.fareAmount})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
        ),
        margin: const EdgeInsets.all(5),
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 22,
            ),
            const Text("Trip Fare"),
            const SizedBox(
              height: 22,
            ),
            const Divider(
              height: 2,
              thickness: 2,
            ),
            const SizedBox(
              height: 16,
            ),
            Text(
              "\$$fareAmount",
              style: const TextStyle(
                fontSize: 55,
                fontFamily: "Brand",
                fontWeight: FontWeight.bold,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "This is the total trip amount it has been charged to the rider",
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(
              height: 30,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: RaisedButton(
                onPressed: () async {
                  Navigator.pop(context, 'close');
                },
                color: Colors.green,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      "Pay Cash",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Icon(
                      Icons.attach_money,
                      color: Colors.white,
                      size: 26,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
