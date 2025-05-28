import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
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
  Future<Map<String, dynamic>> register(String name, String email, String password, String role) async {
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
        'storeName': role == UserRoles.seller ? name : null,
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      final docRef = await _firestore.collection('users').add(userData);
      
      // Set current user
      _currentUser = UserModel(
        id: docRef.id,
        name: name,
        email: email,
        role: role,
        storeName: role == UserRoles.seller ? name : null,
      );
      
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

    _currentUser = null;
    
    _isLoading = false;
    notifyListeners();
  }
} 