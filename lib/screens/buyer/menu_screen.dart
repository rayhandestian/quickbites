import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/menu_model.dart';
import '../../models/tenant_model.dart';
import '../../providers/menu_provider.dart';
import '../../providers/tenant_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/app_button.dart';
import 'checkout_screen.dart';

class MenuScreen extends StatefulWidget {
  final String? menuId;
  final String? tenantId;
  
  const MenuScreen({Key? key, this.menuId, this.tenantId}) : super(key: key);

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  // Add state variables for quantity and note
  int _quantity = 1;
  final TextEditingController _noteController = TextEditingController();
  
  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
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

  // Method to increment quantity
  void _incrementQuantity(int stock) {
    if (_quantity < stock) {
      setState(() {
        _quantity++;
      });
    }
  }

  // Method to decrement quantity
  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuProvider = Provider.of<MenuProvider>(context);
    final tenantProvider = Provider.of<TenantProvider>(context);
    
    if (widget.menuId != null) {
      // Detail view for a specific menu
      final menu = menuProvider.getMenuById(widget.menuId!);
      
      if (menu == null) {
        return const Center(
          child: Text('Menu tidak ditemukan'),
        );
      }
      
      return _buildMenuDetail(context, menu);
    }
    
    if (widget.tenantId != null) {
      // List view of menus for a specific tenant
      final tenant = tenantProvider.getTenantById(widget.tenantId!);
      final tenantMenus = menuProvider.getMenusByTenant(widget.tenantId!);
      
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
      body: RefreshIndicator(
        onRefresh: () async {
          await Provider.of<MenuProvider>(context, listen: false).loadMenus();
          await Provider.of<TenantProvider>(context, listen: false).loadTenants();
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: allMenus.length,
          itemBuilder: (context, index) {
            final menu = allMenus[index];
            return _buildMenuListItem(context, menu);
          },
        ),
      ),
    );
  }
  
  Widget _buildTenantMenuList(BuildContext context, TenantModel tenant, List<MenuModel> menus) {
    if (menus.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          await Provider.of<MenuProvider>(context, listen: false).loadMenus();
          await Provider.of<TenantProvider>(context, listen: false).loadTenants();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height - 200,
            child: const Center(
              child: Text('Tidak ada menu tersedia untuk tenant ini'),
            ),
          ),
        ),
      );
    }
    
    final foodItems = menus.where((menu) => menu.category == FoodCategories.food).toList();
    final beverageItems = menus.where((menu) => menu.category == FoodCategories.beverage).toList();
    
    return RefreshIndicator(
      onRefresh: () async {
        await Provider.of<MenuProvider>(context, listen: false).loadMenus();
        await Provider.of<TenantProvider>(context, listen: false).loadTenants();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
      ),
    );
  }
  
  Widget _buildMenuDetail(BuildContext context, MenuModel menu) {
    final tenantProvider = Provider.of<TenantProvider>(context);
    final tenant = tenantProvider.getTenantById(menu.tenantId);
    final tenantName = tenant?.name ?? 'Unknown Tenant';
    
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
              // Menu Image
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _isValidImageUrl(menu.imageUrl)
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        menu.imageUrl!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Center(
                      child: Icon(
                        menu.category == FoodCategories.food ? Icons.lunch_dining : Icons.local_drink,
                        size: 64,
                        color: AppColors.primaryAccent,
                      ),
                    ),
              ),
              const SizedBox(height: 24),
              
              // Menu Name and Price
              Text(
                menu.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              
              // Tenant Name (Clickable)
              InkWell(
                onTap: () {
                  if (tenant != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MenuScreen(tenantId: tenant.id),
                      ),
                    );
                  }
                },
                child: Row(
                  children: [
                    Text(
                      tenantName,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.primaryAccent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: AppColors.primaryAccent,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              Text(
                formatCurrency(menu.price),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
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
              
              // Quantity Selector with working buttons
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
                    onPressed: menu.stock > 0 ? () => _decrementQuantity() : null,
                    icon: const Icon(Icons.remove_circle_outline),
                    color: menu.stock > 0 ? AppColors.primaryAccent : Colors.grey,
                  ),
                  SizedBox(
                    width: 40,
                    child: Center(
                      child: Text(
                        '$_quantity',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: menu.stock > 0 ? () => _incrementQuantity(menu.stock) : null,
                    icon: const Icon(Icons.add_circle_outline),
                    color: _quantity < menu.stock ? AppColors.primaryAccent : Colors.grey,
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
                controller: _noteController,
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
                onPressed: menu.stock > 0 ? () {
                  // Navigate to checkout with current quantity and note
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CheckoutScreen(
                        menuId: menu.id,
                        quantity: _quantity,
                        customNote: _noteController.text,
                      ),
                    ),
                  );
                } : () {},
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
              // Menu Image
              Container(
                width: 70,
                height: 70,
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
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            menu.category == FoodCategories.food ? Icons.lunch_dining : Icons.local_drink,
                            size: 30,
                            color: AppColors.primaryAccent,
                          );
                        },
                      ),
                    )
                  : Center(
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