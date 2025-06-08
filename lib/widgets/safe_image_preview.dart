import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/constants.dart';

// Simple image preview widget to avoid layout issues
class SafeImagePreview extends StatelessWidget {
  final File? imageFile;
  final String? networkImageUrl;
  final double height;
  final double width;
  final VoidCallback? onTap;
  final bool isEnabled;
  
  const SafeImagePreview({
    super.key,
    this.imageFile,
    this.networkImageUrl,
    this.height = 120,
    this.width = double.infinity,
    this.onTap,
    this.isEnabled = true,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: AppColors.primaryAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withOpacity(0.5)),
        ),
        child: _buildContent(),
      ),
    );
  }
  
  Widget _buildContent() {
    // Priority: Local file > Network image > Placeholder
    if (imageFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          imageFile!,
          height: height,
          width: width,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Error loading image: $error');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.error, color: Colors.red, size: 32),
                  SizedBox(height: 4),
                  Text('Error loading image', style: TextStyle(color: Colors.red)),
                ],
              ),
            );
          },
        ),
      );
    } else if (networkImageUrl != null && networkImageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: networkImageUrl!,
          height: height,
          width: width,
          fit: BoxFit.cover,
          placeholder: (context, url) => const Center(
            child: CircularProgressIndicator(),
          ),
          errorWidget: (context, url, error) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.error, color: Colors.red, size: 32),
                SizedBox(height: 4),
                Text('Error loading image', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ),
      );
    } else {
      // Empty placeholder
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.add_photo_alternate,
            size: 40,
            color: AppColors.primaryAccent,
          ),
          SizedBox(height: 8),
          Text(
            'Add Image',
            style: TextStyle(
              color: AppColors.primaryAccent,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }
  }
} 