import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taxi_rider_app/assistants/assistant_methods.dart';
import 'package:taxi_rider_app/core/error/failures.dart';
import 'package:taxi_rider_app/core/result/result.dart';
import 'package:taxi_rider_app/features/places_directions/presentation/providers/maps_repositories_provider.dart';
import 'package:taxi_rider_app/features/trip_places/presentation/providers/trip_places_provider.dart';
import 'package:taxi_rider_app/models/address.dart';
import 'package:taxi_rider_app/models/place_predictions.dart';
import 'package:taxi_rider_app/widgets/dividerwidget.dart';
import 'package:taxi_rider_app/widgets/progressdialog.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _pickUp = TextEditingController();
  final _dropOff = TextEditingController();
  List<PlacePredictions> _predictions = [];

  @override
  void dispose() {
    _pickUp.dispose();
    _dropOff.dispose();
    super.dispose();
  }

  Future<void> _findPlace(String placeName) async {
    if (placeName.length < 2) {
      return;
    }
    final repo = ref.read(placesRepositoryProvider);
    final result = await repo.autocomplete(placeName);
    if (!mounted) {
      return;
    }
    if (result is FailureResult<List<PlacePredictions>, Failure>) {
      return;
    }
    final list = (result as Success<List<PlacePredictions>, Failure>).value;
    setState(() => _predictions = list);
  }

  Future<void> _selectPlace(String placeId) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ProgressDialog(
        message: 'Setting Dropoff. Please wait...',
      ),
    );
    final repo = ref.read(placesRepositoryProvider);
    final result = await repo.placeDetails(placeId);
    if (!mounted) {
      return;
    }
    Navigator.pop(context);
    if (result is FailureResult<Address, Failure>) {
      AssistantMethods.displayToastMessage(
        result.error.message,
        context,
      );
      return;
    }
    final address = (result as Success<Address, Failure>).value;
    ref.read(tripPlacesProvider.notifier).updateDropOffLocation(address);
    if (!mounted) {
      return;
    }
    Navigator.pop(context, 'obtainDirection');
  }

  @override
  Widget build(BuildContext context) {
    final pick = ref.watch(tripPlacesProvider).pickUpLocation;
    _pickUp.text = pick?.placeName ?? '';

    return Scaffold(
      body: Column(
        children: [
          Container(
            height: 215,
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black,
                  blurRadius: 6,
                  spreadRadius: 0.5,
                  offset: Offset(0.7, 0.7),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                left: 25,
                top: 50,
                right: 25,
                bottom: 20,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 5),
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back),
                      ),
                      const Center(
                        child: Text(
                          'Set Drop Off',
                          style: TextStyle(
                            fontFamily: 'Brand',
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Image.asset('images/pickicon.png', height: 16, width: 16),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(3),
                            child: TextField(
                              controller: _pickUp,
                              decoration: InputDecoration(
                                hintText: 'PickUp Location',
                                fillColor: Colors.grey[400],
                                filled: true,
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.only(
                                  left: 11,
                                  top: 8,
                                  bottom: 8,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Image.asset('images/desticon.png', height: 16, width: 16),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(3),
                            child: TextField(
                              onChanged: (val) {
                                if (val.length > 4) {
                                  _findPlace(val);
                                }
                              },
                              controller: _dropOff,
                              decoration: InputDecoration(
                                hintText: 'Where to?',
                                fillColor: Colors.grey[400],
                                filled: true,
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.only(
                                  left: 11,
                                  top: 8,
                                  bottom: 8,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (_predictions.isNotEmpty)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListView.separated(
                  itemBuilder: (context, index) {
                    final p = _predictions[index];
                    return TextButton(
                      onPressed: () => _selectPlace(p.place_id),
                      child: Row(
                        children: [
                          const Icon(Icons.add_location),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                Text(
                                  p.main_text,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  p.secondary_text,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const DividerWidget(),
                  itemCount: _predictions.length,
                ),
              ),
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }
}
