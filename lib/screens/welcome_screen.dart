import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../widgets/app_button.dart';
import 'auth/login_screen.dart';
import 'auth/register_screen.dart';
import 'auth/seller_register_screen.dart';

// Get ButtonType enum
import '../widgets/app_button.dart' show ButtonType;

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.fastfood,
                    size: 70,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                
                // App Name
                const Text(
                  'quickbites ',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Tagline
                const Text(
                  'Pemesanan Makanan Kampus',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 60),
                
                // Login Button
                AppButton(
                  text: 'Login',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  },
                ),
                const SizedBox(height: 16),
                
                // Register Button
                AppButton(
                  text: 'Register',
                  onPressed: () {
                    _showRegisterOptions(context);
                  },
                  type: ButtonType.secondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _showRegisterOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Register sebagai'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person, color: AppColors.primaryAccent),
                title: const Text('Buyer'),
                subtitle: const Text('Pesan makanan dari berbagai tenant'),
                onTap: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegisterScreen()),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.store, color: AppColors.primaryAccent),
                title: const Text('Seller'),
                subtitle: const Text('Jual makanan di quickbites '),
                onTap: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SellerRegisterScreen()),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
} 