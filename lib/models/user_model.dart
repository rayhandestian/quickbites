class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // 'buyer' or 'seller'
  final String? storeName; // Only for sellers

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.storeName,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'buyer',
      storeName: map['storeName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'storeName': storeName,
    };
  }
} 