class TenantModel {
  final String id;
  final String name;
  final String sellerId;
  final String? description;
  final String? imageUrl;

  TenantModel({
    required this.id,
    required this.name,
    required this.sellerId,
    this.description,
    this.imageUrl,
  });

  factory TenantModel.fromMap(Map<String, dynamic> map) {
    return TenantModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      sellerId: map['sellerId'] ?? '',
      description: map['description'],
      imageUrl: map['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sellerId': sellerId,
      'description': description,
      'imageUrl': imageUrl,
    };
  }
} 