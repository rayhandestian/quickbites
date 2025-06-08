# Firebase Setup for QuickBites 

This document provides instructions for setting up Firebase for the QuickBites application.

## 1. Create a Firebase Project

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" and follow the setup wizard
3. Name your project (e.g., "QuickBites")
4. Configure Google Analytics if desired
5. Click "Create project"

## 2. Register Your App with Firebase

### For Android:

1. In the Firebase console, click on the Android icon to add an Android app
2. Enter your app's package name (found in `android/app/build.gradle` under `applicationId`)
3. Enter a nickname for your app (e.g., "QuickBites Android")
4. Enter your app's SHA-1 signing certificate (optional for development)
5. Click "Register app"
6. Download the `google-services.json` file
7. Place the file in the `android/app/` directory of your Flutter project

### For iOS:

1. In the Firebase console, click on the iOS icon to add an iOS app
2. Enter your app's bundle ID (found in your Xcode project settings)
3. Enter a nickname for your app (e.g., "QuickBites iOS")
4. Enter your App Store ID (optional)
5. Click "Register app"
6. Download the `GoogleService-Info.plist` file
7. Open your Flutter project in Xcode and add the file to the Runner directory (right-click Runner and select "Add Files to Runner")

## 3. Set Up Firebase Authentication

1. In the Firebase console, go to "Authentication"
2. Click "Get started"
3. Enable the "Email/Password" sign-in method
4. Optionally, configure other sign-in methods as needed

## 4. Set Up Firestore Database

1. In the Firebase console, go to "Firestore Database"
2. Click "Create database"
3. Start in test mode for development (you can update security rules later)
4. Choose a database location closest to your users
5. Click "Enable"

## 5. Create Firestore Collections

Create the following collections in Firestore:

### Users Collection

```
users/
  [user_id]/
    name: string
    email: string
    role: string ("buyer" or "seller")
    storeName: string (optional, for sellers)
    createdAt: timestamp
```

### Menus Collection

```
menus/
  [menu_id]/
    name: string
    price: number
    stock: number
    tenantId: string (reference to a tenant document)
    category: string
```

### Orders Collection

```
orders/
  [order_id]/
    buyerId: string (reference to a user document)
    menuId: string (reference to a menu document)
    quantity: number
    customNote: string (optional)
    status: string ("created", "ready", "completed", etc.)
    timestamp: timestamp
```

### Tenants Collection

```
tenants/
  [tenant_id]/
    name: string
    sellerId: string (reference to a user document)
    description: string
```

## 6. Update Firebase Security Rules

Update your Firestore security rules to secure your data. Here's a basic example:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow authenticated users to read all data
    match /{document=**} {
      allow read: if request.auth != null;
    }
    
    // Users collection rules
    match /users/{userId} {
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Orders collection rules
    match /orders/{orderId} {
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
        (resource.data.buyerId == request.auth.uid || 
        get(/databases/$(database)/documents/tenants/$(resource.data.tenantId)).data.sellerId == request.auth.uid);
    }
    
    // Menus collection rules
    match /menus/{menuId} {
      allow create, update, delete: if request.auth != null && 
        get(/databases/$(database)/documents/tenants/$(request.resource.data.tenantId)).data.sellerId == request.auth.uid;
    }
    
    // Tenants collection rules
    match /tenants/{tenantId} {
      allow create, update, delete: if request.auth != null && 
        request.resource.data.sellerId == request.auth.uid;
    }
  }
}
```

## 7. Initialize Firebase in the App

The QuickBites app is already configured to initialize Firebase in the `main.dart` file. Make sure you have the following packages in your `pubspec.yaml`:

```yaml
dependencies:
  firebase_core: ^2.26.0
  cloud_firestore: ^4.15.7
  firebase_auth: ^4.16.0
```

## Troubleshooting

If you encounter any issues:

1. Ensure you've placed the configuration files in the correct locations
2. Verify that you've added the correct package dependencies
3. Run `flutter clean` and then `flutter pub get`
4. Check that your Firebase project is properly configured

For more detailed Firebase setup instructions, refer to the [official Flutter Firebase documentation](https://firebase.flutter.dev/docs/overview). 