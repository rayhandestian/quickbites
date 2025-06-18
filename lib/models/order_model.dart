class OrderModel {
  final String id;
  final String buyerId;
  final String menuId;
  final String? customNote;
  final int quantity;
  final String status; // 'dibuat', 'siap', 'selesai'
  final DateTime timestamp;
  final int? orderNumber; // New field for incremental order number per tenant

  OrderModel({
    required this.id,
    required this.buyerId,
    required this.menuId,
    this.customNote,
    required this.quantity,
    required this.status,
    required this.timestamp,
    this.orderNumber,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id'] ?? '',
      buyerId: map['buyerId'] ?? '',
      menuId: map['menuId'] ?? '',
      customNote: map['customNote'],
      quantity: map['quantity'] ?? 0,
      status: map['status'] ?? 'dibuat',
      timestamp: map['timestamp'] != null 
        ? DateTime.parse(map['timestamp']) 
        : DateTime.now(),
      orderNumber: map['orderNumber'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'buyerId': buyerId,
      'menuId': menuId,
      'customNote': customNote,
      'quantity': quantity,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
      'orderNumber': orderNumber,
    };
  }

  OrderModel copyWith({
    String? id,
    String? buyerId,
    String? menuId,
    String? customNote,
    int? quantity,
    String? status,
    DateTime? timestamp,
    int? orderNumber,
  }) {
    return OrderModel(
      id: id ?? this.id,
      buyerId: buyerId ?? this.buyerId,
      menuId: menuId ?? this.menuId,
      customNote: customNote ?? this.customNote,
      quantity: quantity ?? this.quantity,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      orderNumber: orderNumber ?? this.orderNumber,
    );
  }
} 