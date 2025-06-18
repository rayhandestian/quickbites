import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/menu_model.dart';
import '../../providers/menu_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/app_button.dart';
import 'payment_screen.dart';

class CheckoutScreen extends StatelessWidget {
  final String menuId;
  final int quantity;
  final String? customNote;

  const CheckoutScreen({
    Key? key,
    required this.menuId,
    required this.quantity,
    this.customNote,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final menuProvider = Provider.of<MenuProvider>(context);

    final MenuModel? menu = menuProvider.getMenuById(menuId);

    if (menu == null) {
      return const Scaffold(
        body: Center(
          child: Text('Menu tidak ditemukan'),
        ),
      );
    }

    final int totalPrice = menu.price * quantity;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ringkasan Pesanan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildOrderSummaryCard(menu, quantity, customNote, totalPrice),
            const Spacer(),
            AppButton(
              text: 'Lanjutkan ke Pembayaran',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentScreen(
                      menuId: menuId,
                      quantity: quantity,
                      customNote: customNote,
                      totalPrice: totalPrice,
                      tenantId: menu.tenantId,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummaryCard(
    MenuModel menu,
    int quantity,
    String? customNote,
    int totalPrice,
  ) {
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
            // Menu name and quantity
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    menu.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  'x$quantity',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Price per item
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Harga satuan',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  formatCurrency(menu.price),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Custom note if any
            if (customNote != null && customNote.isNotEmpty) ...[
              const Divider(),
              const Text(
                'Catatan:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                customNote,
                style: const TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
            ],

            const Divider(),
            // Total price
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
          ],
        ),
      ),
    );
  }
} 