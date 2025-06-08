import 'package:flutter/material.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../../models/tenant_model.dart';
import '../../providers/tenant_provider.dart';
import '../../services/auth_service.dart';
import '../../services/cloudinary_service.dart';
import '../../utils/constants.dart';
import '../../utils/image_picker_util.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../welcome_screen.dart';

class SellerProfileScreen extends StatelessWidget {
  const SellerProfileScreen({Key? key}) : super(key: key);

  // Helper method to check if an image URL exists and is valid
  bool _isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) {
      return false;
    }
    
    // Basic URL validation
    final validUrl = Uri.tryParse(url);
    if (validUrl == null || !validUrl.isAbsolute) {
      return false;
    }
    
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final tenantProvider = Provider.of<TenantProvider>(context);
    final user = authService.currentUser;

    if (user == null) {
      return const Center(
        child: Text('Silakan login untuk melihat profil Anda'),
      );
    }

    final tenant = tenantProvider.getTenantBySellerId(user.id);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),

            // Profile Avatar and Info
            Row(
              children: [
                // Display tenant image if available, otherwise show avatar with initial
                _isValidImageUrl(tenant?.imageUrl)
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: Image.network(
                      tenant!.imageUrl!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.primaryAccent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: const Center(child: CircularProgressIndicator()),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.primaryAccent,
                          child: Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : '',
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
                  )
                : CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primaryAccent,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tenant?.name ?? 'Toko Anda',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primaryAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),

            // Store Information
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informasi Toko',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(
                          Icons.store,
                          color: AppColors.primaryAccent,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          tenant?.name ?? 'Toko Anda',
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.description,
                          color: AppColors.primaryAccent,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            tenant?.description ?? 'Deskripsi toko Anda',
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      text: 'Edit Informasi Toko',
                      onPressed: () {
                        _showEditStoreDialog(context, tenant);
                      },
                      type: ButtonType.secondary,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),

            // Account Settings
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pengaturan Akun',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(
                        Icons.person_outline,
                        color: AppColors.primaryAccent,
                      ),
                      title: const Text('Edit Profil'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      contentPadding: EdgeInsets.zero,
                      onTap: () {
                        // Navigate to edit profile
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.lock_outline,
                        color: AppColors.primaryAccent,
                      ),
                      title: const Text('Ubah Password'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      contentPadding: EdgeInsets.zero,
                      onTap: () {
                        // Navigate to change password
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.notifications_outlined,
                        color: AppColors.primaryAccent,
                      ),
                      title: const Text('Notifikasi'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      contentPadding: EdgeInsets.zero,
                      onTap: () {
                        // Navigate to notifications settings
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),

            // Logout Button
            AppButton(
              text: 'Logout',
              onPressed: () async {
                await authService.logout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                    (route) => false,
                  );
                }
              },
              type: ButtonType.secondary,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showEditStoreDialog(BuildContext context, TenantModel? tenant) {
    final nameController = TextEditingController(text: tenant?.name ?? '');
    final descriptionController = TextEditingController(text: tenant?.description ?? '');
    
    File? selectedImage;
    bool imageChanged = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(tenant == null ? 'Buat Toko' : 'Edit Informasi Toko'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image Picker
                InkWell(
                  onTap: () async {
                    final image = await ImagePickerUtil.pickImage(context);
                    if (image != null) {
                      setState(() {
                        selectedImage = image;
                        imageChanged = true;
                      });
                    }
                  },
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.secondarySurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: imageChanged && selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              selectedImage!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : _isValidImageUrl(tenant?.imageUrl)
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  tenant!.imageUrl!,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                            : null,
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Icon(
                                        Icons.store,
                                        size: 40,
                                        color: AppColors.primaryAccent,
                                      ),
                                    );
                                  },
                                ),
                              )
                            : const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate,
                                      size: 40,
                                      color: AppColors.primaryAccent,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Tambahkan Foto Toko',
                                      style: TextStyle(
                                        color: AppColors.primaryAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                  ),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: nameController,
                  label: 'Nama Toko',
                  hintText: 'Masukkan nama toko Anda',
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: descriptionController,
                  label: 'Deskripsi',
                  hintText: 'Deskripsi singkat tentang toko Anda',
                  maxLength: 200,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final tenantProvider = Provider.of<TenantProvider>(context, listen: false);
                final authService = Provider.of<AuthService>(context, listen: false);
                
                final name = nameController.text.trim();
                final description = descriptionController.text.trim();
                
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nama toko tidak boleh kosong')),
                  );
                  return;
                }
                
                // Show loading dialog
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const AlertDialog(
                    content: Row(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 16),
                        Text('Menyimpan data...'),
                      ],
                    ),
                  ),
                );
                
                // Upload image if selected
                String? imageUrl = tenant?.imageUrl;
                if (imageChanged && selectedImage != null) {
                  final cloudinaryService = CloudinaryService();
                  imageUrl = await cloudinaryService.uploadImage(selectedImage!);
                  
                  if (imageUrl == null) {
                    // Close loading dialog
                    if (context.mounted) {
                      Navigator.pop(context); // Close loading dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Gagal mengunggah gambar. Coba lagi nanti.')),
                      );
                    }
                    return;
                  }
                }
                
                if (tenant == null) {
                  // Create new tenant
                  final newTenant = TenantModel(
                    id: 'tenant_${DateTime.now().millisecondsSinceEpoch}',
                    name: name,
                    sellerId: authService.currentUser!.id,
                    description: description,
                    imageUrl: imageUrl,
                  );
                  
                  await tenantProvider.addTenant(newTenant);
                } else {
                  // Update existing tenant
                  final updatedTenant = TenantModel(
                    id: tenant.id,
                    name: name,
                    sellerId: tenant.sellerId,
                    description: description,
                    imageUrl: imageUrl,
                  );
                  
                  await tenantProvider.updateTenant(updatedTenant);
                }
                
                // Close loading dialog and tenant dialog
                if (context.mounted) {
                  Navigator.pop(context); // Close loading dialog
                  Navigator.pop(context); // Close tenant dialog
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
} 