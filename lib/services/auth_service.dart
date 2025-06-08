import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../models/tenant_model.dart';
import '../providers/menu_provider.dart';
import '../providers/order_provider.dart';
import '../providers/tenant_provider.dart';
import '../utils/constants.dart';
import 'package:bcrypt/bcrypt.dart';

class AuthService with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  bool get isBuyer => _currentUser?.role == UserRoles.buyer;
  bool get isSeller => _currentUser?.role == UserRoles.seller;

  // Helper method to load all required data
  Future<void> _loadUserData(BuildContext context) async {
    debugPrint('AuthService: Loading user data after login...');
    
    final menuProvider = Provider.of<MenuProvider>(context, listen: false);
    final tenantProvider = Provider.of<TenantProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    // Load data for the authenticated user
    await Future.wait([
      menuProvider.loadMenus(),
      tenantProvider.loadTenants(),
      orderProvider.loadOrders(),
    ]);
    
    debugPrint('AuthService: User data loaded successfully');
  }

  // Hash password with bcrypt
  String _hashPassword(String password) {
    // Generate a salt with default rounds (10)
    return BCrypt.hashpw(password, BCrypt.gensalt());
  }
  
  // Verify password with bcrypt
  bool _verifyPassword(String password, String hashedPassword) {
    return BCrypt.checkpw(password, hashedPassword);
  }

  // Login with email and password
  Future<bool> login(String email, String password, [BuildContext? context]) async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('AuthService: Attempting login for $email');
      // Query Firestore for user with matching email
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        debugPrint('AuthService: User not found with email $email');
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      final userDoc = querySnapshot.docs.first;
      final userData = userDoc.data();
      
      // Check if password matches using bcrypt
      if (!_verifyPassword(password, userData['passwordHash'])) {
        debugPrint('AuthService: Password verification failed for $email');
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      debugPrint('AuthService: Login successful for $email');
      // Set current user
      _currentUser = UserModel.fromMap({
        'id': userDoc.id,
        ...userData,
      });
      
      // Load user data if context is provided
      if (context != null) {
        await _loadUserData(context);
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('AuthService: Login error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Register new user
  Future<Map<String, dynamic>> register(String name, String email, String password, String role, {String? storeName, BuildContext? context}) async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('AuthService: Attempting registration for $email as $role');
      // Check if email already exists
      final existingUsers = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();
      
      if (existingUsers.docs.isNotEmpty) {
        debugPrint('AuthService: Registration failed - email already exists: $email');
        _isLoading = false;
        notifyListeners();
        return {'success': false, 'message': 'Email sudah digunakan.'};
      }
      
      // Create new user document with bcrypt hashed password
      final userData = {
        'name': name,
        'email': email,
        'passwordHash': _hashPassword(password),
        'role': role,
        'storeName': role == UserRoles.seller ? (storeName ?? name) : null,
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      final docRef = await _firestore.collection('users').add(userData);
      final userId = docRef.id;
      
      // Set current user
      _currentUser = UserModel(
        id: userId,
        name: name,
        email: email,
        role: role,
        storeName: role == UserRoles.seller ? (storeName ?? name) : null,
      );

      // If registering as a seller, create a tenant automatically
      if (role == UserRoles.seller) {
        debugPrint('AuthService: Creating tenant for seller: $name');
        final tenantName = storeName ?? name;
        
        final tenantData = {
          'name': tenantName,
          'sellerId': userId,
          'description': 'Tenant for $tenantName',
          'createdAt': FieldValue.serverTimestamp(),
        };
        
        await _firestore.collection('tenants').add(tenantData);
      }
      
      // Load user data if context is provided
      if (context != null) {
        await _loadUserData(context);
      }
      
      debugPrint('AuthService: Registration successful for $email');
      _isLoading = false;
      notifyListeners();
      return {'success': true};
    } catch (e) {
      debugPrint('AuthService: Registration error: $e');
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Registrasi gagal: $e'};
    }
  }

  // Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    debugPrint('AuthService: Logging out user: ${_currentUser?.email}');
    _currentUser = null;
    
    _isLoading = false;
    notifyListeners();
    debugPrint('AuthService: Logout complete');
  }
} 