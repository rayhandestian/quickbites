import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/mock_data_service.dart';
import '../utils/constants.dart';

class OrderProvider with ChangeNotifier {
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

  // Load orders from mock data
  Future<void> loadOrders() async {
    _isLoading = true;
    notifyListeners();

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Load mock data
    _orders = MockDataService.getMockOrders();

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

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Create new order
    final newOrderId = 'order${_orders.length + 1}';
    final newOrder = OrderModel(
      id: newOrderId,
      buyerId: buyerId,
      menuId: menuId,
      quantity: quantity,
      customNote: customNote,
      status: OrderStatus.created,
      timestamp: DateTime.now(),
    );

    // Add to list
    _orders.add(newOrder);

    _isLoading = false;
    notifyListeners();

    return newOrderId;
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    _isLoading = true;
    notifyListeners();

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Find and update order
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index != -1) {
      final updatedOrder = _orders[index].copyWith(status: newStatus);
      _orders[index] = updatedOrder;
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