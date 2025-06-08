import 'dart:io';
import 'dart:convert';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CloudinaryService {
  // Get Cloudinary credentials from .env file
  final String _cloudName = dotenv.get('CLOUDINARY_CLOUD_NAME', fallback: '');
  final String _uploadPreset = dotenv.get('CLOUDINARY_UPLOAD_PRESET', fallback: '');
  late final CloudinaryPublic cloudinary;

  CloudinaryService() {
    // Initialize the Cloudinary instance
    cloudinary = CloudinaryPublic(_cloudName, _uploadPreset, cache: false);
  }

  // Test Cloudinary connectivity
  Future<bool> testCloudinaryConnection() async {
    try {
      debugPrint('Testing Cloudinary connection to cloud: $_cloudName');
      final response = await http.get(
        Uri.parse('https://res.cloudinary.com/$_cloudName/image/upload/v1/samples/cloudinary-icon.png')
      );
      
      final success = response.statusCode == 200;
      debugPrint('Cloudinary connection test result: ${success ? 'SUCCESS' : 'FAILED'} (Status: ${response.statusCode})');
      
      return success;
    } catch (e) {
      debugPrint('Cloudinary connection test error: $e');
      return false;
    }
  }

  // Upload directly using HttpClient (fallback method)
  Future<String?> uploadDirect(File imageFile, {String? folder}) async {
    try {
      debugPrint('Attempting direct HTTP upload to Cloudinary...');
      
      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload')
      );
      
      // Add fields
      request.fields['upload_preset'] = _uploadPreset;
      if (folder != null) {
        request.fields['folder'] = folder;
      }
      
      // Add file
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
        )
      );
      
      // Send request
      debugPrint('Sending direct upload request...');
      var response = await request.send();
      var responseData = await response.stream.toBytes();
      var responseString = String.fromCharCodes(responseData);
      
      // Parse response
      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(responseString);
        String secureUrl = jsonResponse['secure_url'];
        debugPrint('Direct upload successful! URL: $secureUrl');
        return secureUrl;
      } else {
        debugPrint('Direct upload failed with status: ${response.statusCode}');
        debugPrint('Response: $responseString');
        return null;
      }
    } catch (e) {
      debugPrint('Error in direct upload: $e');
      return null;
    }
  }

  // Upload an image to Cloudinary and return the URL
  Future<String?> uploadImage(File imageFile, {String? folder}) async {
    try {
      debugPrint('====== CLOUDINARY UPLOAD ======');
      debugPrint('Starting upload process for file: ${imageFile.path}');
      
      // Verify file exists and can be read
      if (!await imageFile.exists()) {
        debugPrint('❌ ERROR: Image file does not exist!');
        return null;
      }
      
      final fileSize = await imageFile.length();
      debugPrint('File exists: true, Size: $fileSize bytes');
      
      if (fileSize <= 0) {
        debugPrint('❌ ERROR: Image file is empty!');
        return null;
      }
      
      // Verify Cloudinary connection
      final connectionTest = await testCloudinaryConnection();
      if (!connectionTest) {
        debugPrint('❌ ERROR: Cannot connect to Cloudinary service');
        return null;
      }
      
      // Use folder or default
      final folderPath = folder ?? 'quickbites ';
      debugPrint('Using folder: $folderPath');
      
      // For better reliability, use direct upload first (more control over the process)
      debugPrint('Attempting direct HTTP upload...');
      final directResult = await uploadDirect(imageFile, folder: folderPath);
      
      if (directResult != null) {
        debugPrint('✅ Direct upload successful! URL: $directResult');
        return directResult;
      }
      
      debugPrint('⚠️ Direct upload failed, trying CloudinaryPublic package method...');
      
      // Fall back to the package method if direct fails
      try {
        CloudinaryResponse response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            imageFile.path,
            folder: folderPath,
            resourceType: CloudinaryResourceType.Image,
          ),
        );

        // Return the secure URL of the uploaded image
        debugPrint('✅ CloudinaryPublic upload successful! URL: ${response.secureUrl}');
        return response.secureUrl;
      } catch (packageError) {
        debugPrint('❌ CloudinaryPublic package upload failed: $packageError');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error uploading image to Cloudinary: $e');
      debugPrint('Error details: ${e.toString()}');
      
      // Provide more specific error information
      if (e is CloudinaryException) {
        debugPrint('Cloudinary specific error: ${e.message}');
      }
      
      return null;
    }
  }

  // Direct test method to upload a test image - call this to test Cloudinary setup
  Future<String?> uploadTestImage(File imageFile) async {
    debugPrint('==== CLOUDINARY TEST UPLOAD ====');
    debugPrint('Testing image upload with file: ${imageFile.path}');
    debugPrint('File exists: ${await imageFile.exists()}, Size: ${await imageFile.length()} bytes');
    
    try {
      // First verify Cloudinary connection
      final connectionTest = await testCloudinaryConnection();
      if (!connectionTest) {
        debugPrint('TEST UPLOAD FAILED: Cannot connect to Cloudinary service');
        return null;
      }
      
      debugPrint('Connection test passed - proceeding with test upload');
      
      // Use direct upload method for simplicity in testing
      final uploadResult = await uploadDirect(imageFile, folder: 'test_uploads');
      
      if (uploadResult != null) {
        debugPrint('✅ TEST UPLOAD SUCCESSFUL: $uploadResult');
      } else {
        debugPrint('❌ TEST UPLOAD FAILED!');
      }
      return uploadResult;
    } catch (e) {
      debugPrint('❌ TEST UPLOAD ERROR: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      return null;
    }
  }
} 