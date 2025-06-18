import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/menu_model.dart';
import '../../models/order_model.dart';

import '../../providers/menu_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/tenant_provider.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../widgets/app_button.dart';

class SellerOrdersScreen extends StatefulWidget {
  const SellerOrdersScreen({Key? key}) : super(key: key);

  @override
  State<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends State<SellerOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Load orders when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderProvider>(context, listen: false).loadOrders();
      Provider.of<MenuProvider>(context, listen: false).loadMenus();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final menuProvider = Provider.of<MenuProvider>(context);
    final orderProvider = Provider.of<OrderProvider>(context);
    final tenantProvider = Provider.of<TenantProvider>(context);
    
    if (authService.currentUser == null) {
      return const Center(
        child: Text('Silakan login untuk melihat pesanan'),
      );
    }
    
    // Get seller's tenant
    final tenant = tenantProvider.getTenantBySellerId(authService.currentUser!.id);
    
    if (tenant == null) {
      return const Center(
        child: Text('Tenant tidak ditemukan'),
      );
    }
    
    // Get seller's menu items
    final menuItems = menuProvider.getMenusByTenant(tenant.id);
    
    // Get all menu IDs for this tenant
    final menuIds = menuItems.map((menu) => menu.id).toList();
    
    // Get orders for this tenant
    final allOrders = orderProvider.getOrdersByTenant(tenant.id, menuIds);
    
    // Filter orders by status
    final newOrders = allOrders.where((order) => order.status == OrderStatus.sent).toList();
    final inProgressOrders = allOrders.where((order) => order.status == OrderStatus.created).toList();
    final readyOrders = allOrders.where((order) => order.status == OrderStatus.ready).toList();
    final completedOrders = allOrders.where((order) => order.status == OrderStatus.completed).toList();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesanan'),
        automaticallyImplyLeading: false,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryAccent,
          unselectedLabelColor: AppColors.textPrimary.withOpacity(0.5),
          indicatorColor: AppColors.primaryAccent,
          isScrollable: false,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Baru'),
            Tab(text: 'Diproses'),
            Tab(text: 'Siap'),
            Tab(text: 'Histori'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrderList(context, newOrders, menuProvider, OrderStatus.sent),
          _buildOrderList(context, inProgressOrders, menuProvider, OrderStatus.created),
          _buildOrderList(context, readyOrders, menuProvider, OrderStatus.ready),
          _buildOrderList(context, completedOrders, menuProvider, OrderStatus.completed),
        ],
      ),
    );
  }
  
  Widget _buildOrderList(
    BuildContext context, 
    List<OrderModel> orders, 
    MenuProvider menuProvider,
    String status,
  ) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getStatusIcon(status),
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak ada pesanan ${_getStatusText(status).toLowerCase()}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: () async {
        await Provider.of<OrderProvider>(context, listen: false).loadOrders();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          final menu = menuProvider.getMenuById(order.menuId);
          
          if (menu == null) {
            return const SizedBox.shrink();
          }
          
          return _buildOrderCard(context, order, menu, status);
        },
      ),
    );
  }
  
  IconData _getStatusIcon(String status) {
    switch (status) {
      case OrderStatus.sent:
        return Icons.receipt_long;
      case OrderStatus.created:
        return Icons.restaurant;
      case OrderStatus.ready:
        return Icons.room_service;
      case OrderStatus.completed:
        return Icons.check_circle;
      default:
        return Icons.receipt;
    }
  }
  
  Widget _buildOrderCard(BuildContext context, OrderModel order, MenuModel menu, String currentStatus) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(order.status).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getStatusText(order.status),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _getStatusColor(order.status),
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Order ID and Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nomor Urutan: ${order.orderNumber ?? 0}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  _formatDate(order.timestamp),
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Menu Item
            Row(
              children: [
                // Menu Image
                Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _isValidImageUrl(menu.imageUrl)
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          menu.imageUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              menu.category == FoodCategories.food ? Icons.lunch_dining : Icons.local_drink,
                              size: 30,
                              color: AppColors.primaryAccent,
                            );
                          },
                        ),
                      )
                    : Center(
                        child: Icon(
                          menu.category == FoodCategories.food ? Icons.lunch_dining : Icons.local_drink,
                          size: 30,
                          color: AppColors.primaryAccent,
                        ),
                      ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        menu.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${order.quantity}x ${formatCurrency(menu.price)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.primaryAccent,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatCurrency(menu.price * order.quantity),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            
            // Custom Note
            if (order.customNote != null && order.customNote!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Catatan: ${order.customNote}',
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textPrimary.withOpacity(0.7),
                  ),
                ),
              ),
            
            const Divider(height: 24),
            
            // Action Buttons
            _buildOrderActions(context, order, currentStatus, menu),
          ],
        ),
      ),
    );
  }
  
  String _getStatusText(String status) {
    switch (status) {
      case OrderStatus.sent:
        return 'Pesanan Baru';
      case OrderStatus.created:
        return 'Pesanan Diterima';
      case OrderStatus.ready:
        return 'Siap Diambil';
      case OrderStatus.completed:
        return 'Histori';
      default:
        return 'Unknown';
    }
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case OrderStatus.sent:
        return Colors.orange;
      case OrderStatus.created:
        return Colors.blue;
      case OrderStatus.ready:
        return Colors.green;
      case OrderStatus.completed:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  // Format date to Indonesian format
  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    
    return '$day/$month/$year $hour:$minute';
  }

  // Helper method to check if an image URL exists and is valid
  bool _isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) {
      return false;
    }
    
    // Basic URL validation
    final validUrl = Uri.tryParse(url);
    if (validUrl == null || !validUrl.isAbsolute) {
      return false;
    }
    
    return true;
  }

  // Add this method to handle order actions based on status
  Widget _buildOrderActions(BuildContext context, OrderModel order, String currentStatus, MenuModel menu) {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final menuProvider = Provider.of<MenuProvider>(context, listen: false);

    if (currentStatus == OrderStatus.sent) {
      return AppButton(
        text: 'Terima Pesanan',
        onPressed: () async {
          // Update stock first
          await menuProvider.updateStock(menu.id, menu.stock - order.quantity);
          
          // Then update order status
          await orderProvider.updateOrderStatus(order.id, OrderStatus.created);
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pesanan diterima')),
          );
        },
      );
    } else if (currentStatus == OrderStatus.created) {
      return AppButton(
        text: 'Siap Diambil',
        onPressed: () async {
          await orderProvider.updateOrderStatus(order.id, OrderStatus.ready);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pesanan siap diambil')),
          );
        },
      );
    } else if (currentStatus == OrderStatus.ready) {
      return const Text(
        'Menunggu pelanggan mengambil pesanan',
        style: TextStyle(
          fontSize: 14,
          fontStyle: FontStyle.italic,
          color: Colors.blue,
        ),
        textAlign: TextAlign.center,
      );
    } else {
      return const Text(
        'Pesanan selesai',
        style: TextStyle(
          fontSize: 14,
          fontStyle: FontStyle.italic,
          color: Colors.green,
        ),
        textAlign: TextAlign.center,
      );
    }
  }
} 