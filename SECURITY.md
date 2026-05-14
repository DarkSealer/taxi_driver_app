# Security

- **Never commit** Google Maps keys, FCM server keys, or other secrets to git.
- Prefer `--dart-define=MAPS_API_KEY=...` and `--dart-define=FCM_AUTH_HEADER=...` for local runs and CI (see [README](README.md)).
- If keys were ever committed publicly, **rotate** them in Google Cloud and Firebase.
