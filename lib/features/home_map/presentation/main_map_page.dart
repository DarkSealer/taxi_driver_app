import 'dart:async';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:taxi_rider_app/assistants/assistant_methods.dart';
import 'package:taxi_rider_app/core/providers/firebase_providers.dart';
import 'package:taxi_rider_app/features/auth/presentation/providers/current_user_provider.dart';
import 'package:taxi_rider_app/features/history/application/sync_trip_history.dart';
import 'package:taxi_rider_app/features/history/presentation/pages/history_page.dart';
import 'package:taxi_rider_app/features/home_map/presentation/providers/nearby_drivers_provider.dart';
import 'package:taxi_rider_app/features/places_search/presentation/pages/search_page.dart';
import 'package:taxi_rider_app/features/profile/presentation/pages/profile_page.dart';
import 'package:taxi_rider_app/features/rating/presentation/pages/rating_page.dart';
import 'package:taxi_rider_app/features/ride_request/presentation/providers/ride_session_provider.dart';
import 'package:taxi_rider_app/features/trip_places/presentation/providers/trip_places_provider.dart';
import 'package:taxi_rider_app/models/direction_details.dart';
import 'package:taxi_rider_app/models/nearby_available_drivers.dart';
import 'package:taxi_rider_app/widgets/collect_fare_dialog.dart';
import 'package:taxi_rider_app/widgets/dividerwidget.dart';
import 'package:taxi_rider_app/widgets/no_driver_available_dialog.dart';
import 'package:taxi_rider_app/widgets/progressdialog.dart';
import 'package:url_launcher/url_launcher.dart';

class MainMapPage extends ConsumerStatefulWidget {
  const MainMapPage({super.key});

  @override
  ConsumerState<MainMapPage> createState() => _MainMapPageState();
}

class _MainMapPageState extends ConsumerState<MainMapPage> {
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
  /// normal | requesting — avoids shadowing [State.state].
  String rideRequestFlowState = 'normal';

  List<NearbyAvailableDrivers> _driverAssignmentQueue = [];
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

      driverDetailsContainerHeight = 0;
    });

    ref.read(rideSessionProvider.notifier).reset();
    ref.read(nearbyDriversProvider.notifier).clear();
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

    await AssistantMethods.searchCoordinateAddress(ref, position);

    await syncTripHistoryForCurrentUser(ref);

    final user = ref.read(currentUserProvider);
    uName = user?.name ?? '';

    initGeofireListener();
  }

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentUserProvider.notifier).loadFromRemote();
    });
  }

  // store the clients data in DB
  void saveRideRequest() {
    final trip = ref.read(tripPlacesProvider);
    final user = ref.read(currentUserProvider);
    final session = ref.read(rideSessionProvider);
    if (user == null) {
      AssistantMethods.displayToastMessage(
        'User profile not loaded yet. Please wait and try again.',
        context,
      );
      return;
    }

    rideRequestRef = ref.read(rideRequestsDatabaseRefProvider).push();

    final pickUp = trip.pickUpLocation;
    final dropOff = trip.dropOffLocation;

    final pickUpLocationMap = {
      'latitude': pickUp?.latitude.toString(),
      'longitude': pickUp?.longitude.toString(),
    };

    final dropOffLocationMap = {
      'latitude': dropOff?.latitude.toString(),
      'longitude': dropOff?.longitude.toString(),
    };

    final riderInfoMap = {
      'driver_id': 'waiting',
      'payment_method': 'cash',
      'pickup': pickUpLocationMap,
      'dropoff': dropOffLocationMap,
      'created_at': DateTime.now().toString(),
      'rider_name': user.name,
      'rider_phone': user.phone,
      'pickup_address': pickUp!.placeName,
      'dropoff_address': dropOff!.placeName,
      'ride_type': session.carRideType,
    };

    rideRequestRef!.set(riderInfoMap);

    rideStreamSubscription = rideRequestRef!.onValue.listen((event) async {
      if (event.snapshot.value == null) {
        return;
      }

      final values = event.snapshot.value as Map<dynamic, dynamic>;
      final rideSession = ref.read(rideSessionProvider.notifier);

      if (values['car_details'] != null) {
        rideSession.setDriverDetails(
          carDetails: values['car_details'].toString(),
        );
      }

      if (values['driver_name'] != null) {
        rideSession.setDriverDetails(
          name: values['driver_name'].toString(),
        );
      }

      if (values['driver_location'] != null) {
        final driverLat =
            double.parse(values['driver_location']['latitude'].toString());
        final driverLng =
            double.parse(values['driver_location']['longitude'].toString());

        final driverCurrentLocation = LatLng(driverLat, driverLng);

        final statusRide = ref.read(rideSessionProvider).statusRide;
        if (statusRide == 'accepted') {
          updateRideTimeToPickUpLoc(driverCurrentLocation);
        } else if (statusRide == 'onride') {
          updateRideTimeToDropOffLoc(driverCurrentLocation);
        } else if (statusRide == 'arrived') {
          rideSession.setRideStatusLabel('Driver has Arrived');
        }
      }

      if (values['driver_phone'] != null) {
        rideSession.setDriverDetails(
          phone: values['driver_phone'].toString(),
        );
      }

      if (values['status'] != null) {
        rideSession.setStatusRide(values['status'].toString());
      }

      final statusRide = ref.read(rideSessionProvider).statusRide;
      if (statusRide == 'accepted') {
        displayDriverDetailsContainer();
        Geofire.stopListener();
        deleteGeofireMarkers();
      }

      if (statusRide == 'ended') {
        if (values['fares'] != null) {
          final fare = int.parse(values['fares'].toString());
          final res = await showDialog<dynamic>(
            context: context,
            builder: (BuildContext context) =>
                CollectFareDialog(paymentMethod: 'cash', fareAmount: fare),
          );

          var driverId = '';
          if (res == 'close') {
            if (values['driver_id'] != null) {
              driverId = values['driver_id'].toString();
            }

            if (!mounted) {
              return;
            }
            await Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (context) => RatingPage(driverId: driverId),
              ),
            );

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
        ref,
        driverCurrentLocation,
        positionUserLatLng,
      );

      if (details == null) {
        return;
      }

      ref.read(rideSessionProvider.notifier).setRideStatusLabel(
            'Driver is Coming - ${details.durationText}',
          );

      isRequestingPositionDetails = false;
    }
  }

  void updateRideTimeToDropOffLoc(LatLng driverCurrentLocation) async {
    if (!isRequestingPositionDetails) {
      isRequestingPositionDetails = true;

      final dropOffLoc = ref.read(tripPlacesProvider).dropOffLocation;
      final dropOffLatLng =
          LatLng(dropOffLoc!.latitude, dropOffLoc.longitude);

      // obtine detaliile calatoriei (timpul de ajungere a soferului la adresa clientului)
      var details = await AssistantMethods.obtainDirectionsDetails(
        ref,
        driverCurrentLocation,
        dropOffLatLng,
      );

      if (details == null) {
        return;
      }

      ref.read(rideSessionProvider.notifier).setRideStatusLabel(
            'Going to Destination - ${details.durationText}',
          );

      isRequestingPositionDetails = false;
    }
  }

  // cancel the request
  void cancelRideRequest() {
    // removes the entry from db
    rideRequestRef!.remove();
    setState(() {
      rideRequestFlowState = 'normal';
    });
  }

  @override
  Widget build(BuildContext context) {
    final rideUi = ref.watch(rideSessionProvider);
    final trip = ref.watch(tripPlacesProvider);
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
                            Navigator.push<void>(
                              context,
                              MaterialPageRoute<void>(
                                builder: (context) => const ProfilePage(),
                              ),
                            );
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
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => const HistoryPage(),
                    ),
                  );
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
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (context) => const ProfilePage(),
                      ),
                    );
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
                  context.push('/about');
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
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  ref.read(currentUserProvider.notifier).clear();
                  if (context.mounted) {
                    context.go('/login');
                  }
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
                          var res = await Navigator.push<dynamic>(
                            context,
                            MaterialPageRoute<dynamic>(
                              builder: (context) => const SearchPage(),
                            ),
                          );

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
                                trip.pickUpLocation != null
                                    ? trip.pickUpLocation!.placeName
                                    : 'Add Home',
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
                          AssistantMethods.displayToastMessage(
                            'searching bike...',
                            context,
                          );
                          ref.read(rideSessionProvider.notifier).setCarRideType(
                                'bike',
                              );
                          setState(() {
                            rideRequestFlowState = 'requesting';
                          });
                          _driverAssignmentQueue = List.of(
                            ref.read(nearbyDriversProvider),
                          );
                          displayRequestRideContainer();
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
                          AssistantMethods.displayToastMessage(
                            'searching Uber-Go...',
                            context,
                          );
                          ref.read(rideSessionProvider.notifier).setCarRideType(
                                'uber-go',
                              );
                          setState(() {
                            rideRequestFlowState = 'requesting';
                          });
                          _driverAssignmentQueue = List.of(
                            ref.read(nearbyDriversProvider),
                          );
                          displayRequestRideContainer();
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
                          AssistantMethods.displayToastMessage(
                            'searching Uber-X...',
                            context,
                          );
                          ref.read(rideSessionProvider.notifier).setCarRideType(
                                'uber-x',
                              );
                          setState(() {
                            rideRequestFlowState = 'requesting';
                          });
                          _driverAssignmentQueue = List.of(
                            ref.read(nearbyDriversProvider),
                          );
                          displayRequestRideContainer();
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
                        onTap: () {},
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
                          rideUi.rideStatusLabel,
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
                      rideUi.carDetailsDriver,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    Text(
                      rideUi.driverName,
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
                                Uri.parse('tel:${rideUi.driverPhone}'),
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
    final trip = ref.read(tripPlacesProvider);
    final initialPos = trip.pickUpLocation;
    final finalPos = trip.dropOffLocation;

    final pickUpLatLng = LatLng(initialPos!.latitude, initialPos.longitude);
    final dropOffLatLng = LatLng(finalPos!.latitude, finalPos.longitude);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const ProgressDialog(
        message: 'Please wait...',
      ),
    );

    final details = await AssistantMethods.obtainDirectionsDetails(
      ref,
      pickUpLatLng,
      dropOffLatLng,
    );

    if (!mounted) {
      return;
    }
    Navigator.pop(context);

    if (details == null) {
      AssistantMethods.displayToastMessage(
        'Could not load directions. Check MAPS_API_KEY.',
        context,
      );
      return;
    }

    setState(() {
      tripDirectionDetails = details;
    });

    final polylinePoints = PolylinePoints();
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
      if (map != null) {
        final callBack = map['callBack'];
        final driversNotifier = ref.read(nearbyDriversProvider.notifier);

        switch (callBack) {
          case Geofire.onKeyEntered:
            final nearbyAvailableDrivers = NearbyAvailableDrivers(
              key: map['key'],
              latitude: map['latitude'],
              longitude: map['longitude'],
            );
            driversNotifier.onKeyEntered(nearbyAvailableDrivers);

            if (nearbyAvailableDriverKeysLoaded) {
              updateAvailableDriversOnMap();
            }
            break;

          case Geofire.onKeyExited:
            driversNotifier.onKeyExited(map['key'] as String);
            updateAvailableDriversOnMap();
            break;

          case Geofire.onKeyMoved:
            final nearbyAvailableDrivers = NearbyAvailableDrivers(
              key: map['key'],
              latitude: map['latitude'],
              longitude: map['longitude'],
            );
            driversNotifier.onKeyMoved(nearbyAvailableDrivers);
            updateAvailableDriversOnMap();
            break;

          case Geofire.onGeoQueryReady:
            updateAvailableDriversOnMap();
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

    final tMarkers = <Marker>{};
    for (final driver in ref.read(nearbyDriversProvider)) {
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
    if (_driverAssignmentQueue.isEmpty) {
      cancelRideRequest();
      resetApp();
      noDriverFound();
      return;
    }

    final driver = _driverAssignmentQueue.first;
    final driversRef = ref.read(driversDatabaseRefProvider);
    final rideType = ref.read(rideSessionProvider).carRideType;

    driversRef
        .child(driver.key)
        .child('car_details')
        .child('type')
        .get()
        .then((snap) async {
      if (snap.value != null) {
        final carType = snap.value.toString();

        if (carType == rideType) {
          notifyDriver(driver);
          _driverAssignmentQueue.removeAt(0);
        } else {
          AssistantMethods.displayToastMessage(
            '$rideType driver not available. Please try again later.',
            context,
          );
        }
      } else {
        AssistantMethods.displayToastMessage(
          'No car found. Please try again later.',
          context,
        );
      }
    });
  }

  // send notification to the driver
  void notifyDriver(NearbyAvailableDrivers driver) {
    final driversRef = ref.read(driversDatabaseRefProvider);
    driversRef.child(driver.key).child('newRide').set(rideRequestRef!.key);

    driversRef.child(driver.key).child('token').get().then((snap) {
      if (snap.value != null) {
        final token = snap.value.toString();
        AssistantMethods.sendNotificationToDriver(
          token,
          rideRequestRef!.key!,
        );
      } else {
        return;
      }

      const oneSecondPassed = Duration(seconds: 1);
      Timer.periodic(oneSecondPassed, (timer) {
        if (rideRequestFlowState != 'requesting') {
          driversRef.child(driver.key).child('newRide').set('cancelled');
          cancelTimer(driver, timer);
        }

        ref.read(rideSessionProvider.notifier).decrementDriverRequestTimeout();

        driversRef.child(driver.key).child('newRide').onValue.listen((event) {
          if (event.snapshot.value.toString() == 'accepted') {
            cancelTimer(driver, timer);
          }
        });

        if (ref.read(rideSessionProvider).driverRequestTimeoutSeconds == 0) {
          driversRef.child(driver.key).child('newRide').set('timeout');
          cancelTimer(driver, timer);

          searchNearestDriver();
        }
      });
    });
  }

  void cancelTimer(NearbyAvailableDrivers driver, Timer timer) {
    ref.read(driversDatabaseRefProvider).child(driver.key).child('newRide').onDisconnect();
    ref.read(rideSessionProvider.notifier).resetDriverRequestTimeout();
    timer.cancel();
  }
}
