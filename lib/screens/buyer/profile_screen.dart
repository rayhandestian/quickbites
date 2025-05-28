import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../widgets/app_button.dart';
import '../welcome_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    if (user == null) {
      return const Center(
        child: Text('Silakan login untuk melihat profil Anda'),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 24),

            // Profile Avatar
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primaryAccent,
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // User Name
            Text(
              user.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),

            // User Email
            Text(
              user.email,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32),

            // Profile Sections
            _buildProfileSection(
              context,
              'Informasi Akun',
              [
                _buildProfileItem(
                  Icons.person_outline,
                  'Edit Profil',
                  () {},
                ),
                _buildProfileItem(
                  Icons.lock_outline,
                  'Ubah Password',
                  () {},
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildProfileSection(
              context,
              'Preferensi',
              [
                _buildProfileItem(
                  Icons.notifications_outlined,
                  'Notifikasi',
                  () {},
                ),
                _buildProfileItem(
                  Icons.language,
                  'Bahasa',
                  () {},
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildProfileSection(
              context,
              'Lainnya',
              [
                _buildProfileItem(
                  Icons.info_outline,
                  'Tentang Aplikasi',
                  () {},
                ),
                _buildProfileItem(
                  Icons.help_outline,
                  'Bantuan',
                  () {},
                ),
              ],
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

  Widget _buildProfileSection(
    BuildContext context,
    String title,
    List<Widget> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileItem(
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: AppColors.primaryAccent,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textPrimary.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
} 