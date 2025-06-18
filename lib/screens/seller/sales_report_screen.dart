import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order_model.dart';
import '../../models/menu_model.dart';
import '../../providers/order_provider.dart';
import '../../providers/menu_provider.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';

class SalesReportScreen extends StatefulWidget {
  final String reportPeriod;
  final String tenantId;

  const SalesReportScreen({
    Key? key,
    required this.reportPeriod,
    required this.tenantId,
  }) : super(key: key);

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  String _selectedPeriod = '';
  
  @override
  void initState() {
    super.initState();
    _selectedPeriod = widget.reportPeriod;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Penjualan Detail'),
        backgroundColor: AppColors.primaryAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer2<OrderProvider, MenuProvider>(
        builder: (context, orderProvider, menuProvider, child) {
          final allMenus = menuProvider.menus;
          final sellerMenus = allMenus.where((menu) => menu.tenantId == widget.tenantId).toList();
          final menuIds = sellerMenus.map((menu) => menu.id).toList();
          final allOrders = orderProvider.getOrdersByTenant(widget.tenantId, menuIds);
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Period Selector
                _buildPeriodSelector(),
                const SizedBox(height: 24),
                
                // Summary Cards
                _buildSummarySection(allOrders, sellerMenus),
                const SizedBox(height: 24),
                
                // Sales Chart (Mock)
                _buildSalesChart(),
                const SizedBox(height: 24),
                
                // Top Selling Items
                _buildTopSellingItems(allOrders, sellerMenus),
                const SizedBox(height: 24),
                
                // Order History
                _buildOrderHistory(allOrders, sellerMenus),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Periode Laporan:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            DropdownButton<String>(
              value: _selectedPeriod,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedPeriod = newValue!;
                });
              },
              items: <String>['Harian', 'Bulanan', 'Mingguan']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(List<OrderModel> orders, List<MenuModel> menus) {
    final filteredOrders = _getFilteredOrders(orders);
    final completedOrders = filteredOrders.where((order) => order.status == OrderStatus.completed).toList();
    
    // Calculate revenue from completed orders
    double totalRevenue = 0;
    for (var order in completedOrders) {
      final menu = menus.firstWhere(
        (m) => m.id == order.menuId, 
        orElse: () => MenuModel(
          id: '', 
          name: '', 
          price: 0, 
          stock: 0, 
          tenantId: '', 
          category: FoodCategories.food,
        )
      );
      totalRevenue += menu.price * order.quantity;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ringkasan $_selectedPeriod',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Pesanan',
                filteredOrders.length.toString(),
                Icons.receipt_long,
                AppColors.primaryAccent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Pesanan Selesai',
                completedOrders.length.toString(),
                Icons.check_circle,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Pendapatan',
                formatCurrency(totalRevenue.toInt()),
                Icons.payments,
                AppColors.secondaryAccent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Rata-rata/Pesanan',
                formatCurrency(completedOrders.isNotEmpty ? (totalRevenue / completedOrders.length).toInt() : 0),
                Icons.analytics,
                Colors.blue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textPrimary.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesChart() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, color: AppColors.primaryAccent),
                const SizedBox(width: 8),
                const Text(
                  'Grafik Penjualan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.primaryAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.analytics,
                      size: 48,
                      color: AppColors.primaryAccent.withOpacity(0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Grafik penjualan $_selectedPeriod',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textPrimary.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSellingItems(List<OrderModel> orders, List<MenuModel> menus) {
    final filteredOrders = _getFilteredOrders(orders);
    
    // Count sales by menu item
    Map<String, int> salesCount = {};
    Map<String, double> salesRevenue = {};
    
    for (var order in filteredOrders.where((o) => o.status == OrderStatus.completed)) {
      salesCount[order.menuId] = (salesCount[order.menuId] ?? 0) + order.quantity;
      final menu = menus.firstWhere(
        (m) => m.id == order.menuId, 
        orElse: () => MenuModel(
          id: '', 
          name: '', 
          price: 0, 
          stock: 0, 
          tenantId: '', 
          category: FoodCategories.food,
        )
      );
      salesRevenue[order.menuId] = (salesRevenue[order.menuId] ?? 0) + (menu.price * order.quantity);
    }
    
    // Sort by sales count
    final topItems = salesCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 8),
                const Text(
                  'Menu Terlaris',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (topItems.isEmpty)
              const Center(
                child: Text(
                  'Belum ada penjualan',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
              )
            else
              ...topItems.take(5).map((entry) {
                final menu = menus.firstWhere(
                  (m) => m.id == entry.key, 
                  orElse: () => MenuModel(
                    id: '', 
                    name: 'Menu tidak ditemukan', 
                    price: 0, 
                    stock: 0, 
                    tenantId: '', 
                    category: FoodCategories.food,
                  )
                );
                final count = entry.value;
                final revenue = salesRevenue[entry.key] ?? 0;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primaryAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          menu.category == FoodCategories.food ? Icons.lunch_dining : Icons.local_drink,
                          color: AppColors.primaryAccent,
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
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Terjual: $count • ${formatCurrency(revenue.toInt())}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textPrimary.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHistory(List<OrderModel> orders, List<MenuModel> menus) {
    final filteredOrders = _getFilteredOrders(orders);
    filteredOrders.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: AppColors.primaryAccent),
                const SizedBox(width: 8),
                const Text(
                  'Riwayat Pesanan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (filteredOrders.isEmpty)
              const Center(
                child: Text(
                  'Belum ada pesanan',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
              )
            else
              ...filteredOrders.take(10).map((order) {
                final menu = menus.firstWhere(
                  (m) => m.id == order.menuId, 
                  orElse: () => MenuModel(
                    id: '', 
                    name: 'Menu tidak ditemukan', 
                    price: 0, 
                    stock: 0, 
                    tenantId: '', 
                    category: FoodCategories.food,
                  )
                );
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(order.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '#${order.orderNumber ?? 0}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(order.status),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${menu.name} x${order.quantity}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '${_formatDate(order.timestamp)} • ${formatCurrency(menu.price * order.quantity)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textPrimary.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(order.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getStatusText(order.status),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: _getStatusColor(order.status),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  List<OrderModel> _getFilteredOrders(List<OrderModel> orders) {
    final now = DateTime.now();
    
    switch (_selectedPeriod) {
      case 'Harian':
        return orders.where((order) {
          final orderDate = order.timestamp;
          return orderDate.year == now.year &&
                 orderDate.month == now.month &&
                 orderDate.day == now.day;
        }).toList();
      case 'Mingguan':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        return orders.where((order) {
          final orderDate = order.timestamp;
          return orderDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
                 orderDate.isBefore(weekEnd.add(const Duration(days: 1)));
        }).toList();
      case 'Bulanan':
        return orders.where((order) {
          final orderDate = order.timestamp;
          return orderDate.year == now.year &&
                 orderDate.month == now.month;
        }).toList();
      default:
        return orders;
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
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case OrderStatus.sent:
        return 'Baru';
      case OrderStatus.created:
        return 'Diterima';
      case OrderStatus.ready:
        return 'Siap';
      case OrderStatus.completed:
        return 'Selesai';
      default:
        return 'Unknown';
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    
    return '$day/$month $hour:$minute';
  }
} 