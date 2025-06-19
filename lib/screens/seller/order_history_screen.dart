import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/menu_model.dart';
import '../../models/order_model.dart';
import '../../providers/menu_provider.dart';
import '../../providers/order_provider.dart';
import '../../utils/constants.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({Key? key}) : super(key: key);

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshOrders(BuildContext context) async {
    await Provider.of<OrderProvider>(context, listen: false).loadOrders();
    await Provider.of<MenuProvider>(context, listen: false).loadMenus();
  }

  @override
  Widget build(BuildContext context) {
    final menuProvider = Provider.of<MenuProvider>(context);
    final orderProvider = Provider.of<OrderProvider>(context, listen: true);

    final completedOrders = orderProvider.orders.where((order) => order.status == OrderStatus.completed).toList();
    final rejectedOrders = orderProvider.orders.where((order) => order.status == OrderStatus.rejected).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pesanan'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryAccent,
          unselectedLabelColor: AppColors.textPrimary.withOpacity(0.5),
          indicatorColor: AppColors.primaryAccent,
          tabs: const [
            Tab(text: 'Histori'),
            Tab(text: 'Ditolak'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrderList(context, completedOrders, menuProvider, OrderStatus.completed),
          _buildOrderList(context, rejectedOrders, menuProvider, OrderStatus.rejected),
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
      onRefresh: () => _refreshOrders(context),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          final menu = menuProvider.getMenuById(order.menuId);
          
          if (menu == null) {
            return const SizedBox.shrink();
          }
          
          return _buildOrderCard(context, order, menu);
        },
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order, MenuModel menu) {
    // This is a simplified and slightly modified version of the card from SellerOrdersScreen
    // to avoid code duplication issues and keep it self-contained.
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.id.substring(0, 6)}',
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
            Row(
              children: [
                if (_isValidImageUrl(menu.imageUrl))
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      menu.imageUrl!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
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
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${order.quantity} x Rp ${menu.price}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Rp ${menu.price * order.quantity}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryAccent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods copied from SellerOrdersScreen
  bool _isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) {
      return false;
    }
    final uri = Uri.tryParse(url);
    return uri != null && uri.isAbsolute;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.rejected:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case OrderStatus.completed:
        return 'Histori';
      case OrderStatus.rejected:
        return 'Ditolak';
      default:
        return 'Unknown';
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case OrderStatus.completed:
        return Icons.check_circle_outline;
      case OrderStatus.rejected:
        return Icons.cancel_outlined;
      default:
        return Icons.history;
    }
  }
} 