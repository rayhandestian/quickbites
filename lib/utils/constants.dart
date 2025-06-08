import 'package:flutter/material.dart';

// Colors from the requirements
class AppColors {
  static const Color background = Color(0xFFFFFFFF);
  static const Color primaryAccent = Color(0xFF389C9A);
  static const Color secondaryAccent = Color(0xFFFEDB71);
  static const Color textPrimary = Color(0xFF1D1D1D);
  static const Color secondarySurface = Color(0xFFF8F8F8);
  
  // Additional utility colors
  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFFFA000);
  static const Color divider = Color(0xFFE0E0E0);
}

// Order status constants
class OrderStatus {
  static const String sent = 'dikirim';    // Initial status when order is sent by buyer
  static const String created = 'dibuat';  // When seller accepts the order
  static const String ready = 'siap';      // When order is ready for pickup
  static const String completed = 'selesai'; // When order is completed
}

// User roles
class UserRoles {
  static const String buyer = 'buyer';
  static const String seller = 'seller';
}

// Food categories
class FoodCategories {
  static const String food = 'Makanan';
  static const String beverage = 'Minuman';
}

// Routes for navigation
class AppRoutes {
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String buyerHome = '/buyer/home';
  static const String sellerHome = '/seller/home';
  static const String menu = '/menu';
  static const String checkout = '/checkout';
  static const String orderTracker = '/order-tracker';
  static const String profile = '/profile';
  static const String inventory = '/inventory';
}

// Format currency in IDR
String formatCurrency(int amount) {
  return 'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
} 