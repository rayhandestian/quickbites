class MenuModel {
  final String id;
  final String name;
  final int price;
  final int stock;
  final String tenantId;
  final String category; // 'Makanan' or 'Minuman'
  final String? imageUrl; // Added for storing Cloudinary image URL

  MenuModel({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.tenantId,
    required this.category,
    this.imageUrl,
  });

  factory MenuModel.fromMap(Map<String, dynamic> map) {
    return MenuModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      price: map['price'] ?? 0,
      stock: map['stock'] ?? 0,
      tenantId: map['tenantId'] ?? '',
      category: map['category'] ?? 'Makanan',
      imageUrl: map['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'stock': stock,
      'tenantId': tenantId,
      'category': category,
      'imageUrl': imageUrl,
    };
  }

  MenuModel copyWith({
    String? id,
    String? name,
    int? price,
    int? stock,
    String? tenantId,
    String? category,
    String? imageUrl,
  }) {
    return MenuModel(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      tenantId: tenantId ?? this.tenantId,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
} 