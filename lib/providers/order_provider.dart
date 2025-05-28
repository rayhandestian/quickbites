import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
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
      // If there's an error, use an empty list
      _orders = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  // Add a new order
  Future<String> addOrder({
    required String buyerId,
    required String menuId,
    required int quantity,
    String? customNote,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final orderData = {
        'buyerId': buyerId,
        'menuId': menuId,
        'quantity': quantity,
        'customNote': customNote,
        'status': OrderStatus.created,
        'timestamp': FieldValue.serverTimestamp(),
      };
      
      final docRef = await _firestore.collection('orders').add(orderData);
      final orderId = docRef.id;
      
      // Add to local list
      final newOrder = OrderModel(
        id: orderId,
        buyerId: buyerId,
        menuId: menuId,
        quantity: quantity,
        customNote: customNote,
        status: OrderStatus.created,
        timestamp: DateTime.now(),
      );
      
      _orders.add(newOrder);
      
      _isLoading = false;
      notifyListeners();
      
      return orderId;
    } catch (e) {
      print('Error adding order: $e');
      _isLoading = false;
      notifyListeners();
      return '';
    }
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
    }

    _isLoading = false;
    notifyListeners();
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