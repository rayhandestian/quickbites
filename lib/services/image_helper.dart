import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImageHelper {
  static final ImagePicker _picker = ImagePicker();

  // Pick image from gallery
  static Future<File?> pickImageFromGallery({
    double? maxWidth,
    double? maxHeight,
    int? quality,
  }) async {
    try {
      debugPrint('Opening gallery to pick image...');
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: quality,
      );

      if (pickedFile != null) {
        debugPrint('Image picked from gallery: ${pickedFile.path}');
        final File imageFile = File(pickedFile.path);
        debugPrint('File exists: ${await imageFile.exists()}, Size: ${await imageFile.length()} bytes');
        return imageFile;
      } else {
        debugPrint('No image selected from gallery');
      }
      return null;
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
      debugPrint('Error stack trace: ${StackTrace.current}');
      return null;
    }
  }

  // Pick image from camera
  static Future<File?> pickImageFromCamera({
    double? maxWidth,
    double? maxHeight,
    int? quality,
  }) async {
    try {
      debugPrint('Opening camera to take picture...');
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: quality,
      );

      if (pickedFile != null) {
        debugPrint('Image captured from camera: ${pickedFile.path}');
        final File imageFile = File(pickedFile.path);
        debugPrint('File exists: ${await imageFile.exists()}, Size: ${await imageFile.length()} bytes');
        return imageFile;
      } else {
        debugPrint('No image captured from camera');
      }
      return null;
    } catch (e) {
      debugPrint('Error picking image from camera: $e');
      debugPrint('Error stack trace: ${StackTrace.current}');
      return null;
    }
  }

  // Show image picker dialog with camera and gallery options
  static Future<File?> showImagePickerDialog(BuildContext context) async {
    try {
      debugPrint('Showing image picker dialog...');
      
      // Use a completer pattern to wait for the result
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(
              'Select Image Source',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Gallery option
                InkWell(
                  onTap: () {
                    Navigator.of(context).pop(ImageSource.gallery);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.blue.withOpacity(0.1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue.withOpacity(0.2),
                          ),
                          child: const Icon(Icons.photo_library, color: Colors.blue, size: 28),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Gallery',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Select from photo library',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Camera option
                InkWell(
                  onTap: () {
                    Navigator.of(context).pop(ImageSource.camera);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.green.withOpacity(0.1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green.withOpacity(0.2),
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.green, size: 28),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Camera',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Take a new photo',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: const Text('CANCEL'),
              ),
            ],
          );
        },
      );
      
      // User dismissed the dialog without selecting
      if (source == null) {
        debugPrint('Dialog dismissed without selecting a source');
        return null;
      }
      
      // Based on the selected source, pick the image
      File? pickedImage;
      if (source == ImageSource.gallery) {
        pickedImage = await pickImageFromGallery(
          maxWidth: 800,
          quality: 80,
        );
      } else {
        pickedImage = await pickImageFromCamera(
          maxWidth: 800,
          quality: 80,
        );
      }
      
      if (pickedImage != null) {
        debugPrint('Successfully got image from ${source == ImageSource.gallery ? "gallery" : "camera"}: ${pickedImage.path}');
        debugPrint('File exists: ${await pickedImage.exists()}, Size: ${await pickedImage.length()} bytes');
      } else {
        debugPrint('No image was picked');
      }
      
      return pickedImage;
    } catch (e) {
      debugPrint('Error in image picker dialog: $e');
      debugPrint('Error stack trace: ${StackTrace.current}');
      return null;
    }
  }
} 