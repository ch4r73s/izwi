# Izwi Notifications Flutter App

Flutter client for creating and viewing notifications (SMS-style outbound messages), managing recipients, and handling user-facing flows.

```bash
taskkill /f /im java.exe
.\gradlew --stop
rd /s /q "C:\Users\EMF Dev\.gradle\caches\8.10.2"
flutter clean
flutter pub get
flutter run
# Expose to public network
ngrok http https://localhost:44344 --host-header=localhost:44344
```

## Folder Scope

This README applies only to `flutter_app/`.

## Features

- Authentication UI with role-based navigation
- Notification list and detail views
- Create notification flow
- Recipient/client management screens
- Settings and theme support

## Tech Stack

- Flutter (Dart)
- `provider` for state management
- `http` for API calls
- `sqflite` for local notification persistence (current implementation)

## Prerequisites

- Flutter SDK (stable channel)
- Android Studio / VS Code + Flutter extensions
- Platform toolchains for your target (Android/iOS/Web/Desktop)

## Setup

```bash
cd flutter_app
flutter pub get
```

## Run

```bash
flutter run
```

## Build Examples

```bash
flutter build apk
flutter build web
```

## Key Directories

- `lib/screens/` UI screens
- `lib/services/` service logic
- `lib/models/` app models
- `lib/config/` route configuration
- `assets/` static assets and contact file

## API Integration Notes

Some screens still use placeholder endpoints and/or local storage:
- `lib/screens/admin/clients.dart`
- `lib/screens/admin/user_registration.dart`
- `lib/services/database/` (local SQLite notification storage)

For backend integration, target the .NET API endpoints in `../dotnet_api`.

## Testing

```bash
flutter test
```

## Current Gaps

- Auth screen currently uses local hardcoded credentials in UI flow.
- Notifications screen currently reads from local SQLite, not backend API.

## Recommended Next Steps

1. Centralize API base URL in one config file.
2. Add bearer-token interceptor/header management for protected endpoints.
3. Replace local notification DAO read/write with API-backed repository.