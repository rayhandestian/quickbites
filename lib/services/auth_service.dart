import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/user_model.dart';
import '../models/tenant_model.dart';
import '../utils/constants.dart';
import 'package:bcrypt/bcrypt.dart';

class AuthService with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  
  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  bool get isBuyer => _currentUser?.role == UserRoles.buyer;
  bool get isSeller => _currentUser?.role == UserRoles.seller;

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
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Query Firestore for user with matching email
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      final userDoc = querySnapshot.docs.first;
      final userData = userDoc.data();
      
      // Check if password matches using bcrypt
      if (!_verifyPassword(password, userData['passwordHash'])) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      // Set current user
      _currentUser = UserModel.fromMap({
        'id': userDoc.id,
        ...userData,
      });

      // Get and update FCM token
      try {
        final fcmToken = await _firebaseMessaging.getToken();
        if (fcmToken != null) {
          await _firestore.collection('users').doc(userDoc.id).update({
            'fcmToken': fcmToken,
          });
          _currentUser = UserModel(
            id: _currentUser!.id,
            name: _currentUser!.name,
            email: _currentUser!.email,
            role: _currentUser!.role,
            storeName: _currentUser!.storeName,
            fcmToken: fcmToken,
          );
        }
      } catch (e) {
        print('Failed to get or update FCM token: $e');
        // Continue without FCM token if it fails
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Login error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Register new user
  Future<Map<String, dynamic>> register(String name, String email, String password, String role, {String? storeName}) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Check if email already exists
      final existingUsers = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();
      
      if (existingUsers.docs.isNotEmpty) {
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
        final tenantName = storeName ?? name;
        
        final tenantData = {
          'name': tenantName,
          'sellerId': userId,
          'description': 'Tenant for $tenantName',
          'createdAt': FieldValue.serverTimestamp(),
        };
        
        await _firestore.collection('tenants').add(tenantData);
      }
      
      _isLoading = false;
      notifyListeners();
      return {'success': true};
    } catch (e) {
      print('Registration error: $e');
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Registrasi gagal: $e'};
    }
  }

  // Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    // Clear FCM token on logout
    if (_currentUser != null) {
      try {
        await _firestore.collection('users').doc(_currentUser!.id).update({
          'fcmToken': FieldValue.delete(),
        });
      } catch (e) {
        print('Failed to clear FCM token: $e');
      }
    }

    _currentUser = null;
    
    _isLoading = false;
    notifyListeners();
  }
} 