import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/tenant_model.dart';
import '../../providers/tenant_provider.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../welcome_screen.dart';

class SellerProfileScreen extends StatelessWidget {
  const SellerProfileScreen({Key? key}) : super(key: key);

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
                CircleAvatar(
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Informasi Toko'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                label: 'Nama Toko',
                hintText: 'Masukkan nama toko',
                controller: nameController,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Deskripsi',
                hintText: 'Masukkan deskripsi toko',
                controller: descriptionController,
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
            onPressed: () {
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
              
              if (tenant == null) {
                // Create new tenant
                final newTenant = TenantModel(
                  id: 'tenant_${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  sellerId: authService.currentUser!.id,
                  description: description,
                );
                
                tenantProvider.addTenant(newTenant);
              } else {
                // Update existing tenant
                final updatedTenant = TenantModel(
                  id: tenant.id,
                  name: name,
                  sellerId: tenant.sellerId,
                  description: description,
                  imageUrl: tenant.imageUrl,
                );
                
                tenantProvider.updateTenant(updatedTenant);
              }
              
              Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
} 