import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class RatingPage extends StatefulWidget {
  const RatingPage({super.key, required this.driverId});

  final String driverId;

  @override
  State<RatingPage> createState() => _RatingPageState();
}

class _RatingPageState extends State<RatingPage> {
  double _rating = 3;
  String _title = 'Good';

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
              const SizedBox(height: 22),
              const Text(
                'Rate this Driver',
                style: TextStyle(
                  fontSize: 20,
                  fontFamily: 'Brand',
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 22),
              const Divider(height: 2, thickness: 2),
              const SizedBox(height: 16),
              RatingBar.builder(
                initialRating: _rating,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: false,
                itemCount: 5,
                itemPadding: const EdgeInsets.symmetric(horizontal: 4),
                itemBuilder: (context, _) => const Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                onRatingUpdate: (rating) {
                  setState(() {
                    _rating = rating;
                    if (_rating <= 1) {
                      _title = 'Very Bad';
                    } else if (_rating == 2) {
                      _title = 'Bad';
                    } else if (_rating == 3) {
                      _title = 'Good';
                    } else if (_rating == 4) {
                      _title = 'Very Good';
                    } else {
                      _title = 'Excellent';
                    }
                  });
                },
              ),
              const SizedBox(height: 14),
              Text(
                _title,
                style: const TextStyle(
                  fontSize: 65,
                  fontFamily: 'Signatra',
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () async {
                    final driverRatingRef = FirebaseDatabase.instance
                        .ref()
                        .child('drivers')
                        .child(widget.driverId)
                        .child('ratings');

                    final snap = await driverRatingRef.get();
                    if (snap.exists && snap.value != null) {
                      final oldRatings =
                          double.parse(snap.value.toString());
                      final averageRatings = (oldRatings + _rating) / 2;
                      await driverRatingRef.set(averageRatings);
                    } else {
                      await driverRatingRef.set(_rating.toString());
                    }
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        'Submit',
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
