import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/menu_model.dart';
import '../models/order_model.dart';
import '../models/tenant_model.dart';

class FirebaseService {
  // Firestore collections
  final CollectionReference _usersCollection = FirebaseFirestore.instance.collection('users');
  final CollectionReference _menusCollection = FirebaseFirestore.instance.collection('menus');
  final CollectionReference _ordersCollection = FirebaseFirestore.instance.collection('orders');
  final CollectionReference _tenantsCollection = FirebaseFirestore.instance.collection('tenants');

  // Users operations
  Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (doc.exists) {
        return UserModel.fromMap({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>
        });
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  Future<List<UserModel>> getUsers() async {
    try {
      final snapshot = await _usersCollection.get();
      return snapshot.docs
          .map((doc) => UserModel.fromMap({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>
              }))
          .toList();
    } catch (e) {
      print('Error getting users: $e');
      return [];
    }
  }

  Future<String> addUser(UserModel user) async {
    try {
      // Remove id from the map as Firestore will generate one
      final userData = user.toMap();
      userData.remove('id');
      
      final doc = await _usersCollection.add(userData);
      return doc.id;
    } catch (e) {
      print('Error adding user: $e');
      return '';
    }
  }

  // Menus operations
  Future<MenuModel?> getMenu(String menuId) async {
    try {
      final doc = await _menusCollection.doc(menuId).get();
      if (doc.exists) {
        return MenuModel.fromMap({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>
        });
      }
      return null;
    } catch (e) {
      print('Error getting menu: $e');
      return null;
    }
  }

  Future<List<MenuModel>> getMenus() async {
    try {
      final snapshot = await _menusCollection.get();
      return snapshot.docs
          .map((doc) => MenuModel.fromMap({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>
              }))
          .toList();
    } catch (e) {
      print('Error getting menus: $e');
      return [];
    }
  }

  Future<List<MenuModel>> getMenusByCategory(String category) async {
    try {
      final snapshot = await _menusCollection.where('category', isEqualTo: category).get();
      return snapshot.docs
          .map((doc) => MenuModel.fromMap({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>
              }))
          .toList();
    } catch (e) {
      print('Error getting menus by category: $e');
      return [];
    }
  }

  Future<List<MenuModel>> getMenusByTenant(String tenantId) async {
    try {
      final snapshot = await _menusCollection.where('tenantId', isEqualTo: tenantId).get();
      return snapshot.docs
          .map((doc) => MenuModel.fromMap({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>
              }))
          .toList();
    } catch (e) {
      print('Error getting menus by tenant: $e');
      return [];
    }
  }

  Future<String> addMenu(MenuModel menu) async {
    try {
      // Remove id from the map as Firestore will generate one
      final menuData = menu.toMap();
      menuData.remove('id');
      
      final doc = await _menusCollection.add(menuData);
      return doc.id;
    } catch (e) {
      print('Error adding menu: $e');
      return '';
    }
  }

  Future<void> updateMenu(MenuModel menu) async {
    try {
      // Remove id from the map as it's not needed for update
      final menuData = menu.toMap();
      menuData.remove('id');
      
      await _menusCollection.doc(menu.id).update(menuData);
    } catch (e) {
      print('Error updating menu: $e');
    }
  }

  Future<void> deleteMenu(String menuId) async {
    try {
      await _menusCollection.doc(menuId).delete();
    } catch (e) {
      print('Error deleting menu: $e');
    }
  }

  // Orders operations
  Future<OrderModel?> getOrder(String orderId) async {
    try {
      final doc = await _ordersCollection.doc(orderId).get();
      if (doc.exists) {
        return OrderModel.fromMap({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>
        });
      }
      return null;
    } catch (e) {
      print('Error getting order: $e');
      return null;
    }
  }

  Future<List<OrderModel>> getOrders() async {
    try {
      final snapshot = await _ordersCollection.get();
      return snapshot.docs
          .map((doc) => OrderModel.fromMap({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>
              }))
          .toList();
    } catch (e) {
      print('Error getting orders: $e');
      return [];
    }
  }

  Future<List<OrderModel>> getOrdersByBuyer(String buyerId) async {
    try {
      final snapshot = await _ordersCollection.where('buyerId', isEqualTo: buyerId).get();
      return snapshot.docs
          .map((doc) => OrderModel.fromMap({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>
              }))
          .toList();
    } catch (e) {
      print('Error getting orders by buyer: $e');
      return [];
    }
  }

  Future<List<OrderModel>> getOrdersByStatus(String status) async {
    try {
      final snapshot = await _ordersCollection.where('status', isEqualTo: status).get();
      return snapshot.docs
          .map((doc) => OrderModel.fromMap({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>
              }))
          .toList();
    } catch (e) {
      print('Error getting orders by status: $e');
      return [];
    }
  }

  Future<String> addOrder(OrderModel order) async {
    try {
      // Remove id from the map as Firestore will generate one
      final orderData = order.toMap();
      orderData.remove('id');
      
      // Add a timestamp if not provided
      if (!orderData.containsKey('timestamp')) {
        orderData['timestamp'] = FieldValue.serverTimestamp();
      }
      
      final doc = await _ordersCollection.add(orderData);
      return doc.id;
    } catch (e) {
      print('Error adding order: $e');
      return '';
    }
  }

  Future<void> updateOrder(OrderModel order) async {
    try {
      // Remove id from the map as it's not needed for update
      final orderData = order.toMap();
      orderData.remove('id');
      
      await _ordersCollection.doc(order.id).update(orderData);
    } catch (e) {
      print('Error updating order: $e');
    }
  }

  // Tenants operations
  Future<TenantModel?> getTenant(String tenantId) async {
    try {
      final doc = await _tenantsCollection.doc(tenantId).get();
      if (doc.exists) {
        return TenantModel.fromMap({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>
        });
      }
      return null;
    } catch (e) {
      print('Error getting tenant: $e');
      return null;
    }
  }

  Future<List<TenantModel>> getTenants() async {
    try {
      final snapshot = await _tenantsCollection.get();
      return snapshot.docs
          .map((doc) => TenantModel.fromMap({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>
              }))
          .toList();
    } catch (e) {
      print('Error getting tenants: $e');
      return [];
    }
  }

  Future<String> addTenant(TenantModel tenant) async {
    try {
      // Remove id from the map as Firestore will generate one
      final tenantData = tenant.toMap();
      tenantData.remove('id');
      
      final doc = await _tenantsCollection.add(tenantData);
      return doc.id;
    } catch (e) {
      print('Error adding tenant: $e');
      return '';
    }
  }
} 