import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/menu_model.dart';
import '../../models/order_model.dart';
import '../../models/tenant_model.dart';
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
    _tabController = TabController(length: 3, vsync: this);
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
    final pendingOrders = allOrders.where((order) => order.status == OrderStatus.created).toList();
    final readyOrders = allOrders.where((order) => order.status == OrderStatus.ready).toList();
    final completedOrders = allOrders.where((order) => order.status == OrderStatus.completed).toList();
    
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryAccent,
          unselectedLabelColor: AppColors.textPrimary.withOpacity(0.5),
          indicatorColor: AppColors.primaryAccent,
          tabs: const [
            Tab(text: 'Pesanan Baru'),
            Tab(text: 'Siap Diambil'),
            Tab(text: 'Selesai'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOrderList(context, pendingOrders, menuProvider, OrderStatus.created),
              _buildOrderList(context, readyOrders, menuProvider, OrderStatus.ready),
              _buildOrderList(context, completedOrders, menuProvider, OrderStatus.completed),
            ],
          ),
        ),
      ],
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
        child: Text('Tidak ada pesanan ${_getStatusText(status).toLowerCase()}'),
      );
    }
    
    return ListView.builder(
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
    );
  }
  
  Widget _buildOrderCard(BuildContext context, OrderModel order, MenuModel menu, String currentStatus) {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order ID and Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.id.substring(order.id.length - 4)}',
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
                // Menu Image (placeholder)
                Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
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
            
            const Divider(height: 32),
            
            // Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getStatusText(order.status),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _getStatusColor(order.status),
                  ),
                ),
                if (currentStatus == OrderStatus.created)
                  AppButton(
                    text: 'Siap Diambil',
                    onPressed: () {
                      // Update order status to ready
                      orderProvider.updateOrderStatus(order.id, OrderStatus.ready);
                    },
                    type: ButtonType.primary,
                    isFullWidth: false,
                    height: 40,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    
    return '$day/$month/$year $hour:$minute';
  }
  
  String _getStatusText(String status) {
    switch (status) {
      case OrderStatus.created:
        return 'Pesanan Dibuat';
      case OrderStatus.ready:
        return 'Siap Diambil';
      case OrderStatus.completed:
        return 'Selesai';
      default:
        return 'Unknown';
    }
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case OrderStatus.created:
        return Colors.orange;
      case OrderStatus.ready:
        return Colors.blue;
      case OrderStatus.completed:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
} 