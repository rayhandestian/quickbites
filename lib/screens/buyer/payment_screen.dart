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
  final String? tenantId;

  const PaymentScreen({
    Key? key,
    required this.menuId,
    required this.quantity,
    this.customNote,
    required this.totalPrice,
    this.tenantId,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String? _selectedPaymentMethod;
  bool _isProcessing = false;
  bool _showPaymentInterface = false;

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
            child: _showPaymentInterface ? _buildPaymentInterface() : _buildPaymentMethodSelection(),
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

  Widget _buildPaymentMethodSelection() {
    return Column(
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
          onPressed: _selectedPaymentMethod == null ? () {} : () {
            setState(() {
              _showPaymentInterface = true;
            });
          },
        ),
      ],
    );
  }

  Widget _buildPaymentInterface() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Back button
        Row(
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  _showPaymentInterface = false;
                });
              },
              icon: const Icon(Icons.arrow_back),
            ),
            const Text(
              'Kembali ke metode pembayaran',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Payment method info
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.secondarySurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                'Pembayaran via $_selectedPaymentMethod',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Total: ${formatCurrency(widget.totalPrice)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryAccent,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Mock payment interface (QR code placeholder)
        Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.qr_code,
                      size: 80,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'QR Code Mock',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _selectedPaymentMethod ?? 'Payment',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Instructions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Cara Pembayaran:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '1. Buka aplikasi ${_selectedPaymentMethod ?? 'payment'}\n'
                '2. Scan QR Code di atas\n'
                '3. Konfirmasi pembayaran\n'
                '4. Tekan "Sudah Bayar" setelah selesai',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
        ),
        
        const Spacer(),
        
        // Payment completion button
        AppButton(
          text: 'Sudah Bayar',
          onPressed: () async {
            await _processPayment();
          },
        ),
        
        const SizedBox(height: 8),
        
        // Cancel button
        TextButton(
          onPressed: () {
            setState(() {
              _showPaymentInterface = false;
            });
          },
          child: const Text(
            'Batal',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ),
      ],
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
      await orderProvider.addOrder(newOrder, tenantId: widget.tenantId);
      
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