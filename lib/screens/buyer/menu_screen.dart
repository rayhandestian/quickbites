import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/menu_model.dart';
import '../../providers/menu_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/app_button.dart';

class MenuScreen extends StatelessWidget {
  final String? menuId;
  
  const MenuScreen({Key? key, this.menuId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final menuProvider = Provider.of<MenuProvider>(context);
    
    if (menuId != null) {
      // Detail view for a specific menu
      final menu = menuProvider.getMenuById(menuId!);
      
      if (menu == null) {
        return const Center(
          child: Text('Menu tidak ditemukan'),
        );
      }
      
      return _buildMenuDetail(context, menu);
    }
    
    // List view of all menus
    final allMenus = menuProvider.menus;
    
    return Scaffold(
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: allMenus.length,
        itemBuilder: (context, index) {
          final menu = allMenus[index];
          return _buildMenuListItem(context, menu);
        },
      ),
    );
  }
  
  Widget _buildMenuDetail(BuildContext context, MenuModel menu) {
    return Scaffold(
      appBar: AppBar(
        title: Text(menu.name),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Menu Image (placeholder)
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    menu.category == FoodCategories.food ? Icons.lunch_dining : Icons.local_drink,
                    size: 80,
                    color: AppColors.primaryAccent,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Menu Name
              Text(
                menu.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              
              // Price
              Text(
                formatCurrency(menu.price),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryAccent,
                ),
              ),
              const SizedBox(height: 8),
              
              // Stock
              Text(
                'Stok: ${menu.stock}',
                style: TextStyle(
                  fontSize: 16,
                  color: menu.stock > 0 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              
              // Quantity Selector (stub)
              const Text(
                'Jumlah',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.remove_circle_outline),
                    color: AppColors.primaryAccent,
                  ),
                  const SizedBox(
                    width: 40,
                    child: Center(
                      child: Text(
                        '1',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.add_circle_outline),
                    color: AppColors.primaryAccent,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Custom Note
              const Text(
                'Catatan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Contoh: Tidak pedas, tanpa es, dll.',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.secondarySurface,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              
              // Order Button
              AppButton(
                text: 'Pesan Sekarang',
                onPressed: () {
                  // Navigate to checkout
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fitur masih dalam pengembangan'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildMenuListItem(BuildContext context, MenuModel menu) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MenuScreen(menuId: menu.id)),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Menu Image (placeholder)
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    menu.category == FoodCategories.food ? Icons.lunch_dining : Icons.local_drink,
                    size: 40,
                    color: AppColors.primaryAccent,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      menu.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatCurrency(menu.price),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryAccent,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Stok: ${menu.stock}',
                      style: TextStyle(
                        fontSize: 12,
                        color: menu.stock > 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textPrimary.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 