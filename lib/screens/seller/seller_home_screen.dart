import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/menu_model.dart';
import '../../models/tenant_model.dart';
import '../../providers/menu_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/tenant_provider.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import 'inventory_screen.dart';
import 'seller_orders_screen.dart';
import 'seller_profile_screen.dart';
import 'sales_report_screen.dart';

class SellerHomeScreen extends StatefulWidget {
  const SellerHomeScreen({Key? key}) : super(key: key);

  @override
  State<SellerHomeScreen> createState() => _SellerHomeScreenState();
}

class _SellerHomeScreenState extends State<SellerHomeScreen> {
  int _currentIndex = 0;
  String _selectedReportPeriod = 'Harian'; // Default to daily reports
  
  @override
  void initState() {
    super.initState();
    // Load data when the screen is initialized
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final menuProvider = Provider.of<MenuProvider>(context, listen: false);
    final tenantProvider = Provider.of<TenantProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    await Future.wait([
      menuProvider.loadMenus(),
      tenantProvider.loadTenants(),
      orderProvider.loadOrders(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final menuProvider = Provider.of<MenuProvider>(context);
    final orderProvider = Provider.of<OrderProvider>(context);
    final tenantProvider = Provider.of<TenantProvider>(context);
    
    // Get seller's tenant
    final tenant = tenantProvider.getTenantBySellerId(authService.currentUser?.id ?? '');
    
    // Get seller's menu items
    final menuItems = tenant != null 
        ? menuProvider.getMenusByTenant(tenant.id) 
        : <MenuModel>[];
    
    // Get all menu IDs for this tenant
    final menuIds = menuItems.map((menu) => menu.id).toList();
    
    // Get orders for this tenant
    final orders = orderProvider.getOrdersByTenant(tenant?.id ?? '', menuIds);
    
    // Count orders by status
    final int pendingOrders = orders.where((order) => order.status == OrderStatus.created).length;
    final int readyOrders = orders.where((order) => order.status == OrderStatus.ready).length;
    final int completedOrders = orders.where((order) => order.status == OrderStatus.completed).length;
    
    final List<Widget> screens = [
      _buildHomeContent(tenant, pendingOrders, readyOrders, completedOrders, menuItems.length, orders),
      const InventoryScreen(),
      const SellerOrdersScreen(),
      const SellerProfileScreen(),
    ];

    return Scaffold(
      appBar: _currentIndex != 2 ? AppBar(
        title: Text(
          _currentIndex == 0 ? 'Dashboard Penjual' : 
          _currentIndex == 1 ? 'Inventori' : 'Profil',
        ),
        automaticallyImplyLeading: false, // Remove back button
      ) : null,
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Inventori',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Pesanan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Akun',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent(
    TenantModel? tenant, 
    int pendingOrders, 
    int readyOrders, 
    int completedOrders,
    int totalMenuItems,
    List<dynamic> allOrders,
  ) {
    final totalOrders = pendingOrders + readyOrders + completedOrders;
    final totalRevenue = completedOrders * 15000; // Mock revenue calculation
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tenant Info
            Card(
              elevation: 0,
              color: AppColors.secondarySurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.primaryAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: tenant?.imageUrl != null && tenant!.imageUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              tenant!.imageUrl!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryAccent.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.store,
                                  color: Colors.white,
                                  size: 30,
                                );
                              },
                            ),
                          )
                        : const Icon(
                            Icons.store,
                            color: Colors.white,
                            size: 30,
                          ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tenant?.name ?? 'Toko Anda',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tenant?.description ?? 'Deskripsi toko Anda',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textPrimary.withOpacity(0.7),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Sales Report Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Laporan Penjualan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                DropdownButton<String>(
                  value: _selectedReportPeriod,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedReportPeriod = newValue!;
                    });
                  },
                  items: <String>['Harian', 'Bulanan']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            GestureDetector(
              onTap: () {
                final authService = Provider.of<AuthService>(context, listen: false);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SalesReportScreen(
                      reportPeriod: _selectedReportPeriod,
                      tenantId: tenant?.id ?? authService.currentUser?.id ?? '',
                    ),
                  ),
                );
              },
              child: _buildSalesReport(allOrders, _selectedReportPeriod),
            ),
            const SizedBox(height: 24),
            
            // Order Statistics
            const Text(
              'Statistik Pesanan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Pesanan',
                    totalOrders.toString(),
                    Icons.receipt,
                    AppColors.primaryAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Pendapatan',
                    formatCurrency(totalRevenue),
                    Icons.payments,
                    AppColors.secondaryAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Menu Aktif',
                    totalMenuItems.toString(),
                    Icons.restaurant_menu,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Pesanan Baru',
                    pendingOrders.toString(),
                    Icons.new_releases,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Orders Breakdown
            const Text(
              'Detail Pesanan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildOrderStatusCard(
              'Pesanan Dibuat',
              pendingOrders,
              Icons.hourglass_empty,
              Colors.orange,
            ),
            const SizedBox(height: 8),
            
            _buildOrderStatusCard(
              'Siap Diambil',
              readyOrders,
              Icons.check_circle_outline,
              Colors.blue,
            ),
            const SizedBox(height: 8),
            
            _buildOrderStatusCard(
              'Histori',
              completedOrders,
              Icons.done_all,
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSalesReport(List<dynamic> orders, String period) {
    // Filter orders for the selected period
    final now = DateTime.now();
    List<dynamic> filteredOrders;
    
    if (period == 'Harian') {
      // Get orders from today
      filteredOrders = orders.where((order) {
        final orderDate = order.timestamp;
        return orderDate.year == now.year &&
               orderDate.month == now.month &&
               orderDate.day == now.day;
      }).toList();
    } else {
      // Get orders from this month
      filteredOrders = orders.where((order) {
        final orderDate = order.timestamp;
        return orderDate.year == now.year &&
               orderDate.month == now.month;
      }).toList();
    }
    
    final completedSales = filteredOrders.where((order) => order.status == OrderStatus.completed).length;
    final totalSalesRevenue = completedSales * 15000; // Mock calculation
    
    return Card(
      elevation: 2,
      color: AppColors.primaryAccent.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: AppColors.primaryAccent,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Laporan $period',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.primaryAccent.withOpacity(0.7),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Penjualan Selesai',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$completedSales pesanan',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Total Pendapatan',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatCurrency(totalSalesRevenue),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: AppColors.secondarySurface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStatusCard(String title, int count, IconData icon, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Text(
              count.toString(),
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
} 