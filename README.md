# TripPick / 旅先ピック

TripPick is a bilingual Flutter Web demo that recommends three travel
destinations from a user's origin country, domestic/international preference,
budget level, trip length, interests, and optional travel month.

The Flutter client never receives Gemini credentials. A local Dart server
validates requests, asks Gemini for destination cities and attraction names,
and returns display-ready data with ordinary Google Maps search links.

## Requirements

- Flutter with Dart 3.11 or newer
- Chrome
- Gemini API key for live mode

## Quick start with fake data

The fake server is deterministic and requires no API credentials.

```sh
cd server
cp .env.example .env
dart pub get
dart run bin/server.dart
```

In a second terminal:

```sh
flutter pub get
flutter run -d chrome --web-port=3000 \
  --dart-define=BACKEND_BASE_URL=http://localhost:8080
```

Alternatively, run the Flutter-only fake repository without the server:

```sh
flutter run -d chrome --web-port=3000 \
  --dart-define=USE_FAKE_REPOSITORY=true
```

## Live API mode

Create `server/.env` from `.env.example`, then set:

```text
GEMINI_API_KEY=your_key
GEMINI_MODEL=gemini-3.5-flash-lite
PORT=8080
ALLOWED_ORIGIN=http://localhost:3000
USE_FAKE_APIS=false
```

Keep the Gemini key out of Git and configure an appropriate quota before live
testing. Google Maps search links do not require an API key.

## Verification

```sh
flutter gen-l10n
dart format lib test
flutter analyze
flutter test

cd server
dart format bin lib test
dart analyze
dart test
```

## MVP boundaries

Budget is a soft preference, not a price quote. The demo does not calculate
flights, accommodation, food, or total trip costs. It also excludes accounts,
bookings, saved trips, analytics, itineraries, restaurant menus, and embedded
maps. The local server must be deployed and hardened before the web client can
be published for public use.
