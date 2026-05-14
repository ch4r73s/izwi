# Velvet Masowe Notifications App

Full-stack notification platform for creating, sending, and tracking outbound notifications (SMS-style messages) with:
- Flutter client app (`flutter_app`)
- ASP.NET Core Web API backend (`dotnet_api`)

## Project Structure

- `flutter_app/` Flutter mobile/web/desktop client
- `dotnet_api/` ASP.NET Core 8 API with JWT auth + EF Core (SQL Server)

## Features

### Flutter App
- Role-based login UX (`admin`, `user`, `guest` flows currently present in UI)
- Notification list and detail screens
- Create notification screen
- Recipient/client management screens
- Settings and theme support

### .NET API
- JWT authentication and authorization
- User management endpoints
- Notification endpoints for:
  - creating notifications
  - pulling received notifications
  - pulling sent notifications
  - marking notifications as read
- Device token registration endpoint
- SQL Server persistence via EF Core

## Prerequisites

- Flutter SDK (stable)
- .NET SDK 8.x
- SQL Server instance (local or remote)

## Backend Setup (`dotnet_api`)

1. Open `dotnet_api/appsettings.json` and configure:
- `ConnectionStrings:DefaultConnection`
- `JwtSettings:SecretKey` (must be strong and at least 32 chars)
- `JwtSettings:Issuer`
- `JwtSettings:Audience`

2. Restore and run:

```bash
cd dotnet_api
dotnet restore
dotnet ef migrations add InitialCreate
dotnet ef database update
dotnet run
```

Swagger will be available in development at:
- `https://localhost:<port>/swagger`

## Flutter Setup (`flutter_app`)

1. Install packages:

```bash
cd flutter_app
flutter pub get
```

2. Run app:

```bash
flutter run
```

## Notes

- Each internal project now has its own focused README:
  - `flutter_app/README.md`
  - `dotnet_api/README.md`