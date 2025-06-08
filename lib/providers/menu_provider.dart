import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/menu_model.dart';
import '../services/cloudinary_service.dart';

class MenuProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CloudinaryService _cloudinaryService = CloudinaryService();
  List<MenuModel> _menus = [];
  bool _isLoading = false;

  List<MenuModel> get menus => _menus;
  bool get isLoading => _isLoading;

  // Get menus by category
  List<MenuModel> getMenusByCategory(String category) {
    return _menus.where((menu) => menu.category == category).toList();
  }

  // Get menus by tenant
  List<MenuModel> getMenusByTenant(String tenantId) {
    return _menus.where((menu) => menu.tenantId == tenantId).toList();
  }

  // Get a single menu by ID
  MenuModel? getMenuById(String menuId) {
    try {
      return _menus.firstWhere((menu) => menu.id == menuId);
    } catch (e) {
      return null;
    }
  }

  // Load menus from Firestore
  Future<void> loadMenus() async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('MenuProvider: Loading menus from Firestore...');
      final querySnapshot = await _firestore.collection('menus').get();
      debugPrint('MenuProvider: Retrieved ${querySnapshot.docs.length} menus from Firestore');
      
      _menus = querySnapshot.docs.map((doc) {
        final data = doc.data();
        debugPrint('MenuProvider: Menu data for ${doc.id}: $data');
        
        return MenuModel(
          id: doc.id,
          name: data['name'] ?? '',
          price: data['price'] ?? 0,
          stock: data['stock'] ?? 0,
          tenantId: data['tenantId'] ?? '',
          category: data['category'] ?? 'Makanan',
          imageUrl: data['imageUrl'],
        );
      }).toList();
      
      debugPrint('MenuProvider: Loaded ${_menus.length} menus into local state');
      for (var menu in _menus) {
        debugPrint('MenuProvider: Menu: ${menu.name}, ImageUrl: ${menu.imageUrl ?? 'null'}');
      }
    } catch (e) {
      debugPrint('MenuProvider: Error loading menus: $e');
      debugPrint('MenuProvider: Error stack trace: ${StackTrace.current}');
      // If there's an error, use an empty list
      _menus = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  // Upload image to Cloudinary and return URL
  Future<String?> uploadMenuImage(File imageFile, String menuId) async {
    try {
      // Upload to Cloudinary with a folder named after the menuId
      debugPrint('MenuProvider: Starting menu image upload for menuId: $menuId');
      debugPrint('MenuProvider: Image file path: ${imageFile.path}');
      
      if (!(await imageFile.exists())) {
        debugPrint('MenuProvider: ERROR - Image file does not exist!');
        return null;
      }
      
      final imageUrl = await _cloudinaryService.uploadImage(
        imageFile,
        folder: 'menu_images/$menuId',
      );
      
      if (imageUrl == null) {
        debugPrint('MenuProvider: Cloudinary upload returned null URL');
      } else {
        debugPrint('MenuProvider: Cloudinary upload successful: $imageUrl');
      }
      
      return imageUrl;
    } catch (e) {
      debugPrint('MenuProvider: Error uploading image: $e');
      return null;
    }
  }

  // Add a new menu with image
  Future<void> addMenu(MenuModel menu, {File? imageFile}) async {
    _isLoading = true;
    notifyListeners();

    try {
      // First create the Firestore document to get a real ID
      debugPrint('MenuProvider: Adding menu to Firestore (without image first)');
      final menuData = {
        'name': menu.name,
        'price': menu.price,
        'stock': menu.stock,
        'tenantId': menu.tenantId,
        'category': menu.category,
        'imageUrl': null, // Will update this after upload
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      // Create document first to get real ID
      final docRef = await _firestore.collection('menus').add(menuData);
      final realMenuId = docRef.id;
      debugPrint('MenuProvider: Menu added with ID: $realMenuId');
      
      String? imageUrl;
      
      // Upload image if provided - NOW using the real document ID
      if (imageFile != null) {
        debugPrint('MenuProvider: Image file provided for upload. Path: ${imageFile.path}');
        debugPrint('MenuProvider: File exists: ${await imageFile.exists()}, Size: ${await imageFile.length()} bytes');
        
        // Use the REAL document ID for the upload
        imageUrl = await uploadMenuImage(imageFile, realMenuId);
        
        if (imageUrl != null) {
          debugPrint('MenuProvider: Image upload successful. URL: $imageUrl');
          
          // Update the document with the image URL
          await _firestore.collection('menus').doc(realMenuId).update({
            'imageUrl': imageUrl
          });
          debugPrint('MenuProvider: Updated Firestore document with imageUrl');
        } else {
          debugPrint('MenuProvider: Image upload FAILED!');
        }
      } else {
        debugPrint('MenuProvider: No image file provided for menu: ${menu.name}');
      }
      
      // Add to local list with the generated ID and image URL
      final newMenu = MenuModel(
        id: realMenuId,
        name: menu.name,
        price: menu.price,
        stock: menu.stock,
        tenantId: menu.tenantId,
        category: menu.category,
        imageUrl: imageUrl,
      );
      
      _menus.add(newMenu);
      debugPrint('MenuProvider: Added menu to local list with imageUrl: $imageUrl');
    } catch (e) {
      debugPrint('MenuProvider: Error adding menu: $e');
      debugPrint('MenuProvider: Error stack trace: ${StackTrace.current}');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Update a menu
  Future<void> updateMenu(MenuModel updatedMenu, {File? imageFile}) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Prepare the basic update data (without image)
      final updateData = {
        'name': updatedMenu.name,
        'price': updatedMenu.price,
        'stock': updatedMenu.stock,
        'category': updatedMenu.category,
      };
      
      // Start with existing image URL
      String? imageUrl = updatedMenu.imageUrl;
      
      // Upload new image if provided
      if (imageFile != null) {
        debugPrint('MenuProvider: New image file provided for update. Path: ${imageFile.path}');
        
        // Verify file exists
        if (!await imageFile.exists()) {
          debugPrint('MenuProvider: ERROR - Image file does not exist!');
          throw Exception('Image file does not exist');
        }
        
        debugPrint('MenuProvider: File exists: ${await imageFile.exists()}, Size: ${await imageFile.length()} bytes');
        
        // Use the menu's real ID for the upload
        imageUrl = await uploadMenuImage(imageFile, updatedMenu.id);
        
        if (imageUrl != null) {
          debugPrint('MenuProvider: Image upload successful for update. URL: $imageUrl');
          // Include the new image URL in the update data
          updateData['imageUrl'] = imageUrl;
        } else {
          debugPrint('MenuProvider: Image upload FAILED for update!');
          throw Exception('Failed to upload image');
        }
      } else {
        debugPrint('MenuProvider: No new image file provided for menu update: ${updatedMenu.name}');
        debugPrint('MenuProvider: Keeping existing imageUrl: ${updatedMenu.imageUrl ?? "null"}');
      }
      
      debugPrint('MenuProvider: Updating menu in Firestore with data: $updateData');
      await _firestore.collection('menus').doc(updatedMenu.id).update(updateData);
      debugPrint('MenuProvider: Menu updated with ID: ${updatedMenu.id}');
      
      // Update in local list
      final index = _menus.indexWhere((menu) => menu.id == updatedMenu.id);
      if (index != -1) {
        _menus[index] = updatedMenu.copyWith(imageUrl: imageUrl);
        debugPrint('MenuProvider: Updated local menu with imageUrl: $imageUrl');
      }
    } catch (e) {
      debugPrint('MenuProvider: Error updating menu: $e');
      debugPrint('MenuProvider: Error stack trace: ${StackTrace.current}');
      // Rethrow to allow UI to handle the error
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete a menu
  Future<void> deleteMenu(String menuId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firestore.collection('menus').doc(menuId).delete();
      
      // Remove from local list
      _menus.removeWhere((menu) => menu.id == menuId);
      
      // Note: Images on Cloudinary will remain as there's no direct way to delete them from client-side
      // For production, consider implementing server-side cleanup or using signed uploads with eager transformations
    } catch (e) {
      print('Error deleting menu: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Update stock for a menu
  Future<void> updateStock(String menuId, int newStock) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firestore.collection('menus').doc(menuId).update({
        'stock': newStock,
      });
      
      // Update in local list
      final index = _menus.indexWhere((menu) => menu.id == menuId);
      if (index != -1) {
        final updatedMenu = _menus[index].copyWith(stock: newStock);
        _menus[index] = updatedMenu;
      }
    } catch (e) {
      print('Error updating stock: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Decrease stock when order is placed
  Future<void> decreaseStock(String menuId, int quantity) async {
    final index = _menus.indexWhere((menu) => menu.id == menuId);
    if (index != -1) {
      final currentStock = _menus[index].stock;
      if (currentStock >= quantity) {
        try {
          await _firestore.collection('menus').doc(menuId).update({
            'stock': FieldValue.increment(-quantity),
          });
          
          final updatedMenu = _menus[index].copyWith(stock: currentStock - quantity);
          _menus[index] = updatedMenu;
          notifyListeners();
        } catch (e) {
          print('Error decreasing stock: $e');
        }
      }
    }
  }
} 