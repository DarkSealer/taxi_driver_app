import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '/configmaps.dart';

class RatingScreen extends StatefulWidget {
  final String driverId;
  const RatingScreen({Key? key, required this.driverId}) : super(key: key);

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Dialog(
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
              const Text(
                "Rate this Driver",
                style: TextStyle(
                  fontSize: 20,
                  fontFamily: 'Brand',
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
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
              RatingBar.builder(
                initialRating: starCounter,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: false,
                itemCount: 5,
                itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                itemBuilder: (context, _) => const Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                onRatingUpdate: (rating) {
                  starCounter = rating;
                  if (starCounter == 1) {
                    setState(() {
                      title = 'Very Bad';
                    });
                  }
                  if (starCounter == 2) {
                    setState(() {
                      title = 'Bad';
                    });
                  }
                  if (starCounter == 3) {
                    setState(() {
                      title = 'Good';
                    });
                  }
                  if (starCounter == 4) {
                    setState(() {
                      title = 'Very Good';
                    });
                  }
                  if (starCounter == 5) {
                    setState(() {
                      title = 'Excellent';
                    });
                  }
                },
              ),
              const SizedBox(
                height: 14,
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 65,
                  fontFamily: 'Signatra',
                  color: Colors.green,
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: RaisedButton(
                  onPressed: () async {
                    DatabaseReference driverRatingRef = FirebaseDatabase
                        .instance
                        .ref()
                        .child("drivers")
                        .child(widget.driverId)
                        .child('ratings');

                    driverRatingRef.get().then((snap) {
                      if (snap.value != null) {
                        double oldRatings = double.parse(snap.value.toString());
                        double averageRatings = (oldRatings + starCounter) / 2;
                        driverRatingRef.set(averageRatings);
                      }
                      // daca este un sofer nou fara ratinguri anterioare
                      else {
                        driverRatingRef.set(starCounter.toString());
                      }
                    });

                    Navigator.pop(context);
                  },
                  color: Colors.green,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: const [
                      Text(
                        "Submit",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
