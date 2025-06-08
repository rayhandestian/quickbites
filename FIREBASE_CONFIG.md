# Firebase Configuration in quickbites 

## Configuration Files

This app uses two key Firebase configuration files:

1. **google-services.json**: This is the standard Android configuration file for Firebase. It contains the actual API keys and service identifiers needed for Firebase services. This file is **not** committed to the repository for security reasons.

2. **firebase_options.dart**: This is a Dart file that Flutter uses to access Firebase configuration. Our implementation uses placeholder values instead of hardcoded credentials, as the Firebase SDK automatically reads the real values from google-services.json at runtime.

## Why Both Files?

- **google-services.json** is the standard way to configure Firebase for Android apps, and it's automatically recognized by the Firebase SDK.
- **firebase_options.dart** is required by Flutter to provide the Firebase configuration in Dart code, but we're using it with placeholders to avoid exposing sensitive information in our source code.

## Security Best Practices

1. **Never commit google-services.json** to a public repository
2. Use placeholder values in firebase_options.dart
3. Keep .env files out of version control
4. Regularly rotate API keys if you suspect they've been compromised

## Local Development Setup

1. Download the google-services.json file from your Firebase console
2. Place it in the android/app/ directory
3. Create a .env file with your Cloudinary credentials
4. Run the app - the Firebase SDK will automatically read the correct values at runtime 