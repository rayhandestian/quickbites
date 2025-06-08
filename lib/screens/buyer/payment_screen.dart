import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../widgets/app_button.dart';
import 'buyer_home_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String menuId;
  final int quantity;
  final String? customNote;
  final int totalPrice;

  const PaymentScreen({
    Key? key,
    required this.menuId,
    required this.quantity,
    this.customNote,
    required this.totalPrice,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String? _selectedPaymentMethod;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembayaran'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pilih metode pembayaran yang anda inginkan!',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                
                // QR Code section
                const Text(
                  'QR CODE',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                _buildPaymentOption('QRIS'),
                
                const SizedBox(height: 24),
                // E-Wallet section
                const Text(
                  'E-Wallet',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                _buildPaymentOption('OVO'),
                const SizedBox(height: 8),
                _buildPaymentOption('JAGO'),
                const SizedBox(height: 8),
                _buildPaymentOption('DANA'),
                const SizedBox(height: 8),
                _buildPaymentOption('Shopee Pay'),
                
                const Spacer(),
                AppButton(
                  text: 'Bayar',
                  onPressed: _selectedPaymentMethod == null ? () {} : () async {
                    await _processPayment();
                  },
                ),
              ],
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String method) {
    final bool isSelected = _selectedPaymentMethod == method;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = method;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryAccent.withOpacity(0.1) : AppColors.secondarySurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primaryAccent : Colors.transparent,
            width: isSelected ? 2 : 0,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Icon(Icons.payment, color: Colors.grey),
            ),
            const SizedBox(width: 16),
            Text(
              method,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processPayment() async {
    if (_selectedPaymentMethod == null) return;
    
    setState(() {
      _isProcessing = true;
    });
    
    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      
      final userId = authService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      // Create new order
      final OrderModel newOrder = OrderModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        buyerId: userId,
        menuId: widget.menuId,
        quantity: widget.quantity,
        customNote: widget.customNote,
        status: OrderStatus.sent,
        timestamp: DateTime.now(),
      );
      
      // Save order to Firestore
      await orderProvider.addOrder(newOrder);
      
      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 2));
      
      // Navigate to BuyerHomeScreen with orders tab selected
      if (mounted) {
        // Clear the entire navigation stack and go to BuyerHomeScreen with orders tab
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const BuyerHomeScreen(initialTabIndex: 1),
          ),
          (route) => false, // Remove all previous routes
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memproses pembayaran: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
} 