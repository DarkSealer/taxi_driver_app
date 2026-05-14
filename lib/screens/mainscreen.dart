import 'dart:async';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:taxi_rider_app/main.dart';
import 'package:taxi_rider_app/screens/about_screen.dart';
import 'package:taxi_rider_app/screens/history_screen.dart';
import 'package:taxi_rider_app/screens/profile_screen.dart';
import 'package:taxi_rider_app/screens/rating_screen.dart';
import 'package:taxi_rider_app/widgets/collect_fare_dialog.dart';
import 'package:taxi_rider_app/widgets/no_driver_available_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

import '/assistants/assistant_methods.dart';
import '/configmaps.dart';
import '/datahandler/appdata.dart';
import '/models/direction_details.dart';
import '/screens/loginscreen.dart';
import '/screens/searchscreen.dart';
import '/widgets/dividerwidget.dart';
import '/widgets/progressdialog.dart';
import '/assistants/geofire_assistant.dart';
import '/models/nearby_available_drivers.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  static const String idScreen = "mainScreen";

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final Completer<GoogleMapController> _controllerGoogleMap = Completer();
  late GoogleMapController newGoogleMapController;
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  DirectionDetails? tripDirectionDetails;
  List<LatLng> pLineCoordinates = [];
  Set<Polyline> polylineSet = {};
  late Position currentPosition;
  var geoLocator = Geolocator();
  double bottomPaddingOfMap = 0;
  Set<Marker> markersSet = {};
  Set<Circle> circlesSet = {};
  double rideDetailsContainerHeight = 0;
  double requestRideContainerHeight = 0;
  double searchContainerHeight = 300;
  bool drawerOpen = true;
  late DatabaseReference? rideRequestRef;
  bool nearbyAvailableDriverKeysLoaded = false;
  BitmapDescriptor? nearbyIcon;
  late List<NearbyAvailableDrivers> availableDrivers;
  String state = "normal";
  double driverDetailsContainerHeight = 0;
  late StreamSubscription? rideStreamSubscription;
  bool isRequestingPositionDetails = false;
  String uName = "";

  static const colorizeColors = [
    Colors.green,
    Colors.purple,
    Colors.pink,
    Colors.blue,
    Colors.yellow,
    Colors.red,
  ];
  static const colorizeTextStyle = TextStyle(
    fontSize: 55.0,
    fontFamily: 'Signatra',
  );

  void displayRequestRideContainer() {
    setState(() {
      requestRideContainerHeight = 250;
      rideDetailsContainerHeight = 0;
      drawerOpen = false;
      bottomPaddingOfMap = 230;
    });
  }

  void displayDriverDetailsContainer() {
    setState(() {
      drawerOpen = false;
      requestRideContainerHeight = 0;
      rideDetailsContainerHeight = 0;
      bottomPaddingOfMap = 290;
      driverDetailsContainerHeight = 310;
    });
  }

  void resetApp() {
    setState(() {
      drawerOpen = true;
      searchContainerHeight = 300;
      rideDetailsContainerHeight = 0;
      requestRideContainerHeight = 0;
      bottomPaddingOfMap = 230;

      polylineSet.clear();
      markersSet.clear();
      circlesSet.clear();
      pLineCoordinates.clear();

      statusRide = '';
      driverName = '';
      driverPhone = '';
      carDetailsDriver = '';
      rideStatus = 'Driver is Coming';
      driverDetailsContainerHeight = 0;
    });

    locatePosition();
  }

  void displayRideDetailsContainer() async {
    await getPlaceDirection();

    setState(() {
      searchContainerHeight = 0;
      rideDetailsContainerHeight = 340;
      bottomPaddingOfMap = 360;
      drawerOpen = false;
    });

    saveRideRequest();
  }

  // get the user current position
  void locatePosition() async {
    await Geolocator.requestPermission();
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    currentPosition = position;
    LatLng latLngPosition = LatLng(position.latitude, position.longitude);

    CameraPosition cameraPosition =
        CameraPosition(target: latLngPosition, zoom: 14);

    newGoogleMapController
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    String address =
        await AssistantMethods.searchCoordinateAddress(position, context);
    print("This is your Address: $address");

    initGeofireListener();

    uName = userCurrentInfo!.name;

    AssistantMethods.retrieveHistoryInfo(context);
  }

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  @override
  void initState() {
    super.initState();

    AssistantMethods.getCurrentOnlineUserInfo();
  }

  // store the clients data in DB
  void saveRideRequest() {
    rideRequestRef =
        FirebaseDatabase.instance.ref().child("rideRequests").push();

    var pickUp = Provider.of<AppData>(context, listen: false).pickUpLocation;
    var dropOff = Provider.of<AppData>(context, listen: false).dropOffLocation;

    Map pickUpLocationMap = {
      "latitude": pickUp?.latitude.toString(),
      "longitude": pickUp?.longitude.toString(),
    };

    Map dropOffLocationMap = {
      "latitude": dropOff?.latitude.toString(),
      "longitude": dropOff?.longitude.toString(),
    };

    Map riderInfoMap = {
      "driver_id": "waiting",
      "payment_method": "cash",
      "pickup": pickUpLocationMap,
      "dropoff": dropOffLocationMap,
      "created_at": DateTime.now().toString(),
      "rider_name": userCurrentInfo!.name,
      "rider_phone": userCurrentInfo!.phone,
      "pickup_address": pickUp!.placeName,
      "dropoff_address": dropOff!.placeName,
      "ride_type": carRideType,
    };

    rideRequestRef!.set(riderInfoMap);

    rideStreamSubscription = rideRequestRef!.onValue.listen((event) async {
      if (event.snapshot.value == null) {
        return;
      }

      Map values = event.snapshot.value as Map<dynamic, dynamic>;

      // update the car details
      if (values['car_details'] != null) {
        setState(() {
          carDetailsDriver = values['car_details'].toString();
        });
      }

      // update the driver name
      if (values['driver_name'] != null) {
        setState(() {
          driverName = values['driver_name'].toString();
        });
      }

      // update the driver phone
      if (values['driver_location'] != null) {
        double driverLat =
            double.parse(values['driver_location']['latitude'].toString());
        double driverLng =
            double.parse(values['driver_location']['longitude'].toString());

        LatLng driverCurrentLocation = LatLng(driverLat, driverLng);

        // calculeaza & actualizeaza timpul pana ajunge soferul la client
        if (statusRide == "accepted") {
          updateRideTimeToPickUpLoc(driverCurrentLocation);
        }
        // dupa ce a fost preluat clientul, se calculeaza / actualizeaza timpul pana la destinatie
        else if (statusRide == 'onride') {
          updateRideTimeToDropOffLoc(driverCurrentLocation);
        }
        //
        else if (statusRide == 'arrived') {
          setState(() {
            rideStatus = 'Driver has Arrived';
          });
        }
      }

      if (values['driver_phone'] != null) {
        setState(() {
          driverPhone = values['driver_phone'].toString();
        });
      }

      // update the status of the ride
      if (values['status'] != null) {
        statusRide = values['status'].toString();
      }

      if (statusRide == 'accepted') {
        displayDriverDetailsContainer();
        Geofire.stopListener();
        deleteGeofireMarkers();
      }

      if (statusRide == 'ended') {
        if (values['fares'] != null) {
          int fare = int.parse(values['fares'].toString());
          var res = await showDialog(
            context: context,
            builder: (BuildContext context) =>
                CollectFareDialog(paymentMethod: 'cash', fareAmount: fare),
          );

          String driverId = "";
          if (res == 'close') {
            if (values['driver_id'] != null) {
              driverId = values['driver_id'].toString();
            }

            // incarca pagina RatingScreen
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => RatingScreen(driverId: driverId)));

            rideRequestRef!.onDisconnect();
            rideRequestRef = null;
            rideStreamSubscription!.cancel();
            rideStreamSubscription = null;
            resetApp();
          }
        }
      }
    });
  }

  void deleteGeofireMarkers() {
    setState(() {
      markersSet
          .removeWhere((element) => element.markerId.value.contains('driver'));
    });
  }

  void updateRideTimeToPickUpLoc(LatLng driverCurrentLocation) async {
    if (!isRequestingPositionDetails) {
      isRequestingPositionDetails = true;

      var positionUserLatLng = LatLng(
        currentPosition.latitude,
        currentPosition.longitude,
      );

      // obtine detaliile calatoriei (timpul de ajungere a soferului la adresa clientului)
      var details = await AssistantMethods.obtainDirectionsDetails(
        driverCurrentLocation,
        positionUserLatLng,
      );

      if (details == null) {
        return;
      }

      setState(() {
        rideStatus = 'Driver is Coming - ${details.durationText}';
      });

      isRequestingPositionDetails = false;
    }
  }

  void updateRideTimeToDropOffLoc(LatLng driverCurrentLocation) async {
    if (!isRequestingPositionDetails) {
      isRequestingPositionDetails = true;

      var positionUserLatLng =
          Provider.of<AppData>(context, listen: false).dropOffLocation;
      var dropOffLatLng =
          LatLng(positionUserLatLng!.latitude, positionUserLatLng.longitude);

      // obtine detaliile calatoriei (timpul de ajungere a soferului la adresa clientului)
      var details = await AssistantMethods.obtainDirectionsDetails(
        driverCurrentLocation,
        dropOffLatLng,
      );

      if (details == null) {
        return;
      }

      setState(() {
        rideStatus = 'Going to Destination - ${details.durationText}';
      });

      isRequestingPositionDetails = false;
    }
  }

  // cancel the request
  void cancelRideRequest() {
    // removes the entry from db
    rideRequestRef!.remove();
    setState(() {
      state = "normal";
    });
  }

  @override
  Widget build(BuildContext context) {
    createIconMarker();

    return Scaffold(
      key: scaffoldKey,
      // appBar: AppBar(
      //   title: const Text("MainScreen"),
      // ),
      drawer: Container(
        color: Colors.white,
        width: 255,
        child: Drawer(
          child: ListView(
            children: <Widget>[
              // Drawer Header
              Container(
                height: 165.0,
                child: DrawerHeader(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                  ),
                  child: Row(
                    children: <Widget>[
                      Image.asset(
                        "images/user_icon.png",
                        height: 65,
                        width: 65,
                      ),
                      const SizedBox(
                        width: 16,
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            uName,
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: "Brand",
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(
                            height: 6,
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const ProfileScreen()));
                            },
                            child: const Text("Visit Profile"),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              const DividerWidget(),
              const SizedBox(height: 12),
              //Drawer Body Controllers
              GestureDetector(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const HistoryScreen()));
                },
                child: const ListTile(
                  leading: Icon(Icons.history),
                  title: Text(
                    "History",
                    style: TextStyle(
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: GestureDetector(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ProfileScreen()));
                  },
                  child: const Text(
                    "Visit Profile",
                    style: TextStyle(
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pushNamedAndRemoveUntil(
                      context, AboutScreen.idScreen, (route) => false);
                },
                child: const ListTile(
                  leading: Icon(Icons.info),
                  title: Text(
                    "About",
                    style: TextStyle(
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  FirebaseAuth.instance.signOut();
                  Navigator.pushNamedAndRemoveUntil(
                      context, LoginScreen.idScreen, (route) => false);
                },
                child: const ListTile(
                  leading: Icon(Icons.logout),
                  title: Text(
                    "Log Out",
                    style: TextStyle(
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            padding: EdgeInsets.only(bottom: bottomPaddingOfMap),
            mapType: MapType.normal,
            myLocationButtonEnabled: true,
            initialCameraPosition: _kGooglePlex,
            myLocationEnabled: true,
            zoomGesturesEnabled: true,
            zoomControlsEnabled: true,
            polylines: polylineSet,
            markers: markersSet,
            circles: circlesSet,
            onMapCreated: (GoogleMapController controller) {
              _controllerGoogleMap.complete(controller);
              newGoogleMapController = controller;

              setState(() {
                bottomPaddingOfMap = 300;
              });

              // get the user current position
              locatePosition();
            },
          ),
          // Hamburger Button for Drawer
          Positioned(
            top: 38.0,
            left: 22,
            child: GestureDetector(
              onTap: () {
                if (drawerOpen) {
                  scaffoldKey.currentState?.openDrawer();
                  return;
                }

                resetApp();
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 6,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(
                    (drawerOpen) ? Icons.menu : Icons.close,
                    color: Colors.black,
                  ),
                  radius: 20,
                ),
              ),
            ),
          ),
          // Search UI
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedSize(
              curve: Curves.bounceIn,
              duration: const Duration(milliseconds: 160),
              child: Container(
                height: searchContainerHeight,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 16,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 18.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6.0),
                      const Text(
                        "Hi there",
                        style: TextStyle(
                          fontSize: 12,
                        ),
                      ),
                      const Text(
                        "Where to?",
                        style: TextStyle(
                          fontSize: 20,
                          fontFamily: "Brand",
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20.0),
                      GestureDetector(
                        onTap: () async {
                          // load the search screen
                          var res = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const SearchScreen()));

                          if (res == "obtainDirection") {
                            displayRideDetailsContainer();
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(5.0),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black54,
                                blurRadius: 6,
                                spreadRadius: 0.5,
                                offset: Offset(0.7, 0.7),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: const [
                                Icon(
                                  Icons.search,
                                  color: Colors.blueAccent,
                                ),
                                SizedBox(
                                  width: 10.0,
                                ),
                                Text("Search Drop Off"),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 24,
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.home,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 12.0),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                Provider.of<AppData>(context).pickUpLocation !=
                                        null
                                    ? Provider.of<AppData>(context)
                                        .pickUpLocation!
                                        .placeName
                                    : "Add Home",
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(
                                height: 4,
                              ),
                              const Text(
                                "Your living home address",
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      const DividerWidget(),
                      const SizedBox(
                        height: 16,
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.work,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 12.0),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Add Work"),
                              const SizedBox(
                                height: 4,
                              ),
                              Text(
                                "Your office address",
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Ride details UI
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedSize(
              curve: Curves.bounceIn,
              duration: const Duration(milliseconds: 160),
              child: Container(
                height: rideDetailsContainerHeight,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 16,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 17,
                  ),
                  child: Column(
                    children: [
                      // bike ride
                      GestureDetector(
                        onTap: () {
                          //
                          AssistantMethods.displayToastMessage(
                              "searching bike...", context);
                          // call a taxi
                          setState(() {
                            state = "requesting";
                            carRideType = 'bike';
                          });
                          displayRequestRideContainer();
                          availableDrivers =
                              GeofireAssistant.nearbyAvailableDriversList;
                          searchNearestDriver();
                        },
                        child: Container(
                          width: double.infinity,
                          // color: Colors.tealAccent[100],
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                            child: Row(
                              children: [
                                Image.asset(
                                  "images/bike.png",
                                  height: 70,
                                  width: 80,
                                ),
                                const SizedBox(
                                  width: 16.0,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Bike",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontFamily: "Brand",
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    Text(
                                      ((tripDirectionDetails != null)
                                          ? tripDirectionDetails!.distanceText
                                          : ''),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                Expanded(
                                  child: Container(),
                                ),
                                // display the price - for bike
                                Text(
                                  ((tripDirectionDetails != null)
                                      ? '\$${(AssistantMethods.calculateFares(tripDirectionDetails!)) / 2}'
                                      : ''),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                    fontFamily: "Brand",
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 10,
                      ),
                      const Divider(
                        height: 2,
                        thickness: 2,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      // uber-go ride
                      GestureDetector(
                        onTap: () {
                          //
                          AssistantMethods.displayToastMessage(
                              "searching Uber-Go...", context);
                          // call a taxi
                          setState(() {
                            state = "requesting";

                            carRideType = 'uber-go';
                          });
                          displayRequestRideContainer();
                          availableDrivers =
                              GeofireAssistant.nearbyAvailableDriversList;
                          searchNearestDriver();
                        },
                        child: Container(
                          width: double.infinity,
                          // color: Colors.tealAccent[100],
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                            child: Row(
                              children: [
                                Image.asset(
                                  "images/ubergo.png",
                                  height: 70,
                                  width: 80,
                                ),
                                const SizedBox(
                                  width: 16.0,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Uber-Go",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontFamily: "Brand",
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    Text(
                                      ((tripDirectionDetails != null)
                                          ? tripDirectionDetails!.distanceText
                                          : ''),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                Expanded(
                                  child: Container(),
                                ),
                                // display the price
                                Text(
                                  ((tripDirectionDetails != null)
                                      ? '\$${AssistantMethods.calculateFares(tripDirectionDetails!)}'
                                      : ''),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                    fontFamily: "Brand",
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 10,
                      ),
                      const Divider(
                        height: 2,
                        thickness: 2,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      // uber-x ride
                      GestureDetector(
                        onTap: () {
                          //
                          AssistantMethods.displayToastMessage(
                              "searching Uber-X...", context);
                          // call a taxi
                          setState(() {
                            state = "requesting";

                            carRideType = 'uber-x';
                          });
                          displayRequestRideContainer();
                          availableDrivers =
                              GeofireAssistant.nearbyAvailableDriversList;
                          searchNearestDriver();
                        },
                        child: Container(
                          width: double.infinity,
                          // color: Colors.tealAccent[100],
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                            child: Row(
                              children: [
                                Image.asset(
                                  "images/uberx.png",
                                  height: 70,
                                  width: 80,
                                ),
                                const SizedBox(
                                  width: 16.0,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Uber-X",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontFamily: "Brand",
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    Text(
                                      ((tripDirectionDetails != null)
                                          ? tripDirectionDetails!.distanceText
                                          : ''),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                Expanded(
                                  child: Container(),
                                ),
                                // display the price
                                Text(
                                  ((tripDirectionDetails != null)
                                      ? '\$${AssistantMethods.calculateFares(tripDirectionDetails!) * 2}'
                                      : ''),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                    fontFamily: "Brand",
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 10,
                      ),
                      const Divider(
                        height: 2,
                        thickness: 2,
                      ),
                      const SizedBox(
                        height: 10,
                      ),

                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            const Icon(
                              FontAwesomeIcons.moneyCheckAlt,
                              size: 18,
                              color: Colors.black54,
                            ),
                            const SizedBox(
                              width: 16,
                            ),
                            const Text("Cash"),
                            const SizedBox(
                              width: 6,
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.black54,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                      // old call taxi button
                      // Padding(
                      //   padding: const EdgeInsets.symmetric(horizontal: 16),
                      //   child: RaisedButton(
                      //     onPressed: () {
                      //       // call a taxi
                      //       setState(() {
                      //         state = "requesting";
                      //       });
                      //       displayRequestRideContainer();
                      //       availableDrivers =
                      //           GeofireAssistant.nearbyAvailableDriversList;
                      //       searchNearestDriver();
                      //     },
                      //     color: Theme.of(context).accentColor,
                      //     child: Padding(
                      //       padding: const EdgeInsets.all(17),
                      //       child: Row(
                      //         children: const [
                      //           Text(
                      //             "Request",
                      //             style: TextStyle(
                      //                 fontSize: 20,
                      //                 fontWeight: FontWeight.bold,
                      //                 color: Colors.white),
                      //           ),
                      //           Icon(
                      //             FontAwesomeIcons.taxi,
                      //             color: Colors.white,
                      //             size: 26,
                      //           ),
                      //         ],
                      //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //       ),
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Cancel UI
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    spreadRadius: 0.5,
                    blurRadius: 16,
                    color: Colors.black54,
                    offset: Offset(0.7, 0.7),
                  ),
                ],
              ),
              height: requestRideContainerHeight,
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  children: [
                    const SizedBox(
                      height: 12,
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: AnimatedTextKit(
                        animatedTexts: [
                          ColorizeAnimatedText(
                            'Requesting a Ride',
                            textStyle: colorizeTextStyle,
                            colors: colorizeColors,
                            textAlign: TextAlign.center,
                          ),
                          ColorizeAnimatedText(
                            'Please wait...',
                            textStyle: colorizeTextStyle,
                            colors: colorizeColors,
                            textAlign: TextAlign.center,
                          ),
                          ColorizeAnimatedText(
                            'Finding a Driver...',
                            textStyle: colorizeTextStyle,
                            colors: colorizeColors,
                            textAlign: TextAlign.center,
                          ),
                        ],
                        isRepeatingAnimation: true,
                        onTap: () {
                          print("Tap Event");
                        },
                      ),
                    ),
                    const SizedBox(
                      height: 22,
                    ),
                    GestureDetector(
                      onTap: () {
                        cancelRideRequest();
                        resetApp();
                      },
                      child: Container(
                        height: 60,
                        width: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(
                            width: 2,
                            color: Colors.grey,
                          ),
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    const SizedBox(
                      width: double.infinity,
                      child: Text(
                        "Cancel Ride",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Display Assigned Driver Info
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    spreadRadius: 0.5,
                    blurRadius: 16,
                    color: Colors.black54,
                    offset: Offset(0.7, 0.7),
                  ),
                ],
              ),
              height: driverDetailsContainerHeight,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      height: 6.0,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          rideStatus,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontFamily: 'Brand',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 22,
                    ),
                    const Divider(
                      height: 2,
                      thickness: 2,
                    ),
                    const SizedBox(
                      height: 22,
                    ),
                    Text(
                      carDetailsDriver,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    Text(
                      driverName,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const Divider(
                      height: 2,
                      thickness: 2,
                    ),
                    const SizedBox(
                      height: 22,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // call button
                        // Column(
                        //   crossAxisAlignment: CrossAxisAlignment.center,
                        //   children: [
                        //     Container(
                        //       height: 55,
                        //       width: 55,
                        //       decoration: BoxDecoration(
                        //         borderRadius: const BorderRadius.all(
                        //           Radius.circular(26),
                        //         ),
                        //         border:
                        //             Border.all(width: 2, color: Colors.grey),
                        //       ),
                        //       child: const Icon(Icons.call),
                        //     ),
                        //     const SizedBox(
                        //       height: 10,
                        //     ),
                        //     const Text('Call'),
                        //   ],
                        // ),
                        // // Details button
                        // Column(
                        //   crossAxisAlignment: CrossAxisAlignment.center,
                        //   children: [
                        //     Container(
                        //       height: 55,
                        //       width: 55,
                        //       decoration: BoxDecoration(
                        //         borderRadius: const BorderRadius.all(
                        //           Radius.circular(26),
                        //         ),
                        //         border:
                        //             Border.all(width: 2, color: Colors.grey),
                        //       ),
                        //       child: const Icon(Icons.list),
                        //     ),
                        //     const SizedBox(
                        //       height: 10,
                        //     ),
                        //     const Text('Details'),
                        //   ],
                        // ),
                        // // cancel button
                        // Column(
                        //   crossAxisAlignment: CrossAxisAlignment.center,
                        //   children: [
                        //     Container(
                        //       height: 55,
                        //       width: 55,
                        //       decoration: BoxDecoration(
                        //         borderRadius: const BorderRadius.all(
                        //           Radius.circular(26),
                        //         ),
                        //         border:
                        //             Border.all(width: 2, color: Colors.grey),
                        //       ),
                        //       child: const Icon(Icons.close),
                        //     ),
                        //     const SizedBox(
                        //       height: 10,
                        //     ),
                        //     const Text('Cancel'),
                        //   ],
                        // ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: ElevatedButton(
                            onPressed: () {
                              launchUrl(
                                Uri.parse('tel:$driverPhone'),
                                mode: LaunchMode.externalApplication,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink,
                              foregroundColor: Colors.white,
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(17),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Text(
                                    'Call Driver',
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                  Icon(
                                    Icons.call,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ],
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
          ),
        ],
      ),
    );
  }

  Future<void> getPlaceDirection() async {
    var initialPos =
        Provider.of<AppData>(context, listen: false).pickUpLocation;
    var finalPos = Provider.of<AppData>(context, listen: false).dropOffLocation;

    var pickUpLatLng = LatLng(initialPos!.latitude, initialPos.longitude);
    var dropOffLatLng = LatLng(finalPos!.latitude, finalPos.longitude);

    showDialog(
        context: context,
        builder: (BuildContext context) => const ProgressDialog(
              message: "Please wait...",
            ));

    var details = await AssistantMethods.obtainDirectionsDetails(
        pickUpLatLng, dropOffLatLng);
    setState(() {
      tripDirectionDetails = details!;
    });

    Navigator.pop(context);

    print("This is Encoded Points: ${details!.encodedPoints}");

    PolylinePoints polylinePoints = PolylinePoints();
    // decode the encoded polyline points
    List<PointLatLng> decodePolylinePointsResult =
        polylinePoints.decodePolyline(details.encodedPoints);

    pLineCoordinates.clear();

    if (decodePolylinePointsResult.isNotEmpty) {
      for (var pointLatLng in decodePolylinePointsResult) {
        pLineCoordinates
            .add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      }
    }

    polylineSet.clear();
    setState(() {
      Polyline polyline = Polyline(
        color: Colors.blue,
        polylineId: const PolylineId("PolylineID"),
        jointType: JointType.round,
        points: pLineCoordinates,
        width: 5,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      );

      polylineSet.add(polyline);
    });

    // make the polyline stick to the map
    LatLngBounds latLngBounds;
    if (pickUpLatLng.latitude > dropOffLatLng.latitude &&
        pickUpLatLng.longitude > dropOffLatLng.longitude) {
      latLngBounds =
          LatLngBounds(southwest: dropOffLatLng, northeast: pickUpLatLng);
    } else if (pickUpLatLng.latitude > dropOffLatLng.latitude) {
      latLngBounds = LatLngBounds(
          southwest: LatLng(dropOffLatLng.latitude, pickUpLatLng.longitude),
          northeast: LatLng(pickUpLatLng.latitude, dropOffLatLng.longitude));
    } else if (pickUpLatLng.longitude > dropOffLatLng.longitude) {
      latLngBounds = LatLngBounds(
          southwest: LatLng(pickUpLatLng.latitude, dropOffLatLng.longitude),
          northeast: LatLng(dropOffLatLng.latitude, pickUpLatLng.longitude));
    } else {
      latLngBounds =
          LatLngBounds(southwest: pickUpLatLng, northeast: dropOffLatLng);
    }

    newGoogleMapController
        .animateCamera(CameraUpdate.newLatLngBounds(latLngBounds, 70));

    // marker for pick up location
    Marker pickUpLocMarker = Marker(
      markerId: const MarkerId("pickUpId"),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow:
          InfoWindow(title: initialPos.placeName, snippet: "My Location"),
      position: pickUpLatLng,
    );

    // marker for drop off location
    Marker dropOffLocMarker = Marker(
      markerId: const MarkerId("dropOffId"),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow:
          InfoWindow(title: finalPos.placeName, snippet: "DropOff Location"),
      position: dropOffLatLng,
    );

    setState(() {
      markersSet.add(pickUpLocMarker);
      markersSet.add(dropOffLocMarker);
    });

    Circle pickUpLocCircle = Circle(
      circleId: const CircleId("pickUpId"),
      fillColor: Colors.green,
      center: pickUpLatLng,
      radius: 12,
      strokeWidth: 4,
      strokeColor: Colors.greenAccent,
    );

    Circle dropOffLocCircle = Circle(
      circleId: const CircleId("dropOffId"),
      fillColor: Colors.red,
      center: dropOffLatLng,
      radius: 12,
      strokeWidth: 4,
      strokeColor: Colors.redAccent,
    );

    setState(() {
      circlesSet.add(pickUpLocCircle);
      circlesSet.add(dropOffLocCircle);
    });
  }

  // display & update the drivers position on Map
  void initGeofireListener() {
    Geofire.initialize("availableDrivers");

    // latitude, longitude, max distance from user (15km)
    Geofire.queryAtLocation(
            currentPosition.latitude, currentPosition.longitude, 15)
        ?.listen((map) {
      print(map);

      if (map != null) {
        var callBack = map['callBack'];

        // latitude will be retrieved from map['latitude']
        // longitude will be retrieved from map['longitude']

        switch (callBack) {
          case Geofire.onKeyEntered:
            NearbyAvailableDrivers nearbyAvailableDrivers =
                NearbyAvailableDrivers(
              key: map['key'],
              latitude: map['latitude'],
              longitude: map['longitude'],
            );
            GeofireAssistant.nearbyAvailableDriversList
                .add(nearbyAvailableDrivers);

            if (nearbyAvailableDriverKeysLoaded) {
              updateAvailableDriversOnMap();
            }
            break;

          case Geofire.onKeyExited:
            GeofireAssistant.removeDriverFromList(map['key']);
            updateAvailableDriversOnMap();
            break;

          case Geofire.onKeyMoved:
            // Update your key's location
            NearbyAvailableDrivers nearbyAvailableDrivers =
                NearbyAvailableDrivers(
              key: map['key'],
              latitude: map['latitude'],
              longitude: map['longitude'],
            );
            GeofireAssistant.updateDriverNearbyLocation(nearbyAvailableDrivers);
            updateAvailableDriversOnMap();
            break;

          case Geofire.onGeoQueryReady:
            // All initial Data is loaded
            // add markers on map
            updateAvailableDriversOnMap();
            print(map['result']);
            break;
        }
      }

      setState(() {});
    });
  }

  // actualizeaza markerele pe harta
  void updateAvailableDriversOnMap() {
    setState(() {
      markersSet.clear();
    });

    Set<Marker> tMarkers = Set<Marker>();
    for (var driver in GeofireAssistant.nearbyAvailableDriversList) {
      LatLng driverAvailablePosition =
          LatLng(driver.latitude, driver.longitude);
      Marker marker = Marker(
        markerId: MarkerId('driver${driver.key}'),
        position: driverAvailablePosition,
        icon: nearbyIcon!,
        rotation: AssistantMethods.createRandomNumber(360),
      );

      tMarkers.add(marker);
    }

    setState(() {
      markersSet = tMarkers;
    });
  }

  void createIconMarker() {
    if (nearbyIcon == null) {
      ImageConfiguration imageConfiguration = createLocalImageConfiguration(
        context,
        size: const Size(2, 2),
      );
      BitmapDescriptor.fromAssetImage(
              imageConfiguration, "images/car_android.png")
          .then((value) {
        nearbyIcon = value;
      });
    }
  }

  void noDriverFound() {
    showDialog(
      context: context,
      builder: (BuildContext context) => NoDriverAvailableDialog(),
      barrierDismissible: false,
    );
  }

  void searchNearestDriver() {
    // if there is no driver available
    if (availableDrivers.length == 0) {
      cancelRideRequest();
      resetApp();
      noDriverFound();
      return;
    }

    // daca exista soferi disponibili in zona
    var driver = availableDrivers[0];

    // get the type of the car for this driver
    driversRef
        .child(driver.key)
        .child('car_details')
        .child('type')
        .get()
        .then((snap) async {
      if (snap.value != null) {
        String carType = snap.value.toString();

        // daca este acelasi tip de uber cerut de client, notifica soferul
        if (carType == carRideType) {
          notifyDriver(driver);
          availableDrivers.removeAt(0);
        }
        // daca nu s-a gasit niciun sofer cu tipul de masina cerut
        else {
          AssistantMethods.displayToastMessage(
              '$carRideType driver not available. Please try again later.',
              context);
        }
      } else {
        AssistantMethods.displayToastMessage(
            'No car found. Please try again later.', context);
      }
    });
  }

  // send notification to the driver
  void notifyDriver(NearbyAvailableDrivers driver) {
    // change the newRide value to the rideRequestId
    driversRef.child(driver.key).child("newRide").set(rideRequestRef!.key);

    // get the token of the driver
    driversRef.child(driver.key).child("token").get().then((snap) {
      if (snap.value != null) {
        String token = snap.value.toString();
        AssistantMethods.sendNotificationToDriver(
          token,
          rideRequestRef!.key!,
        );
      } else {
        return;
      }

      // se porneste timerul pentru driverul care este ales
      const oneSecondPassed = Duration(seconds: 1);
      Timer.periodic(oneSecondPassed, (timer) {
        if (state != "requesting") {
          driversRef.child(driver.key).child('newRide').set('cancelled');
          cancelTimer(driver, timer);
        }

        driverRequestTimeout -= 1;

        // daca soferul a acceptat comanda inainte de timeout, anuleaza timer
        driversRef.child(driver.key).child('newRide').onValue.listen((event) {
          if (event.snapshot.value.toString() == 'accepted') {
            cancelTimer(driver, timer);
          }
        });

        // daca driverul nu raspunde in timpul setat, anuleaza comanda pentru acesta
        if (driverRequestTimeout == 0) {
          driversRef.child(driver.key).child("newRide").set("timeout");
          cancelTimer(driver, timer);

          // notifica sofer nou
          searchNearestDriver();
        }
      });
    });
  }

  void cancelTimer(NearbyAvailableDrivers driver, Timer timer) {
    driversRef.child(driver.key).child("newRide").onDisconnect();
    driverRequestTimeout = initDriverRequestTimeout;
    timer.cancel();
  }
}
