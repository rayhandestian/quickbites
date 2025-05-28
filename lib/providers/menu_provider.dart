import 'package:flutter/material.dart';
import '../models/menu_model.dart';
import '../services/mock_data_service.dart';

class MenuProvider with ChangeNotifier {
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

  // Load menus from mock data
  Future<void> loadMenus() async {
    _isLoading = true;
    notifyListeners();

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Load mock data
    _menus = MockDataService.getMockMenus();

    _isLoading = false;
    notifyListeners();
  }

  // Add a new menu
  Future<void> addMenu(MenuModel menu) async {
    _isLoading = true;
    notifyListeners();

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Add to list
    _menus.add(menu);

    _isLoading = false;
    notifyListeners();
  }

  // Update a menu
  Future<void> updateMenu(MenuModel updatedMenu) async {
    _isLoading = true;
    notifyListeners();

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Find and update menu
    final index = _menus.indexWhere((menu) => menu.id == updatedMenu.id);
    if (index != -1) {
      _menus[index] = updatedMenu;
    }

    _isLoading = false;
    notifyListeners();
  }

  // Delete a menu
  Future<void> deleteMenu(String menuId) async {
    _isLoading = true;
    notifyListeners();

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Remove from list
    _menus.removeWhere((menu) => menu.id == menuId);

    _isLoading = false;
    notifyListeners();
  }

  // Update stock for a menu
  Future<void> updateStock(String menuId, int newStock) async {
    _isLoading = true;
    notifyListeners();

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    // Find and update menu stock
    final index = _menus.indexWhere((menu) => menu.id == menuId);
    if (index != -1) {
      final updatedMenu = _menus[index].copyWith(stock: newStock);
      _menus[index] = updatedMenu;
    }

    _isLoading = false;
    notifyListeners();
  }

  // Decrease stock when order is placed
  void decreaseStock(String menuId, int quantity) {
    final index = _menus.indexWhere((menu) => menu.id == menuId);
    if (index != -1) {
      final currentStock = _menus[index].stock;
      if (currentStock >= quantity) {
        final updatedMenu = _menus[index].copyWith(stock: currentStock - quantity);
        _menus[index] = updatedMenu;
        notifyListeners();
      }
    }
  }
} 