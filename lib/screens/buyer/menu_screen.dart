import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/menu_model.dart';
import '../../models/tenant_model.dart';
import '../../providers/menu_provider.dart';
import '../../providers/tenant_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/app_button.dart';

class MenuScreen extends StatelessWidget {
  final String? menuId;
  final String? tenantId;
  
  const MenuScreen({Key? key, this.menuId, this.tenantId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final menuProvider = Provider.of<MenuProvider>(context);
    final tenantProvider = Provider.of<TenantProvider>(context);
    
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
    
    if (tenantId != null) {
      // List view of menus for a specific tenant
      final tenant = tenantProvider.getTenantById(tenantId!);
      final tenantMenus = menuProvider.getMenusByTenant(tenantId!);
      
      if (tenant == null) {
        return const Center(
          child: Text('Tenant tidak ditemukan'),
        );
      }
      
      return Scaffold(
        appBar: AppBar(
          title: Text(tenant.name),
        ),
        body: _buildTenantMenuList(context, tenant, tenantMenus),
      );
    }
    
    // List view of all menus (fallback)
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
  
  Widget _buildTenantMenuList(BuildContext context, TenantModel tenant, List<MenuModel> menus) {
    if (menus.isEmpty) {
      return const Center(
        child: Text('Tidak ada menu tersedia untuk tenant ini'),
      );
    }
    
    final foodItems = menus.where((menu) => menu.category == FoodCategories.food).toList();
    final beverageItems = menus.where((menu) => menu.category == FoodCategories.beverage).toList();
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tenant Description
            if (tenant.description != null && tenant.description!.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.secondarySurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tentang',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tenant.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 24),
            
            // Food Category
            if (foodItems.isNotEmpty) ...[
              const Text(
                'Makanan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: foodItems.length,
                itemBuilder: (context, index) {
                  return _buildMenuListItem(context, foodItems[index]);
                },
              ),
              const SizedBox(height: 24),
            ],
            
            // Beverage Category
            if (beverageItems.isNotEmpty) ...[
              const Text(
                'Minuman',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: beverageItems.length,
                itemBuilder: (context, index) {
                  return _buildMenuListItem(context, beverageItems[index]);
                },
              ),
            ],
          ],
        ),
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
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Menu Image (placeholder)
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
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
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.primaryAccent,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 