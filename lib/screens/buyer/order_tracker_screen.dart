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

class OrderTrackerScreen extends StatefulWidget {
  const OrderTrackerScreen({Key? key}) : super(key: key);

  @override
  State<OrderTrackerScreen> createState() => _OrderTrackerScreenState();
}

class _OrderTrackerScreenState extends State<OrderTrackerScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh orders when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderProvider>(context, listen: false).loadOrders();
      Provider.of<TenantProvider>(context, listen: false).loadTenants();
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final menuProvider = Provider.of<MenuProvider>(context);
    
    final List<OrderModel> userOrders = orderProvider.getUserOrders();
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: userOrders.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Belum ada pesanan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pesanan Anda akan muncul di sini',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: userOrders.length,
            itemBuilder: (context, index) {
              final order = userOrders[index];
              final menu = menuProvider.getMenuById(order.menuId);
              
              if (menu == null) {
                return const SizedBox.shrink();
              }
              
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  onTap: () {
                    _showOrderDetailSheet(context, order, menu);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Order ID and Status
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
                            _buildStatusChip(order.status),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Menu and Quantity
                        Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
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
                                    ),
                                  )
                                : Icon(
                                    menu.category == FoodCategories.food ? Icons.lunch_dining : Icons.local_drink,
                                    size: 30,
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
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Jumlah: ${order.quantity}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
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
                                color: AppColors.primaryAccent,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        
                        // Order Date
                        Text(
                          'Dipesan pada: ${_formatDate(order.timestamp)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
    );
  }
  
  // Helper method to format date
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

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    
    switch (status) {
      case 'dikirim':
        color = Colors.orange;
        label = 'Pesanan Diterima';
        break;
      case 'dibuat':
        color = Colors.blue;
        label = 'Pesanan Dibuat';
        break;
      case 'siap':
        color = Colors.green;
        label = 'Siap Diambil';
        break;
      case 'selesai':
        color = Colors.grey;
        label = 'Histori';
        break;
      default:
        color = Colors.orange;
        label = 'Dalam Proses';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
  
  void _showOrderDetailSheet(BuildContext context, OrderModel order, MenuModel menu) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _OrderDetailSheet(order: order, menu: menu),
    );
  }
}

class _OrderDetailSheet extends StatefulWidget {
  final OrderModel order;
  final MenuModel menu;
  
  const _OrderDetailSheet({
    Key? key,
    required this.order,
    required this.menu,
  }) : super(key: key);

  @override
  State<_OrderDetailSheet> createState() => _OrderDetailSheetState();
}

class _OrderDetailSheetState extends State<_OrderDetailSheet> {
  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final int totalPrice = widget.menu.price * widget.order.quantity;
    
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Title
          const Center(
            child: Text(
              'Tracker Pesanan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          
          Center(
            child: Text(
              'Lacak makananmu disini!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Order Number
          Center(
            child: Text(
              'Nomor Urutan: ${widget.order.orderNumber ?? 0}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Consumer<TenantProvider>(
              builder: (context, tenantProvider, _) {
                final tenant = tenantProvider.getTenantById(widget.menu.tenantId);
                return Text(
                  tenant?.name ?? 'Kantin ${widget.menu.tenantId.substring(0, 3)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          
          // Status Tracker
          _buildStatusTracker(widget.order.status),
          const SizedBox(height: 36),
          
          // Detail Pesanan
          const Text(
            'Detail pesanan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.menu.name,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                formatCurrency(widget.menu.price),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          if (widget.order.customNote != null && widget.order.customNote!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.order.customNote!,
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[600],
                  ),
                ),
                const Text(
                  'Gratis',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          
          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Harga',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                formatCurrency(totalPrice),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                'Catatan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.order.customNote != null && widget.order.customNote!.isNotEmpty
                      ? widget.order.customNote!
                      : 'Tidak ada catatan dari pembeli',
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Action Button
          if (widget.order.status == 'siap')
            AppButton(
              text: 'Pesanan sudah diambil',
              onPressed: () async {
                // Update order status to 'selesai'
                await orderProvider.updateOrderStatus(
                  widget.order.id,
                  'selesai',
                );
                if (mounted) {
                  Navigator.pop(context);
                }
              },
            )
          else if (widget.order.status == 'selesai')
            const Center(
              child: Text(
                'Pesanan telah selesai',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.green,
                ),
              ),
            )
          else
            const Center(
              child: Text(
                'Menunggu pesanan siap diambil...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryAccent,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusTracker(String status) {
    final bool orderSent = status == 'dikirim';
    final bool orderCreated = status == 'dibuat' || status == 'siap' || status == 'selesai';
    final bool orderReady = status == 'siap' || status == 'selesai';
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // First Status - Order Sent
        Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.shopping_cart,
                color: Colors.white,
                size: 25,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Dikirim',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        
        // Connector Line
        Container(
          width: 40,
          height: 2,
          color: orderCreated ? Colors.black : Colors.grey[300],
        ),
        
        // Second Status - Order Created
        Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: orderCreated ? Colors.black : Colors.grey[300],
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.restaurant,
                color: orderCreated ? Colors.white : Colors.grey[400],
                size: 25,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Dibuat',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: orderCreated ? AppColors.textPrimary : Colors.grey[400],
              ),
            ),
          ],
        ),
        
        // Connector Line
        Container(
          width: 40,
          height: 2,
          color: orderReady ? Colors.black : Colors.grey[300],
        ),
        
        // Third Status - Ready for pickup
        Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: orderReady ? Colors.black : Colors.grey[300],
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.room_service,
                color: orderReady ? Colors.white : Colors.grey[400],
                size: 25,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Siap Diambil',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: orderReady ? AppColors.textPrimary : Colors.grey[400],
              ),
            ),
          ],
        ),
      ],
    );
  }
} 