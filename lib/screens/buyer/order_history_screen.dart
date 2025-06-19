import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/menu_model.dart';
import '../../models/order_model.dart';
import '../../providers/menu_provider.dart';
import '../../providers/order_provider.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final menuProvider = Provider.of<MenuProvider>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    final List<OrderModel> userOrders = orderProvider.getUserOrders(authService.currentUser?.id);

    // Filter for completed or rejected orders
    final List<OrderModel> historyOrders = userOrders.where((order) {
      return order.status == OrderStatus.completed || order.status == OrderStatus.rejected;
    }).toList();
    
    // Sort by most recent first
    historyOrders.sort((a, b) => b.timestamp.compareTo(a.timestamp));


    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pesanan'),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      backgroundColor: Colors.white,
      body: historyOrders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_toggle_off,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada riwayat pesanan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: historyOrders.length,
              itemBuilder: (context, index) {
                final order = historyOrders[index];
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
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                             Text(
                              'Order #${order.id.substring(0, 6)}', // Display a shortened ID
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
                        Row(
                          children: [
                             Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: AppColors.primaryAccent.withOpacity(0.1),
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
                                    menu.category == FoodCategories.food
                                        ? Icons.lunch_dining
                                        : Icons.local_drink,
                                    size: 30,
                                    color: AppColors.primaryAccent.withOpacity(0.7),
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
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        if (order.status == OrderStatus.rejected && order.rejectionReason != null && order.rejectionReason!.isNotEmpty)
                          Container(
                             width: double.infinity,
                            margin: const EdgeInsets.only(top: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.withOpacity(0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Alasan Ditolak:',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                      fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  order.rejectionReason!,
                                  style: TextStyle(
                                      color: Colors.red.withOpacity(0.9),
                                      fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  bool _isValidImageUrl(String? url) {
    return url != null && url.isNotEmpty && Uri.tryParse(url)?.isAbsolute == true;
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    String chipText;

    switch (status) {
      case OrderStatus.completed:
        chipColor = Colors.green;
        chipText = 'Selesai';
        break;
      case OrderStatus.rejected:
        chipColor = Colors.red;
        chipText = 'Ditolak';
        break;
      default:
        chipColor = Colors.grey;
        chipText = 'Tidak Diketahui';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        chipText,
        style: TextStyle(
          color: chipColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
} 