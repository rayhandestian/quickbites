import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/menu_model.dart';
import '../../models/order_model.dart';
import '../../providers/menu_provider.dart';
import '../../providers/order_provider.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../widgets/app_button.dart';

class SellerInboxScreen extends StatefulWidget {
  const SellerInboxScreen({Key? key}) : super(key: key);

  @override
  State<SellerInboxScreen> createState() => _SellerInboxScreenState();
}

class _SellerInboxScreenState extends State<SellerInboxScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh orders when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderProvider>(context, listen: false).loadOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final orderProvider = Provider.of<OrderProvider>(context);
    final menuProvider = Provider.of<MenuProvider>(context);
    
    final sellerId = authService.currentUser?.id;
    if (sellerId == null) {
      return const Center(
        child: Text('Silakan login untuk melihat pesanan masuk'),
      );
    }
    
    final List<OrderModel> incomingOrders = orderProvider.getSellerOrders(sellerId);
    
    if (incomingOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada pesanan masuk',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pesanan baru akan muncul di sini',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesanan masuk'),
        automaticallyImplyLeading: false,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: incomingOrders.length,
        itemBuilder: (context, index) {
          final order = incomingOrders[index];
          final menu = menuProvider.getMenuById(order.menuId);
          
          if (menu == null) {
            return const SizedBox.shrink();
          }
          
          return _buildOrderItem(context, order, menu, index);
        },
      ),
    );
  }
  
  Widget _buildOrderItem(BuildContext context, OrderModel order, MenuModel menu, int index) {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final Color cardColor = order.status == 'dibuat' 
        ? AppColors.secondaryAccent.withOpacity(0.2) 
        : Colors.white;
    
    return Card(
      elevation: 0,
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          _showOrderDetailsDialog(context, order, menu);
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
                    'Pesanan ${index + 1}',
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
              
              // Item Details
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                          'Jumlah: ${order.quantity}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (order.customNote != null && order.customNote!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Catatan: ${order.customNote}',
                            style: TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
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
              
              // Order Actions
              Row(
                children: [
                  if (order.status == 'dibuat')
                    Expanded(
                      child: AppButton(
                        text: 'Siap Diambil',
                        onPressed: () async {
                          await orderProvider.updateOrderStatus(order.id, 'siap');
                          _showToast(context, 'Status pesanan diperbarui');
                        },
                      ),
                    )
                  else if (order.status == 'siap')
                    Expanded(
                      child: AppButton(
                        text: 'Menunggu Diambil',
                        onPressed: () {},
                      ),
                    )
                  else 
                    Expanded(
                      child: AppButton(
                        text: 'Pesanan Selesai',
                        onPressed: () {},
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    
    switch (status) {
      case 'dibuat':
        color = Colors.blue;
        label = 'Pesanan Baru';
        break;
      case 'siap':
        color = Colors.green;
        label = 'Siap Diambil';
        break;
      case 'selesai':
        color = Colors.grey;
        label = 'Selesai';
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
  
  void _showOrderDetailsDialog(BuildContext context, OrderModel order, MenuModel menu) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nomor Urutan: ${order.id.substring(0, 2)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Menu Item
            Text(
              menu.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            
            // Quantity and Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Jumlah',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  order.quantity.toString(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            
            // Custom Note
            if (order.customNote != null && order.customNote!.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Catatan:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                order.customNote!,
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600],
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            
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
                  formatCurrency(menu.price * order.quantity),
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          if (order.status == 'dibuat')
            ElevatedButton(
              onPressed: () async {
                final orderProvider = Provider.of<OrderProvider>(context, listen: false);
                await orderProvider.updateOrderStatus(order.id, 'siap');
                if (mounted) {
                  Navigator.pop(context);
                  _showToast(context, 'Status pesanan diperbarui menjadi Siap Diambil');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAccent,
              ),
              child: const Text('Siap Diambil'),
            ),
        ],
      ),
    );
  }
} 