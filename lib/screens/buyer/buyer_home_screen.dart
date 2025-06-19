import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/menu_model.dart';
import '../../models/tenant_model.dart';
import '../../providers/menu_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/tenant_provider.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import 'menu_screen.dart';
import 'order_tracker_screen.dart';
import 'profile_screen.dart';
import 'order_history_screen.dart';

class BuyerHomeScreen extends StatefulWidget {
  // Add initial tab index parameter
  final int initialTabIndex;
  
  const BuyerHomeScreen({
    Key? key, 
    this.initialTabIndex = 0,
  }) : super(key: key);

  @override
  State<BuyerHomeScreen> createState() => _BuyerHomeScreenState();
}

class _BuyerHomeScreenState extends State<BuyerHomeScreen> {
  late int _currentIndex;
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Semua'; // Default filter
  List<MenuModel> _filteredMenus = [];
  
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
  
  @override
  void initState() {
    super.initState();
    // Initialize current index from widget parameter
    _currentIndex = widget.initialTabIndex;
    // Load data when the screen is initialized
    _loadInitialData();
    
    // Add listener to search controller
    _searchController.addListener(_filterMenus);
  }

  Future<void> _loadInitialData() async {
    final menuProvider = Provider.of<MenuProvider>(context, listen: false);
    final tenantProvider = Provider.of<TenantProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    await Future.wait([
      menuProvider.loadMenus(),
      tenantProvider.loadTenants(),
      orderProvider.loadOrders(),
    ]);
    
    // Initialize filtered menus
    _filterMenus();
  }
  
  void _filterMenus() {
    final menuProvider = Provider.of<MenuProvider>(context, listen: false);
    final allMenus = menuProvider.menus;
    
    setState(() {
      _filteredMenus = allMenus.where((menu) {
        final matchesSearch = _searchController.text.isEmpty ||
            menu.name.toLowerCase().contains(_searchController.text.toLowerCase());
        final matchesCategory = _selectedCategory == 'Semua' ||
            menu.category == _selectedCategory;
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Method to navigate to a specific tab
  void navigateToTab(int index) {
    if (mounted) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuProvider = Provider.of<MenuProvider>(context);
    final tenantProvider = Provider.of<TenantProvider>(context);
    
    // Update filtered menus when menu provider changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_filteredMenus.isEmpty && menuProvider.menus.isNotEmpty) {
        _filterMenus();
      }
    });
    
    final List<Widget> screens = [
      _buildHomeContent(menuProvider, tenantProvider),
      const OrderTrackerScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentIndex == 0 ? 'QuickBites' : 
          _currentIndex == 1 ? 'Pesanan Saya' : 'Profil',
        ),
        automaticallyImplyLeading: false, // Remove back button
        actions: [
          if (_currentIndex == 1) // Only show on Order Tracker screen
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OrderHistoryScreen(),
                  ),
                );
              },
            ),
        ],
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.delivery_dining),
            label: 'Pesanan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Akun',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent(MenuProvider menuProvider, TenantProvider tenantProvider) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari makanan atau minuman...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.secondarySurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            
            // Filter Chips
            Row(
              children: [
                const Text(
                  'Filter: ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Semua'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Makanan'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Minuman'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Food Grid
            const Text(
              'Menu Tersedia',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            
            // Menu Grid
            _buildMenuGrid(_filteredMenus, tenantProvider),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFilterChip(String category) {
    final isSelected = _selectedCategory == category;
    return FilterChip(
      label: Text(category),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedCategory = category;
        });
        _filterMenus();
      },
      backgroundColor: AppColors.secondarySurface,
      selectedColor: AppColors.primaryAccent.withOpacity(0.2),
      checkmarkColor: AppColors.primaryAccent,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primaryAccent : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildMenuGrid(List<MenuModel> menus, TenantProvider tenantProvider) {
    if (menus.isEmpty) {
      return Center(
        child: Column(
          children: [
            Icon(
              Icons.search_off_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty 
                ? 'Tidak ada menu tersedia'
                : 'Menu tidak ditemukan',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: menus.length,
      itemBuilder: (context, index) {
        final menu = menus[index];
        return _buildMenuCard(menu, tenantProvider);
      },
    );
  }

  Widget _buildMenuCard(MenuModel menu, TenantProvider tenantProvider) {
    final tenant = tenantProvider.getTenantById(menu.tenantId);
    final tenantName = tenant?.name ?? 'Unknown Tenant';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MenuScreen(menuId: menu.id),
          ),
        );
      },
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Menu Image
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
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
                              size: 40,
                              color: AppColors.primaryAccent,
                            );
                          },
                        ),
                      )
                    : Center(
                        child: Icon(
                          menu.category == FoodCategories.food ? Icons.lunch_dining : Icons.local_drink,
                          size: 40,
                          color: AppColors.primaryAccent,
                        ),
                      ),
                ),
              ),
              const SizedBox(height: 8),
              // Menu Name and Price
              Expanded(
                flex: 2,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Price
                    Text(
                      formatCurrency(menu.price),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryAccent,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Tenant Name
                    Text(
                      tenantName,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textPrimary.withOpacity(0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 