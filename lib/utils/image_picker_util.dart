import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerUtil {
  static final ImagePicker _picker = ImagePicker();

  /// Show a dialog to choose between camera and gallery
  static Future<File?> pickImage(BuildContext context) async {
    return await showDialog<File?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pilih Sumber Gambar'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                GestureDetector(
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Icon(Icons.photo_library),
                        SizedBox(width: 10),
                        Text('Galeri'),
                      ],
                    ),
                  ),
                  onTap: () async {
                    File? file = await _getFromGallery();
                    if (context.mounted) {
                      Navigator.of(context).pop(file);
                    }
                  },
                ),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Divider(),
                ),
                GestureDetector(
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Icon(Icons.photo_camera),
                        SizedBox(width: 10),
                        Text('Kamera'),
                      ],
                    ),
                  ),
                  onTap: () async {
                    File? file = await _getFromCamera();
                    if (context.mounted) {
                      Navigator.of(context).pop(file);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Get image from gallery
  static Future<File?> _getFromGallery() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  /// Get image from camera
  static Future<File?> _getFromCamera() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }
} 