import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taxi_driver_app/assistants/requestassistant.dart';
import 'package:taxi_driver_app/configmaps.dart';
import 'package:taxi_driver_app/datahandler/appdata.dart';
import 'package:taxi_driver_app/models/address.dart';
import 'package:taxi_driver_app/models/place_predictions.dart';
import 'package:taxi_driver_app/widgets/dividerwidget.dart';
import 'package:taxi_driver_app/widgets/progressdialog.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  TextEditingController pickUpTextController = TextEditingController();
  TextEditingController dropOffTextController = TextEditingController();
  List<PlacePredictions> placePredictionList = [];

  @override
  Widget build(BuildContext context) {
    String placeAddress =
        Provider.of<AppData>(context).pickUpLocation!.placeName ?? "";
    pickUpTextController.text = placeAddress;

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
                  const SizedBox(
                    height: 5,
                  ),
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: const Icon(Icons.arrow_back),
                      ),
                      const Center(
                        child: Text(
                          "Set Drop Off",
                          style: TextStyle(
                            fontFamily: "Brand",
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  Row(
                    children: [
                      Image.asset(
                        "images/pickicon.png",
                        height: 16,
                        width: 16,
                      ),
                      const SizedBox(
                        width: 18,
                      ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(
                              5,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(3),
                            child: TextField(
                              controller: pickUpTextController,
                              decoration: InputDecoration(
                                hintText: "PickUp Location",
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
                  const SizedBox(
                    height: 10,
                  ),
                  Row(
                    children: [
                      Image.asset(
                        "images/desticon.png",
                        height: 16,
                        width: 16,
                      ),
                      const SizedBox(
                        width: 18,
                      ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(
                              5,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(3),
                            child: TextField(
                              onChanged: (val) {
                                if (val.length > 4) {
                                  findPlace(val);
                                }
                              },
                              controller: dropOffTextController,
                              decoration: InputDecoration(
                                hintText: "Where to?",
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
          // tile for displaying predictions
          const SizedBox(
            height: 10,
          ),
          (placePredictionList.isNotEmpty)
              ? Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(0.0),
                    itemBuilder: (context, index) {
                      return PredictionTile(
                          placePredictions: placePredictionList[index]);
                    },
                    separatorBuilder: (BuildContext context, int index) =>
                        const DividerWidget(),
                    itemCount: placePredictionList.length,
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                  ),
                )
              : Container(),
        ],
      ),
    );
  }

  void findPlace(String placeName) async {
    if (placeName.length > 1) {
      // TODO - de modificat modul de apelare a locatiei in functie de locatia userului
      String autoCompleteUrl =
          "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$placeName&language=$language&types=geocode&key=$mapKey&components=country:ro";
      var res = await RequestAssistant.getRequest(autoCompleteUrl);

      if (res == "failed") {
        return;
      }

      if (res["status"] == "OK") {
        var predictions = res["predictions"];

        // converting the json and storing the data into a List of places
        var placesList = (predictions as List)
            .map((e) => PlacePredictions.fromJson(e))
            .toList();
        setState(() {
          placePredictionList = placesList;
        });
      }
    }
  }
}

class PredictionTile extends StatelessWidget {
  final PlacePredictions placePredictions;

  const PredictionTile({Key? key, required this.placePredictions})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        getPlaceAddressDetails(
          placePredictions.place_id,
          context,
        );
      },
      child: Column(
        children: [
          const SizedBox(
            width: 10,
          ),
          Row(
            children: [
              const Icon(Icons.add_location),
              const SizedBox(
                width: 14,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      height: 8,
                    ),
                    Text(
                      placePredictions.main_text,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16.0,
                      ),
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                    Text(
                      placePredictions.secondary_text,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(fontSize: 12.0, color: Colors.grey),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(
            width: 10,
          ),
        ],
      ),
    );
  }

  void getPlaceAddressDetails(String placeId, context) async {
    showDialog(
        context: context,
        builder: (BuildContext context) =>
            ProgressDialog(message: "Setting Dropoff. Please wait..."));

    String placeDetailsUrl =
        "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$mapKey";

    var res = await RequestAssistant.getRequest(placeDetailsUrl);

    Navigator.pop(context);

    if (res == "failed") {
      return;
    }

    if (res["status"] == "OK") {
      Address address = Address(
        placeId: placeId,
        placeFormattedAddress: res["result"]["formatted_address"],
        placeName: res["result"]["name"],
        latitude: res["result"]["geometry"]["location"]["lat"],
        longitude: res["result"]["geometry"]["location"]["lng"],
      );

      Provider.of<AppData>(context, listen: false)
          .updateDropOffLocationAddress(address);
      print("This is the drop off location: ${address.placeName}");

      Navigator.pop(context, "obtainDirection");
    }
  }
}
