# Taxi / Rideshare Passenger App

A Flutter mobile client for requesting and tracking on-demand rides. The app
connects passengers to nearby drivers using a live map, Firebase-backed
presence and ride state, and Google routing for estimates and turn-by-turn
context.

> **Note:** The Dart package name is `taxi_rider_app` (see `pubspec.yaml`).
> The repository folder may appear as `taxi_driver_app` depending on your
> checkout.

---

## Highlights

- **Authentication** — Email-based sign-in and registration via Firebase Auth.
- **Live map** — Google Maps with pickup/drop-off selection, route polylines,
  and markers for trip context.
- **Driver discovery** — Geo-indexed nearby driver queries using Geofire-style
  data against Firebase Realtime Database.
- **Ride lifecycle** — Request flow, driver assignment, status updates, and
  post-trip rating.
- **Account area** — Profile, trip history, and about screens.

This project demonstrates integration of real-time backends, location services,
and third-party mapping APIs in a single cross-platform codebase.

---

## Tech Stack

| Area | Technology |
|------|------------|
| UI & framework | [Flutter](https://flutter.dev/) (Dart) |
| State management | [Provider](https://pub.dev/packages/provider) (`ChangeNotifier`) |
| Backend & auth | [Firebase Core](https://firebase.google.com/docs/flutter/setup), [Firebase Auth](https://firebase.google.com/docs/auth), [Firebase Realtime Database](https://firebase.google.com/docs/database) |
| Maps & location | [google_maps_flutter](https://pub.dev/packages/google_maps_flutter), [geolocator](https://pub.dev/packages/geolocator), [flutter_polyline_points](https://pub.dev/packages/flutter_polyline_points) |
| Geo queries | [flutter_geofire](https://pub.dev/packages/flutter_geofire) |
| Networking | [http](https://pub.dev/packages/http) (e.g. directions / places helpers) |
| UX | Custom typography (Bolt / Signatra), [animated_text_kit](https://pub.dev/packages/animated_text_kit), [font_awesome_flutter](https://pub.dev/packages/font_awesome_flutter) |

---

## Project Structure

```
lib/
├── assistants/       # Geocoding, directions, Geofire helpers
├── datahandler/      # App-wide pick/drop state and trip history (Provider)
├── models/           # User, address, directions, history, predictions
├── screens/          # Login, register, main map, search, history, profile, etc.
├── widgets/          # Reusable dialogs and list items
├── configmaps.dart   # API keys and runtime constants (see setup)
└── main.dart         # Firebase init, routes, Provider root
```

---

## Prerequisites

- [Flutter](https://docs.flutter.dev/get-started/install) SDK compatible with
  `sdk: ">=2.12.0 <3.0.0"` in `pubspec.yaml` (upgrade the constraint if you move
  to a newer Dart SDK).
- A [Firebase](https://console.firebase.google.com/) project with **Realtime
  Database** and **Authentication** enabled, and FlutterFire / platform config
  (`google-services.json`, `GoogleService-Info.plist`) added per
  [official setup](https://firebase.google.com/docs/flutter/setup).
- [Google Maps API](https://developers.google.com/maps/flutter-package) keys
  with Maps SDK for Android/iOS and any Places/Directions endpoints your
  assistants use.

---

## Setup

1. **Clone the repository** and open it in your editor.

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Configure Firebase** — Add your Firebase app to the Android and iOS
   runners and ensure database security rules match your intended demo or
   production model.

4. **Configure secrets locally** — Put Google Maps and any server tokens in
   `lib/configmaps.dart` (or refactor to `--dart-define` / env files). **Do not
   commit real production keys** to public repositories; use placeholders in
   version control and inject secrets in CI or local-only files.

5. **Run**

   ```bash
   flutter run
   ```

---

## Testing

```bash
flutter test
```

---

## Status & Disclaimer

This codebase is suitable as a **portfolio / learning** reference for Flutter,
Firebase, and maps integration. Production hardening would include stricter
rules on Realtime Database, key management outside source control, error
surfacing, and updated dependency versions.

---

## License

This project is not published to pub.dev (`publish_to: 'none'`). Add a
`LICENSE` file in the repository if you intend to specify terms for reuse.
