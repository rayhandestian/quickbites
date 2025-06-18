import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/menu_model.dart';
import '../../models/order_model.dart';
import '../../providers/menu_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/tenant_provider.dart';

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
      body: Column(
        children: [
          // Debug info - remove this in production
          if (userOrders.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: Colors.grey[100],
              child: Text(
                'Debug: ${userOrders.length} orders loaded. Rejected orders: ${userOrders.where((o) => o.status == OrderStatus.rejected).length}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          
          Expanded(
            child: userOrders.isEmpty
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
                        
                        // Estimated completion time or rejection reason
                        if (order.status == OrderStatus.created && order.estimatedCompletionTime != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Estimasi selesai: ${_formatTime(order.estimatedCompletionTime!)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        if (order.status == OrderStatus.rejected)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.cancel,
                                      size: 18,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Pesanan ditolak penjual',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                                if (order.rejectionReason != null && order.rejectionReason!.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    'Alasan: ${order.rejectionReason}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.red.withOpacity(0.8),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        
                        const SizedBox(height: 8),
                        const Divider(),
                        const SizedBox(height: 8),
                        
                        // Order Date and Delete button (if rejected)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Dipesan pada: ${_formatDate(order.timestamp)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            if (order.status == OrderStatus.rejected)
                              TextButton.icon(
                                onPressed: () {
                                  _showDeleteOrderConfirmation(context, order.id);
                                },
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 16,
                                  color: Colors.red,
                                ),
                                label: const Text(
                                  'Hapus',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
            ),
          ],
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

  // Helper method to format time
  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Show delete order confirmation dialog
  void _showDeleteOrderConfirmation(BuildContext context, String orderId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus Pesanan'),
          content: const Text('Apakah Anda yakin ingin menghapus pesanan ini?'),
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
                await Provider.of<OrderProvider>(context, listen: false)
                    .deleteOrder(orderId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pesanan berhasil dihapus')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
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
      case OrderStatus.sent:
        color = Colors.orange;
        label = 'Dipesan';
        break;
      case OrderStatus.created:
        color = Colors.blue;
        label = 'Pesanan Dibuat';
        break;
      case OrderStatus.ready:
        color = Colors.green;
        label = 'Siap Diambil';
        break;
      case OrderStatus.completed:
        color = Colors.grey;
        label = 'Histori';
        break;
      case OrderStatus.rejected:
        color = Colors.red;
        label = 'Ditolak';
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
  // Helper method to format time
  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

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
          
          // Estimation time display (if order is accepted)
          if (widget.order.status == OrderStatus.created && widget.order.estimatedCompletionTime != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 20,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Estimasi selesai: ${_formatTime(widget.order.estimatedCompletionTime!)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),

          // Rejection info (if order is rejected)
          if (widget.order.status == OrderStatus.rejected)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.cancel,
                        size: 24,
                        color: Colors.red,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Pesanan ditolak penjual',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (widget.order.rejectionReason != null && widget.order.rejectionReason!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.2)),
                      ),
                      child: Text(
                        'Alasan: ${widget.order.rejectionReason}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    Text(
                      'Alasan penolakan tidak diberikan',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red.withOpacity(0.7),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),

          if (widget.order.status == OrderStatus.rejected)
            const SizedBox(height: 16),

          // Action Button
          if (widget.order.status == OrderStatus.ready)
            AppButton(
              text: 'Pesanan sudah diambil',
              onPressed: () async {
                // Update order status to 'selesai'
                await orderProvider.updateOrderStatus(
                  widget.order.id,
                  OrderStatus.completed,
                );
                if (mounted) {
                  Navigator.pop(context);
                }
              },
            )
          else if (widget.order.status == OrderStatus.completed)
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
          else if (widget.order.status == OrderStatus.rejected)
            AppButton(
              text: 'Hapus Pesanan',
              onPressed: () async {
                Navigator.pop(context); // Close the bottom sheet first
                await orderProvider.deleteOrder(widget.order.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pesanan berhasil dihapus')),
                );
              },
            )
          else if (widget.order.status == OrderStatus.created)
            const Center(
              child: Text(
                'Pesanan sedang diproses...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryAccent,
                ),
              ),
            )
          else
            const Center(
              child: Text(
                'Menunggu penjual menerima pesanan...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.orange,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusTracker(String status) {
    // Handle rejected orders differently
    if (status == OrderStatus.rejected) {
      return Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: const Icon(
              Icons.cancel,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Pesanan Ditolak',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        ],
      );
    }

    final bool orderSent = status == OrderStatus.sent;
    final bool orderCreated = status == OrderStatus.created || status == OrderStatus.ready || status == OrderStatus.completed;
    final bool orderReady = status == OrderStatus.ready || status == OrderStatus.completed;
    
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
              'Dipesan',
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