import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import '../utils/constants.dart';

class OrderProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<OrderModel> _orders = [];
  bool _isLoading = false;
  
  // Track next order number per tenant
  Map<String, int> _nextOrderNumberByTenant = {};

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;

  // Get orders by buyer ID
  List<OrderModel> getOrdersByBuyer(String buyerId) {
    return _orders.where((order) => order.buyerId == buyerId).toList();
  }

  // Get current user's orders
  List<OrderModel> getUserOrders(String? currentUserId) {
    if (currentUserId == null) {
      return [];
    }
    
    return _orders.where((order) {
      return order.buyerId == currentUserId;
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

  // Get next order number for a specific tenant
  int _getNextOrderNumberForTenant(String tenantId) {
    // Initialize tenant order counter if not exists
    if (!_nextOrderNumberByTenant.containsKey(tenantId)) {
      // Find the highest order number for this tenant and increment it
      int maxOrderNumber = 0;
      for (var order in _orders) {
        // We need to find orders for this tenant by checking the menu
        // For now, we'll use a simple approach and assume the order number is per tenant
        if (order.orderNumber != null && order.orderNumber! > maxOrderNumber) {
          maxOrderNumber = order.orderNumber!;
        }
      }
      _nextOrderNumberByTenant[tenantId] = maxOrderNumber + 1;
    }
    
    return _nextOrderNumberByTenant[tenantId]!;
  }

  // Load orders from Firestore
  Future<void> loadOrders() async {
    _isLoading = true;
    notifyListeners();

    try {
      final querySnapshot = await _firestore.collection('orders').get();
      
      _orders = querySnapshot.docs.map((doc) {
        final data = doc.data();
        // Add the document ID to the data map
        final dataWithId = Map<String, dynamic>.from(data);
        dataWithId['id'] = doc.id;
        
        // Convert Firestore timestamp to string for fromMap
        if (data['timestamp'] != null) {
          dataWithId['timestamp'] = (data['timestamp'] as Timestamp).toDate().toIso8601String();
        }
        
        // Debug: Print rejection reason if it exists
        if (data['rejectionReason'] != null) {
          print('Found rejection reason in Firestore: ${data['rejectionReason']}');
        }
        
        return OrderModel.fromMap(dataWithId);
      }).toList();
      
      // Update the order number counters based on loaded orders
      _updateOrderNumberCounters();
    } catch (e) {
      print('Error loading orders: $e');
      // If there's an error, use mock data for testing
      _loadMockOrders();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Update order number counters based on existing orders
  void _updateOrderNumberCounters() {
    _nextOrderNumberByTenant.clear();
    // Group orders by tenant and find max order number for each
    Map<String, int> maxOrderByTenant = {};
    
    for (var order in _orders) {
      if (order.orderNumber != null) {
        String tenantKey = 'tenant_${order.menuId}'; // Simplified tenant identification
        int currentMax = maxOrderByTenant[tenantKey] ?? 0;
        if (order.orderNumber! > currentMax) {
          maxOrderByTenant[tenantKey] = order.orderNumber!;
        }
      }
    }
    
    // Set next order number for each tenant
    maxOrderByTenant.forEach((tenantKey, maxOrder) {
      _nextOrderNumberByTenant[tenantKey] = maxOrder + 1;
    });
  }

  // Add a new order with incremental number per tenant
  Future<void> addOrder(OrderModel order, {String? tenantId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Get next incremental order number for this tenant
      final orderNumber = tenantId != null ? _getNextOrderNumberForTenant(tenantId) : 1;
      
      final orderData = {
        'buyerId': order.buyerId,
        'menuId': order.menuId,
        'quantity': order.quantity,
        'customNote': order.customNote,
        'status': order.status,
        'timestamp': FieldValue.serverTimestamp(),
        'orderNumber': orderNumber,
      };
      
      final docRef = await _firestore.collection('orders').add(orderData);
      
      // Add to local list with the incremental order number
      final newOrder = order.copyWith(
        id: docRef.id,
        orderNumber: orderNumber,
      );
      _orders.add(newOrder);
      
      // Update the next order number for this tenant
      if (tenantId != null) {
        _nextOrderNumberByTenant[tenantId] = orderNumber + 1;
      }
      
    } catch (e) {
      print('Error adding order: $e');
      // For demo purposes, still add to local list even if Firestore fails
      final orderNumber = tenantId != null ? _getNextOrderNumberForTenant(tenantId) : 1;
      final newOrder = order.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        orderNumber: orderNumber,
      );
      _orders.add(newOrder);
      
      if (tenantId != null) {
        _nextOrderNumberByTenant[tenantId] = orderNumber + 1;
      }
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

  // Reject order with reason
  Future<void> rejectOrder(String orderId, String rejectionReason) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': OrderStatus.rejected,
        'rejectionReason': rejectionReason,
      });
      
      // Update in local list
      final index = _orders.indexWhere((order) => order.id == orderId);
      if (index != -1) {
        final updatedOrder = _orders[index].copyWith(
          status: OrderStatus.rejected,
          rejectionReason: rejectionReason,
        );
        _orders[index] = updatedOrder;
      }
    } catch (e) {
      print('Error rejecting order: $e');
      // For demo purposes, still update the local list even if Firestore fails
      final index = _orders.indexWhere((order) => order.id == orderId);
      if (index != -1) {
        final updatedOrder = _orders[index].copyWith(
          status: OrderStatus.rejected,
          rejectionReason: rejectionReason,
        );
        _orders[index] = updatedOrder;
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  // Accept order with optional estimation time
  Future<void> acceptOrder(String orderId, {int estimatedMinutes = 5}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final estimatedCompletionTime = DateTime.now().add(Duration(minutes: estimatedMinutes));
      
      await _firestore.collection('orders').doc(orderId).update({
        'status': OrderStatus.created,
        'estimatedMinutes': estimatedMinutes,
        'estimatedCompletionTime': estimatedCompletionTime.toIso8601String(),
      });
      
      // Update in local list
      final index = _orders.indexWhere((order) => order.id == orderId);
      if (index != -1) {
        final updatedOrder = _orders[index].copyWith(
          status: OrderStatus.created,
          estimatedMinutes: estimatedMinutes,
          estimatedCompletionTime: estimatedCompletionTime,
        );
        _orders[index] = updatedOrder;
      }
    } catch (e) {
      print('Error accepting order: $e');
      // For demo purposes, still update the local list even if Firestore fails
      final index = _orders.indexWhere((order) => order.id == orderId);
      if (index != -1) {
        final estimatedCompletionTime = DateTime.now().add(Duration(minutes: estimatedMinutes));
        final updatedOrder = _orders[index].copyWith(
          status: OrderStatus.created,
          estimatedMinutes: estimatedMinutes,
          estimatedCompletionTime: estimatedCompletionTime,
        );
        _orders[index] = updatedOrder;
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  // Delete order (for rejected orders)
  Future<void> deleteOrder(String orderId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firestore.collection('orders').doc(orderId).delete();
      
      // Remove from local list
      _orders.removeWhere((order) => order.id == orderId);
    } catch (e) {
      print('Error deleting order: $e');
      // For demo purposes, still remove from local list even if Firestore fails
      _orders.removeWhere((order) => order.id == orderId);
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load mock orders for testing when Firestore is not available
  void _loadMockOrders() {
    print('Loading mock orders...');
    _orders = [
      // New orders with orderNumber
      OrderModel(
        id: '1',
        buyerId: 'buyer1',
        menuId: 'menu1',
        quantity: 2,
        customNote: 'Nasi nya dipisah dan sambalnya sedikit saja',
        status: OrderStatus.created,
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        orderNumber: 1,
        estimatedMinutes: 10,
        estimatedCompletionTime: DateTime.now().add(const Duration(minutes: 10)),
      ),
      OrderModel(
        id: '2',
        buyerId: 'buyer1',
        menuId: 'menu2',
        quantity: 1,
        customNote: 'Sambal dicampur saja',
        status: OrderStatus.ready,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        orderNumber: 2,
        estimatedMinutes: 5,
        estimatedCompletionTime: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      OrderModel(
        id: '3',
        buyerId: 'buyer2',
        menuId: 'menu3',
        quantity: 1,
        customNote: 'Tidak pakai sambal',
        status: OrderStatus.sent,
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        orderNumber: 3,
      ),
      OrderModel(
        id: '4',
        buyerId: 'buyer1',
        menuId: 'menu1',
        quantity: 1,
        customNote: 'Extra pedas',
        status: OrderStatus.rejected,
        timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
        orderNumber: 4,
        rejectionReason: 'Stock rupanya habis',
      ),
      // Legacy orders without orderNumber (will show 0)
              OrderModel(
          id: 'legacy1',
          buyerId: 'buyer1',
          menuId: 'menu1',
          quantity: 1,
          customNote: 'Pesanan lama tanpa nomor urut',
          status: OrderStatus.completed,
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          orderNumber: null, // Legacy order without orderNumber
        ),
        OrderModel(
          id: 'legacy2',
          buyerId: 'buyer2',
          menuId: 'menu4',
          quantity: 2,
          status: OrderStatus.completed,
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
          orderNumber: null, // Legacy order without orderNumber
        ),
    ];
    
    print('Mock orders loaded: ${_orders.length}');
    print('Rejected orders with reasons: ${_orders.where((o) => o.status == OrderStatus.rejected && o.rejectionReason != null).map((o) => "ID: ${o.id}, Reason: ${o.rejectionReason}").join(", ")}');
    
    // Update counters based on mock data
    _updateOrderNumberCounters();
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