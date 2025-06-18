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
    _tabController = TabController(length: 5, vsync: this);
    
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
    final rejectedOrders = allOrders.where((order) => order.status == OrderStatus.rejected).toList();
    
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
          isScrollable: true,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Dipesan'),
            Tab(text: 'Diproses'),
            Tab(text: 'Siap'),
            Tab(text: 'Histori'),
            Tab(text: 'Ditolak'),
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
      case OrderStatus.rejected:
        return Icons.cancel;
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
        return 'Dipesan';
      case OrderStatus.created:
        return 'Pesanan Diterima';
      case OrderStatus.ready:
        return 'Siap Diambil';
      case OrderStatus.completed:
        return 'Histori';
      case OrderStatus.rejected:
        return 'Ditolak';
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
      case OrderStatus.rejected:
        return Colors.red;
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
      return Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  _showRejectOrderDialog(context, order.id);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Tolak',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppButton(
              text: 'Terima',
              onPressed: () {
                _showAcceptOrderDialog(context, order.id, menu, menuProvider);
              },
            ),
          ),
        ],
      );
    } else if (currentStatus == OrderStatus.created) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (order.estimatedCompletionTime != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Estimasi selesai: ${_formatTime(order.estimatedCompletionTime!)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue,
                ),
              ),
            ),
          const SizedBox(height: 8),
          AppButton(
            text: 'Siap Diambil',
            onPressed: () async {
              await orderProvider.updateOrderStatus(order.id, OrderStatus.ready);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pesanan siap diambil')),
              );
            },
          ),
        ],
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
    } else if (currentStatus == OrderStatus.rejected) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pesanan ditolak',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            if (order.rejectionReason != null)
              Text(
                'Alasan: ${order.rejectionReason}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red.withOpacity(0.8),
                ),
              ),
          ],
        ),
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

  // Format time to show hours and minutes
  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Show reject order dialog
  void _showRejectOrderDialog(BuildContext context, String orderId) {
    final List<String> rejectionReasons = [
      'Stock rupanya habis',
      'Akan tutup',
      'Terlalu sibuk saat ini',
      'Bahan habis',
      'Lainnya (Tulis sendiri)',
    ];
    
    String? selectedReason;
    final TextEditingController customReasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Tolak Pesanan'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pilih alasan penolakan:'),
                  const SizedBox(height: 16),
                  ...rejectionReasons.map((reason) => RadioListTile<String>(
                    title: Text(reason),
                    value: reason,
                    groupValue: selectedReason,
                    onChanged: (value) {
                      setState(() {
                        selectedReason = value;
                      });
                    },
                  )),
                  if (selectedReason == 'Lainnya (Tulis sendiri)')
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextField(
                        controller: customReasonController,
                        decoration: const InputDecoration(
                          hintText: 'Tulis alasan Anda...',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: selectedReason == null ? null : () async {
                    String finalReason = selectedReason == 'Lainnya (Tulis sendiri)'
                        ? customReasonController.text.trim()
                        : selectedReason!;
                    
                    if (finalReason.isNotEmpty) {
                      Navigator.of(context).pop();
                      await Provider.of<OrderProvider>(context, listen: false)
                          .rejectOrder(orderId, finalReason);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Pesanan berhasil ditolak')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Tolak Pesanan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Show accept order dialog
  void _showAcceptOrderDialog(BuildContext context, String orderId, MenuModel menu, MenuProvider menuProvider) {
    int estimatedMinutes = 5; // Default 5 minutes
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Terima Pesanan'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Estimasi waktu selesai (menit):'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      IconButton(
                        onPressed: estimatedMinutes > 1 ? () {
                          setState(() {
                            estimatedMinutes--;
                          });
                        } : null,
                        icon: const Icon(Icons.remove),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$estimatedMinutes menit',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            estimatedMinutes++;
                          });
                        },
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Perkiraan selesai: ${_formatTime(DateTime.now().add(Duration(minutes: estimatedMinutes)))}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    
                    // Update stock first
                    await menuProvider.updateStock(menu.id, menu.stock - 1);
                    
                    // Then accept order with estimation
                    await Provider.of<OrderProvider>(context, listen: false)
                        .acceptOrder(orderId, estimatedMinutes: estimatedMinutes);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Pesanan diterima (estimasi $estimatedMinutes menit)')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Terima Pesanan'),
                ),
              ],
            );
          },
        );
      },
    );
  }
} 