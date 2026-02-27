# Izwi Notifications .NET API

ASP.NET Core 8 Web API backend for authentication, user management, and notification persistence.

## Folder Scope

This README applies only to `dotnet_api/`.

## Features

- JWT authentication and authorization
- User endpoints (admin add/list + registration completion)
- Notification endpoints (create, received, sent, mark read)
- Device token registration
- SQL Server persistence via Entity Framework Core
- Swagger documentation in development

## Tech Stack

- .NET 8 (ASP.NET Core)
- Entity Framework Core + SQL Server
- JWT Bearer Authentication
- Swagger / OpenAPI

## Prerequisites

- .NET SDK 8.x
- SQL Server accessible by your connection string

## Configuration

Edit `appsettings.json`:
- `ConnectionStrings:DefaultConnection`
- `JwtSettings:SecretKey`
- `JwtSettings:Issuer`
- `JwtSettings:Audience`

Example connection string format:

```json
"DefaultConnection": "Server=localhost;Database=IzwiNotificationsDb;Trusted_Connection=True;TrustServerCertificate=True;"
```

## Setup

```bash
cd dotnet_api
dotnet restore
```

## Database Migrations

```bash
dotnet ef migrations add InitialCreate
dotnet ef database update
```

If models change:

```bash
dotnet ef migrations add <MigrationName>
dotnet ef database update
```

## Run

```bash
dotnet run
```

Swagger (development):
- `https://localhost:<port>/swagger`

## Main Endpoints

Base: `/api`

### Auth
- `POST /api/auth/login`
- `POST /api/auth/register`
- `POST /api/auth/refresh`
- `POST /api/auth/logout`
- `POST /api/auth/forgot-password`
- `POST /api/auth/reset-password`

### Users
- `GET /api/users` (Admin)
- `POST /api/users/addUser` (Admin)
- `POST /api/users/registerUser`

### Notifications
- `GET /api/notifications/my`
- `GET /api/notifications/sent`
- `GET /api/notifications` (Admin)
- `POST /api/notifications` (Admin)
- `PUT /api/notifications/{id}/read`
- `PUT /api/notifications/read-all`
- `POST /api/notifications/device-token`

## Development Notes

- CORS is permissive for development.
- On startup in development, migrations are applied and seed data is inserted.
- Keep secrets out of source control for production.

## Verify Build

```bash
dotnet build
```