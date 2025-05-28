# quickbites 

quickbites  is a mobile food ordering application built with Flutter and Firebase. It allows customers to browse food menus from various vendors, place orders, and track their delivery status. Vendors can manage their menus, receive orders, and update order statuses.

## Features

- User authentication (buyers and sellers)
- Menu browsing and filtering
- Real-time order tracking
- Seller dashboard for menu and order management
- Firebase integration for backend services

## Technologies

- Flutter for cross-platform mobile development
- Firebase for backend services:
  - Authentication
  - Firestore Database
  - Firebase Storage

## Getting Started

### Prerequisites

- Flutter SDK
- Android Studio or Visual Studio Code
- Firebase account

### Setup

1. Clone this repository
2. Run `flutter pub get` to install dependencies
3. Configure Firebase:
   - Follow instructions in the `FIREBASE_SETUP.md` file
   - Add required Firebase configuration files (not included in the repository for security)

### Firebase Configuration Files

The following sensitive files are excluded from version control:
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

You will need to create these files from your Firebase console and add them to your local project.

## Development

Run the application in debug mode:

```
flutter run
```

## Building for Production

Android:
```
flutter build apk --release
```

iOS:
```
flutter build ios --release
```

## Project Structure

- `lib/` - Main source code
  - `screens/` - UI screens
  - `widgets/` - Reusable UI components
  - `providers/` - State management
  - `services/` - API and backend services
  - `models/` - Data models
  - `utils/` - Utility functions and constants
