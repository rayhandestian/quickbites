import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import '../models/menu_model.dart';
import '../utils/constants.dart';

class OrderProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<OrderModel> _orders = [];
  bool _isLoading = false;
  
  // Track next order number per tenant
  Map<String, int> _nextOrderNumberByTenant = {};
  
  // Cache menu data to get tenant information
  Map<String, String> _menuToTenantMap = {};

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
  Future<int> _getNextOrderNumberForTenant(String tenantId) async {
    // Initialize tenant order counter if not exists
    if (!_nextOrderNumberByTenant.containsKey(tenantId)) {
      // Find the highest order number for this tenant by checking all orders
      int maxOrderNumber = 0;
      
      // Get all menus for this tenant first
      List<String> tenantMenuIds = [];
      try {
        final menuQuery = await _firestore
            .collection('menus')
            .where('tenantId', isEqualTo: tenantId)
            .get();
        
        tenantMenuIds = menuQuery.docs.map((doc) => doc.id).toList();
        
        // Update menu to tenant mapping
        for (var doc in menuQuery.docs) {
          _menuToTenantMap[doc.id] = tenantId;
        }
      } catch (e) {
        print('Error fetching menus for tenant $tenantId: $e');
      }
      
      // Find max order number for orders of this tenant's menus
      for (var order in _orders) {
        if (tenantMenuIds.contains(order.menuId) && order.orderNumber != null && order.orderNumber! > maxOrderNumber) {
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
      await _updateOrderNumberCounters();
    } catch (e) {
      print('Error loading orders: $e');
      // If there's an error, use mock data for testing
      await _loadMockOrders();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Update order number counters based on existing orders
  Future<void> _updateOrderNumberCounters() async {
    _nextOrderNumberByTenant.clear();
    
    // First, build the menu to tenant mapping
    try {
      final menuQuery = await _firestore.collection('menus').get();
      _menuToTenantMap.clear();
      
      for (var doc in menuQuery.docs) {
        final data = doc.data();
        if (data['tenantId'] != null) {
          _menuToTenantMap[doc.id] = data['tenantId'];
        }
      }
    } catch (e) {
      print('Error fetching menu data: $e');
    }
    
    // Group orders by tenant and find max order number for each
    Map<String, int> maxOrderByTenant = {};
    
    for (var order in _orders) {
      if (order.orderNumber != null) {
        String? tenantId = _menuToTenantMap[order.menuId];
        if (tenantId != null) {
          int currentMax = maxOrderByTenant[tenantId] ?? 0;
          if (order.orderNumber! > currentMax) {
            maxOrderByTenant[tenantId] = order.orderNumber!;
          }
        }
      }
    }
    
    // Set next order number for each tenant
    maxOrderByTenant.forEach((tenantId, maxOrder) {
      _nextOrderNumberByTenant[tenantId] = maxOrder + 1;
    });
  }

  // Add a new order with incremental number per tenant
  Future<void> addOrder(OrderModel order, {String? tenantId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Get next incremental order number for this tenant
      int orderNumber = 1;
      if (tenantId != null) {
        orderNumber = await _getNextOrderNumberForTenant(tenantId);
      } else {
        // If no tenantId provided, try to get it from menu data
        try {
          final menuDoc = await _firestore.collection('menus').doc(order.menuId).get();
          if (menuDoc.exists) {
            final menuData = menuDoc.data();
            if (menuData != null && menuData['tenantId'] != null) {
              tenantId = menuData['tenantId'] as String;
              orderNumber = await _getNextOrderNumberForTenant(tenantId!);
              _menuToTenantMap[order.menuId] = tenantId!;
            }
          }
        } catch (e) {
          print('Error fetching menu data for order: $e');
        }
      }
      
      final orderData = {
        'buyerId': order.buyerId,
        'menuId': order.menuId,
        'quantity': order.quantity,
        'customNote': order.customNote,
        'status': order.status,
        'timestamp': FieldValue.serverTimestamp(),
        'orderNumber': orderNumber,
        'tenantId': tenantId, // Store tenant ID directly in order for easier querying
      };
      
      final docRef = await _firestore.collection('orders').add(orderData);
      
      // Add to local list with the incremental order number and tenantId
      final newOrder = order.copyWith(
        id: docRef.id,
        orderNumber: orderNumber,
        tenantId: tenantId,
      );
      _orders.add(newOrder);
      
      // Update the next order number for this tenant
      if (tenantId != null) {
        _nextOrderNumberByTenant[tenantId] = orderNumber + 1;
      }
      
    } catch (e) {
      print('Error adding order: $e');
      // For demo purposes, still add to local list even if Firestore fails
      int orderNumber = 1;
      if (tenantId != null) {
        orderNumber = await _getNextOrderNumberForTenant(tenantId);
        _nextOrderNumberByTenant[tenantId] = orderNumber + 1;
      }
      
      final newOrder = order.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        orderNumber: orderNumber,
        tenantId: tenantId,
      );
      _orders.add(newOrder);
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
  Future<void> _loadMockOrders() async {
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
    await _updateOrderNumberCounters();
  }

  // Get orders by tenant (for seller) - now uses tenantId directly
  List<OrderModel> getOrdersByTenant(String tenantId, [List<String>? menuIds]) {
    return _orders.where((order) {
      // First try to use the tenantId field if available
      if (order.tenantId != null) {
        return order.tenantId == tenantId;
      }
      // Fallback to menu-based filtering for legacy orders
      if (menuIds != null) {
        return menuIds.contains(order.menuId);
      }
      // If no tenantId and no menuIds provided, check cached mapping
      return _menuToTenantMap[order.menuId] == tenantId;
    }).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Sort by newest first
  }

  // Get active orders (not completed)
  List<OrderModel> getActiveOrders(String buyerId) {
    return _orders.where((order) => 
      order.buyerId == buyerId && 
      order.status != OrderStatus.completed
    ).toList();
  }

  // Helper method to migrate existing orders to include tenantId
  Future<void> migrateOrdersWithTenantId() async {
    print('Starting migration of orders to include tenantId...');
    
    try {
      // Get all orders without tenantId
      final ordersToMigrate = _orders.where((order) => order.tenantId == null).toList();
      
      if (ordersToMigrate.isEmpty) {
        print('No orders need migration');
        return;
      }
      
      print('Found ${ordersToMigrate.length} orders to migrate');
      
      // Build menu to tenant mapping if not already done
      if (_menuToTenantMap.isEmpty) {
        await _updateOrderNumberCounters();
      }
      
      // Update each order
      for (var order in ordersToMigrate) {
        final tenantId = _menuToTenantMap[order.menuId];
        if (tenantId != null) {
          try {
            await _firestore.collection('orders').doc(order.id).update({
              'tenantId': tenantId,
            });
            
            // Update local order
            final index = _orders.indexWhere((o) => o.id == order.id);
            if (index != -1) {
              _orders[index] = order.copyWith(tenantId: tenantId);
            }
            
            print('Migrated order ${order.id} to tenant $tenantId');
          } catch (e) {
            print('Error migrating order ${order.id}: $e');
          }
        }
      }
      
      print('Migration completed');
      notifyListeners();
    } catch (e) {
      print('Error during migration: $e');
    }
  }
} 