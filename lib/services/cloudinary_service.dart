import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CloudinaryService {
  late final CloudinaryPublic _cloudinary;
  bool _isInitialized = false;
  
  CloudinaryService() {
    _initCloudinary();
  }
  
  void _initCloudinary() {
    try {
      // Use the values from .env or fallback to the hardcoded values
      // These should match the values in your .env file
      final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? 'YOUR_CLOUD_NAME';
      final uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? 'YOUR_UPLOAD_PRESET';
      
      _cloudinary = CloudinaryPublic(cloudName, uploadPreset);
      _isInitialized = true;
      debugPrint('CloudinaryService initialized with cloud name: $cloudName');
    } catch (e) {
      debugPrint('Error initializing CloudinaryService: $e');
      _isInitialized = false;
    }
  }
  
  /// Upload an image to Cloudinary
  /// 
  /// Returns the URL of the uploaded image or null if upload fails
  Future<String?> uploadImage(File imageFile) async {
    if (!_isInitialized) {
      debugPrint('CloudinaryService not initialized. Trying to initialize...');
      _initCloudinary();
      if (!_isInitialized) {
        debugPrint('Failed to initialize CloudinaryService. Cannot upload image.');
        return null;
      }
    }
    
    try {
      // Create a CloudinaryResponse by uploading the file
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          folder: 'menu_images',
        ),
      );
      
      // Return the secure URL of the uploaded image
      return response.secureUrl;
    } catch (e) {
      debugPrint('Error uploading image to Cloudinary: $e');
      return null;
    }
  }
  
  /// Upload an image from memory (web platform)
  /// 
  /// Returns the URL of the uploaded image or null if upload fails
  Future<String?> uploadImageWeb(Uint8List imageBytes, String fileName) async {
    if (!_isInitialized) {
      debugPrint('CloudinaryService not initialized. Trying to initialize...');
      _initCloudinary();
      if (!_isInitialized) {
        debugPrint('Failed to initialize CloudinaryService. Cannot upload image.');
        return null;
      }
    }
    
    try {
      // Create a CloudinaryResponse by uploading the bytes
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromBytesData(
          imageBytes,
          identifier: fileName,
          folder: 'menu_images',
        ),
      );
      
      // Return the secure URL of the uploaded image
      return response.secureUrl;
    } catch (e) {
      debugPrint('Error uploading image to Cloudinary: $e');
      return null;
    }
  }
} 