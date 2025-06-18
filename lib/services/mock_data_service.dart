import '../models/user_model.dart';
import '../models/menu_model.dart';
import '../models/order_model.dart';
import '../models/tenant_model.dart';
import '../utils/constants.dart';

// This class provides mock data for testing and development
class MockDataService {
  // Generate mock users
  static List<UserModel> getMockUsers() {
    return [
      UserModel(
        id: 'buyer1',
        name: 'Budi Santoso',
        email: 'budi@example.com',
        role: UserRoles.buyer,
      ),
      UserModel(
        id: 'buyer2',
        name: 'Siti Aminah',
        email: 'siti@example.com',
        role: UserRoles.buyer,
      ),
      UserModel(
        id: 'buyer3',
        name: 'Agus Setiawan',
        email: 'agus@example.com',
        role: UserRoles.buyer,
      ),
      UserModel(
        id: 'seller1',
        name: 'Dewi Catering',
        email: 'dewi@example.com',
        role: UserRoles.seller,
        storeName: 'Warung Dewi',
      ),
      UserModel(
        id: 'seller2',
        name: 'Joko Food',
        email: 'joko@example.com',
        role: UserRoles.seller,
        storeName: 'Joko Healthy Food',
      ),
    ];
  }

  // Generate mock tenants
  static List<TenantModel> getMockTenants() {
    return [
      TenantModel(
        id: 'tenant1',
        name: 'Warung Dewi',
        sellerId: 'seller1',
        description: 'Menyediakan aneka masakan rumahan yang lezat dan sehat',
      ),
      TenantModel(
        id: 'tenant2',
        name: 'Joko Healthy Food',
        sellerId: 'seller2',
        description: 'Makanan sehat untuk gaya hidup aktif',
      ),
    ];
  }

  // Generate mock menus
  static List<MenuModel> getMockMenus() {
    return [
      MenuModel(
        id: 'menu1',
        name: 'Nasi Goreng Special',
        price: 15000,
        stock: 20,
        tenantId: 'tenant1',
        category: FoodCategories.food,
      ),
      MenuModel(
        id: 'menu2',
        name: 'Mie Ayam Bakso',
        price: 18000,
        stock: 15,
        tenantId: 'tenant1',
        category: FoodCategories.food,
      ),
      MenuModel(
        id: 'menu3',
        name: 'Es Teh Manis',
        price: 5000,
        stock: 30,
        tenantId: 'tenant1',
        category: FoodCategories.beverage,
      ),
      MenuModel(
        id: 'menu4',
        name: 'Salad Bowl',
        price: 25000,
        stock: 10,
        tenantId: 'tenant2',
        category: FoodCategories.food,
      ),
      MenuModel(
        id: 'menu5',
        name: 'Smoothie Buah',
        price: 12000,
        stock: 25,
        tenantId: 'tenant2',
        category: FoodCategories.beverage,
      ),
    ];
  }

  // Generate mock orders
  static List<OrderModel> getMockOrders() {
    final now = DateTime.now();
    
    return [
      OrderModel(
        id: 'order1',
        buyerId: 'buyer1',
        menuId: 'menu1',
        quantity: 2,
        status: OrderStatus.created,
        timestamp: now.subtract(const Duration(hours: 1)),
        orderNumber: 1,
      ),
      OrderModel(
        id: 'order2',
        buyerId: 'buyer2',
        menuId: 'menu4',
        quantity: 1,
        customNote: 'Tanpa dressing',
        status: OrderStatus.ready,
        timestamp: now.subtract(const Duration(minutes: 45)),
        orderNumber: 1,
      ),
      OrderModel(
        id: 'order3',
        buyerId: 'buyer3',
        menuId: 'menu2',
        quantity: 3,
        status: OrderStatus.completed,
        timestamp: now.subtract(const Duration(minutes: 30)),
        orderNumber: 2,
      ),
    ];
  }
} 