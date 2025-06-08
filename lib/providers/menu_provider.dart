import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/menu_model.dart';

class MenuProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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
      final querySnapshot = await _firestore.collection('menus').get();
      
      _menus = querySnapshot.docs.map((doc) {
        return MenuModel(
          id: doc.id,
          name: doc['name'],
          price: doc['price'],
          stock: doc['stock'],
          tenantId: doc['tenantId'],
          category: doc['category'],
          imageUrl: doc['imageUrl'],
        );
      }).toList();
    } catch (e) {
      print('Error loading menus: $e');
      // If there's an error, use an empty list
      _menus = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  // Add a new menu
  Future<void> addMenu(MenuModel menu) async {
    _isLoading = true;
    notifyListeners();

    try {
      final menuData = {
        'name': menu.name,
        'price': menu.price,
        'stock': menu.stock,
        'tenantId': menu.tenantId,
        'category': menu.category,
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      // Add imageUrl if it exists
      if (menu.imageUrl != null) {
        menuData['imageUrl'] = menu.imageUrl as Object;
      }
      
      final docRef = await _firestore.collection('menus').add(menuData);
      
      // Add to local list with the generated ID
      final newMenu = MenuModel(
        id: docRef.id,
        name: menu.name,
        price: menu.price,
        stock: menu.stock,
        tenantId: menu.tenantId,
        category: menu.category,
        imageUrl: menu.imageUrl,
      );
      
      _menus.add(newMenu);
    } catch (e) {
      print('Error adding menu: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Update a menu
  Future<void> updateMenu(MenuModel updatedMenu) async {
    _isLoading = true;
    notifyListeners();

    try {
      final updateData = {
        'name': updatedMenu.name,
        'price': updatedMenu.price,
        'stock': updatedMenu.stock,
        'category': updatedMenu.category,
      };
      
      // Add imageUrl if it exists
      if (updatedMenu.imageUrl != null) {
        updateData['imageUrl'] = updatedMenu.imageUrl as Object;
      }
      
      await _firestore.collection('menus').doc(updatedMenu.id).update(updateData);
      
      // Update in local list
      final index = _menus.indexWhere((menu) => menu.id == updatedMenu.id);
      if (index != -1) {
        _menus[index] = updatedMenu;
      }
    } catch (e) {
      print('Error updating menu: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Delete a menu
  Future<void> deleteMenu(String menuId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firestore.collection('menus').doc(menuId).delete();
      
      // Remove from local list
      _menus.removeWhere((menu) => menu.id == menuId);
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