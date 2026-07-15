# Tailor Management System (TailorPro)

A production-ready Tailor Management System built with Flutter, Dart, and Riverpod using a **Feature-First Clean Architecture**.

## Project Structure

The project follows a Clean Architecture structure organized by features:

```text
lib/
├── core/                  # Core configurations and services
│   ├── database/          # SQLite database services (sqflite)
│   ├── di/                # Dependency injection setup (get_it)
│   ├── logger/            # Application logger configuration
│   ├── navigation/        # Routing configuration (go_router)
│   ├── security/          # Password hashing and secure storage (flutter_secure_storage)
│   ├── services/          # Offline backup & restore services
│   └── theme/             # Material Design 3 theme configuration
├── features/              # Feature modules
│   ├── authentication/    # Splash, Login, Register, Password Recovery
│   ├── customers/         # Customers list, Customer profile, Measurements
│   ├── dashboard/         # Bento statistics, Quick actions, Today's schedule
│   ├── orders/            # Order list, New order creation, Status pipeline
│   ├── search/            # Unified global search
│   └── settings/          # Shop profile, Local data backup & restore
├── shared/                # Shared widgets and layout wrappers
│   └── components/        # MainLayout (Bottom Navigation Bar)
├── app.dart               # Root application widget
└── main.dart              # Application entry point (initialization & DI setup)
```

---

## How to Start and Run the App

Since the repository currently contains only the source code (`lib/` and `pubspec.yaml`), you need to initialize the platform configurations and set up Flutter on your local machine.

### Prerequisites

1. **Install Flutter SDK**:
   - Download the latest stable version of Flutter from the [official website](https://docs.flutter.dev/get-started/install).
   - Extract it and add the `flutter/bin` folder to your system's `PATH` environment variable.

2. **Verify Setup**:
   - Run the following command in your terminal to ensure Flutter is properly configured and can see your devices (emulators/browsers):
     ```bash
     flutter doctor
     ```

---

### Step-by-Step Setup

1. **Initialize Platforms**:
   Generate the platform-specific project folders (Android, iOS, Web, Windows, etc.) by running this command in the project root:
   ```bash
   flutter create --platforms=android,ios,web .
   ```

2. **Retrieve Dependencies**:
   Restore the packages listed in `pubspec.yaml` (such as Riverpod, GoRouter, sqflite, etc.):
   ```bash
   flutter pub get
   ```

3. **Run the Application**:
   - To list available devices:
     ```bash
     flutter devices
     ```
   - To run on a specific device (e.g. Chrome, Android Emulator, iOS Simulator):
     ```bash
     flutter run
     ```
     *(Example for Web: `flutter run -d chrome`)*
