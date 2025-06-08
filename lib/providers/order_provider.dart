import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../services/auth_service.dart';
import '../providers/menu_provider.dart';
import '../utils/constants.dart';

class OrderProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<OrderModel> _orders = [];
  bool _isLoading = false;

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;

  // Get orders by buyer ID
  List<OrderModel> getOrdersByBuyer(String buyerId) {
    return _orders.where((order) => order.buyerId == buyerId).toList();
  }

  // Get current user's orders
  List<OrderModel> getUserOrders() {
    return _orders.where((order) {
      // Here we'd normally filter by the current user's ID
      // For demo purposes, we're returning all orders
      return true; // In a real app, you'd check against the current user ID
    }).toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Sort by newest first
  }

  // Get orders for seller
  List<OrderModel> getSellerOrders(String sellerId) {
    // In a real app, you'd filter orders based on the menu items owned by this seller
    // For demo purposes, we're returning all orders that aren't completed
    return _orders.where((order) => order.status != 'selesai').toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Sort by newest first
  }

  // Get orders by status
  List<OrderModel> getOrdersByStatus(String status) {
    return _orders.where((order) => order.status == status).toList();
  }

  // Get a single order by ID
  OrderModel? getOrderById(String orderId) {
    try {
      return _orders.firstWhere((order) => order.id == orderId);
    } catch (e) {
      return null;
    }
  }

  // Load orders from Firestore
  Future<void> loadOrders() async {
    _isLoading = true;
    notifyListeners();

    try {
      final querySnapshot = await _firestore.collection('orders').get();
      
      _orders = querySnapshot.docs.map((doc) {
        return OrderModel(
          id: doc.id,
          buyerId: doc['buyerId'],
          menuId: doc['menuId'],
          quantity: doc['quantity'],
          customNote: doc['customNote'],
          status: doc['status'],
          timestamp: (doc['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      print('Error loading orders: $e');
      // If there's an error, use mock data for testing
      _loadMockOrders();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Add a new order
  Future<void> addOrder(OrderModel order) async {
    _isLoading = true;
    notifyListeners();

    try {
      final orderData = {
        'buyerId': order.buyerId,
        'menuId': order.menuId,
        'quantity': order.quantity,
        'customNote': order.customNote,
        'status': order.status,
        'timestamp': FieldValue.serverTimestamp(),
      };
      
      final docRef = await _firestore.collection('orders').add(orderData);
      
      // Add to local list with the generated Firestore ID
      final newOrder = order.copyWith(id: docRef.id);
      _orders.add(newOrder);
      
    } catch (e) {
      print('Error adding order: $e');
      // For demo purposes, still add to local list even if Firestore fails
      _orders.add(order);
    }

    _isLoading = false;
    notifyListeners();
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': newStatus,
      });
      
      // Update in local list
      final index = _orders.indexWhere((order) => order.id == orderId);
      if (index != -1) {
        final updatedOrder = _orders[index].copyWith(status: newStatus);
        _orders[index] = updatedOrder;
      }
    } catch (e) {
      print('Error updating order status: $e');
      // For demo purposes, still update the local list even if Firestore fails
      final index = _orders.indexWhere((order) => order.id == orderId);
      if (index != -1) {
        final updatedOrder = _orders[index].copyWith(status: newStatus);
        _orders[index] = updatedOrder;
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load mock orders for testing when Firestore is not available
  void _loadMockOrders() {
    _orders = [
      OrderModel(
        id: '1',
        buyerId: 'buyer1',
        menuId: 'menu1',
        quantity: 2,
        customNote: 'Nasi nya dipisah dan sambalnya sedikit saja',
        status: 'dibuat',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      OrderModel(
        id: '2',
        buyerId: 'buyer1',
        menuId: 'menu2',
        quantity: 1,
        customNote: 'Sambal dicampur saja',
        status: 'siap',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      OrderModel(
        id: '3',
        buyerId: 'buyer2',
        menuId: 'menu3',
        quantity: 1,
        customNote: 'Tidak pakai sambal',
        status: 'dibuat',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      ),
    ];
  }

  // Get orders by tenant (for seller)
  List<OrderModel> getOrdersByTenant(String tenantId, List<String> menuIds) {
    return _orders.where((order) => menuIds.contains(order.menuId)).toList();
  }

  // Get active orders (not completed)
  List<OrderModel> getActiveOrders(String buyerId) {
    return _orders.where((order) => 
      order.buyerId == buyerId && 
      order.status != OrderStatus.completed
    ).toList();
  }
} 