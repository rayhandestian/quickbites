class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // 'buyer' or 'seller'
  final String? storeName; // Only for sellers
  final String? fcmToken; // For push notifications

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.storeName,
    this.fcmToken,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'buyer',
      storeName: map['storeName'],
      fcmToken: map['fcmToken'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'storeName': storeName,
      'fcmToken': fcmToken,
    };
  }
} 