import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/menu_model.dart';
import '../../models/tenant_model.dart';
import '../../providers/menu_provider.dart';
import '../../providers/tenant_provider.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final menuProvider = Provider.of<MenuProvider>(context);
    final tenantProvider = Provider.of<TenantProvider>(context);
    
    if (authService.currentUser == null) {
      return const Center(
        child: Text('Silakan login untuk mengelola inventori'),
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
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add New Menu Button
            AppButton(
              text: 'Tambah Menu Baru',
              onPressed: () {
                _showAddMenuDialog(context, tenant);
              },
              icon: Icons.add,
            ),
            const SizedBox(height: 24),
            
            // Menu List
            const Text(
              'Daftar Menu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            
            if (menuItems.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text('Belum ada menu'),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  final menu = menuItems[index];
                  return _buildMenuCard(context, menu);
                },
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMenuCard(BuildContext context, MenuModel menu) {
    final menuProvider = Provider.of<MenuProvider>(context, listen: false);
    
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Menu Image (placeholder)
            Container(
              height: 70,
              width: 70,
              decoration: BoxDecoration(
                color: AppColors.primaryAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                  menu.category == FoodCategories.food ? Icons.lunch_dining : Icons.local_drink,
                  size: 35,
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
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: menu.category == FoodCategories.food 
                              ? Colors.orange.withOpacity(0.2) 
                              : Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          menu.category,
                          style: TextStyle(
                            fontSize: 12,
                            color: menu.category == FoodCategories.food 
                                ? Colors.orange 
                                : Colors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: menu.stock > 0 ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Stok: ${menu.stock}',
                          style: TextStyle(
                            fontSize: 12,
                            color: menu.stock > 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.primaryAccent),
                  onPressed: () {
                    _showEditMenuDialog(context, menu);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    _showDeleteConfirmation(context, menu);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  void _showAddMenuDialog(BuildContext context, TenantModel tenant) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();
    String selectedCategory = FoodCategories.food;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Tambah Menu Baru'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  label: 'Nama Menu',
                  hintText: 'Masukkan nama menu',
                  controller: nameController,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Harga',
                  hintText: 'Masukkan harga',
                  controller: priceController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Stok',
                  hintText: 'Masukkan jumlah stok',
                  controller: stockController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kategori',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Makanan'),
                            value: FoodCategories.food,
                            groupValue: selectedCategory,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  selectedCategory = value;
                                });
                              }
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Minuman'),
                            value: FoodCategories.beverage,
                            groupValue: selectedCategory,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  selectedCategory = value;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final menuProvider = Provider.of<MenuProvider>(context, listen: false);
                
                final name = nameController.text.trim();
                final priceText = priceController.text.trim();
                final stockText = stockController.text.trim();
                
                if (name.isEmpty || priceText.isEmpty || stockText.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Semua field harus diisi')),
                  );
                  return;
                }
                
                final price = int.tryParse(priceText) ?? 0;
                final stock = int.tryParse(stockText) ?? 0;
                
                if (price <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Harga harus lebih dari 0')),
                  );
                  return;
                }
                
                // Create new menu
                final newMenu = MenuModel(
                  id: 'menu_${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  price: price,
                  stock: stock,
                  tenantId: tenant.id,
                  category: selectedCategory,
                );
                
                menuProvider.addMenu(newMenu);
                Navigator.pop(context);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showEditMenuDialog(BuildContext context, MenuModel menu) {
    final nameController = TextEditingController(text: menu.name);
    final priceController = TextEditingController(text: menu.price.toString());
    final stockController = TextEditingController(text: menu.stock.toString());
    String selectedCategory = menu.category;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Menu'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  label: 'Nama Menu',
                  hintText: 'Masukkan nama menu',
                  controller: nameController,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Harga',
                  hintText: 'Masukkan harga',
                  controller: priceController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Stok',
                  hintText: 'Masukkan jumlah stok',
                  controller: stockController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kategori',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Makanan'),
                            value: FoodCategories.food,
                            groupValue: selectedCategory,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  selectedCategory = value;
                                });
                              }
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Minuman'),
                            value: FoodCategories.beverage,
                            groupValue: selectedCategory,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  selectedCategory = value;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final menuProvider = Provider.of<MenuProvider>(context, listen: false);
                
                final name = nameController.text.trim();
                final priceText = priceController.text.trim();
                final stockText = stockController.text.trim();
                
                if (name.isEmpty || priceText.isEmpty || stockText.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Semua field harus diisi')),
                  );
                  return;
                }
                
                final price = int.tryParse(priceText) ?? 0;
                final stock = int.tryParse(stockText) ?? 0;
                
                if (price <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Harga harus lebih dari 0')),
                  );
                  return;
                }
                
                // Update menu
                final updatedMenu = menu.copyWith(
                  name: name,
                  price: price,
                  stock: stock,
                  category: selectedCategory,
                );
                
                menuProvider.updateMenu(updatedMenu);
                Navigator.pop(context);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showDeleteConfirmation(BuildContext context, MenuModel menu) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Menu'),
        content: Text('Apakah Anda yakin ingin menghapus menu "${menu.name}"?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final menuProvider = Provider.of<MenuProvider>(context, listen: false);
              menuProvider.deleteMenu(menu.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
} 