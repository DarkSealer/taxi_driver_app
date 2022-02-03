import 'package:firebase_auth/firebase_auth.dart';
import '/models/all_users.dart';

// key for google maps
String mapKey = "AIzaSyAALYM8a49G3M_WTZytgesrxNmMIQersaU";
// cloud messaging key
String serverToken =
    "key=AAAAON-CVIQ:APA91bFA1BL79Ejglw4c6ma3Xk1C5jL1BSkZt0Cqq5h2dElcHNWnYO12HoAJigttJeHCqMiS2y2HfA9_IH8ai93Wz4e9qLDJj67iMebReS8ZAyCiCmep57PuXt-8Tn2rWb4uTXJRAMcQ";
String language = "ro";
User? firebaseUser;
Users? userCurrentInfo;
int initDriverRequestTimeout = 30;
int driverRequestTimeout = initDriverRequestTimeout;
String statusRide = "";
String carDetailsDriver = "";
String driverName = "";
String driverPhone = "";
String rideStatus = 'Driver is Coming';
double starCounter = 0;
String title = '';
String carRideType = '';
