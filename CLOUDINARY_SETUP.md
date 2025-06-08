# Cloudinary Setup for quickbites 

This guide explains how to set up Cloudinary for image uploads in the quickbites  app.

## 1. Create a Cloudinary Account

1. Go to [Cloudinary's website](https://cloudinary.com/) and sign up for a free account.
2. After signing up and verifying your email, you'll be directed to your Cloudinary dashboard.

## 2. Get Your Cloudinary Credentials

From your dashboard:

1. Note your **Cloud Name** (shown at the top of the dashboard)
2. Create an upload preset:
   - Go to Settings > Upload
   - Scroll down to "Upload presets"
   - Click "Add upload preset"
   - Set "Signing Mode" to "Unsigned" (for this simple implementation)
   - Name your preset (e.g., "quickbites _preset")
   - Save the preset

## 3. Configure the App

1. Open `lib/services/cloudinary_service.dart`
2. Replace the placeholder values with your Cloudinary credentials:

```dart
static const String _cloudName = 'your_cloud_name'; // Replace with your cloud name
static const String _uploadPreset = 'your_upload_preset'; // Replace with your upload preset name
```

## 4. Testing Your Setup

1. Run the app
2. Go to the seller inventory screen
3. Try adding a new menu item with an image
4. If the image uploads successfully and appears in the menu item, your setup is working correctly!

## 5. Cloudinary Dashboard Features

You can manage your uploaded images through the Cloudinary dashboard:

- View all uploads in the Media Library
- Monitor usage and performance in the Dashboard
- Set up transformations to automatically resize/optimize images

## 6. Advanced Configuration (Optional)

For a production app, consider these additional steps:

- Set up signed uploads for better security
- Configure auto-tagging and categorization
- Set up eager transformations to process images on upload
- Configure delivery profiles for optimized delivery

## 7. Troubleshooting

If you encounter issues:

- Check that your cloud name and upload preset are correct
- Ensure the upload preset is set to "unsigned" for this implementation
- Check the Flutter console for any error messages
- Verify your internet connection
- Check if your Cloudinary free tier limits have been exceeded

## 8. Security Considerations

This implementation uses unsigned uploads for simplicity. For a production app, consider:

- Using signed uploads with a server-side component
- Setting up proper access controls for your Cloudinary resources
- Implementing rate limiting to prevent abuse
- Setting up proper backup strategies for uploaded content

## 9. Additional Resources

- [Cloudinary Documentation](https://cloudinary.com/documentation)
- [Flutter Cloudinary Package Documentation](https://pub.dev/packages/cloudinary_public)
- [Image Upload Best Practices](https://cloudinary.com/documentation/upload_images) 