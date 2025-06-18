class OrderModel {
  final String id;
  final String buyerId;
  final String menuId;
  final String? customNote;
  final int quantity;
  final String status; // 'dikirim', 'dibuat', 'siap', 'selesai', 'ditolak'
  final DateTime timestamp;
  final int? orderNumber; // New field for incremental order number per tenant
  final String? rejectionReason; // New field for rejection reason
  final int? estimatedMinutes; // New field for estimated completion time in minutes
  final DateTime? estimatedCompletionTime; // Calculated field for estimated completion

  OrderModel({
    required this.id,
    required this.buyerId,
    required this.menuId,
    this.customNote,
    required this.quantity,
    required this.status,
    required this.timestamp,
    this.orderNumber,
    this.rejectionReason,
    this.estimatedMinutes,
    this.estimatedCompletionTime,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id'] ?? '',
      buyerId: map['buyerId'] ?? '',
      menuId: map['menuId'] ?? '',
      customNote: map['customNote'],
      quantity: map['quantity'] ?? 0,
      status: map['status'] ?? 'dikirim',
      timestamp: map['timestamp'] != null 
        ? DateTime.parse(map['timestamp']) 
        : DateTime.now(),
      orderNumber: map['orderNumber'],
      rejectionReason: map['rejectionReason'],
      estimatedMinutes: map['estimatedMinutes'],
      estimatedCompletionTime: map['estimatedCompletionTime'] != null
        ? DateTime.parse(map['estimatedCompletionTime'])
        : null,
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
      'rejectionReason': rejectionReason,
      'estimatedMinutes': estimatedMinutes,
      'estimatedCompletionTime': estimatedCompletionTime?.toIso8601String(),
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
    String? rejectionReason,
    int? estimatedMinutes,
    DateTime? estimatedCompletionTime,
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
      rejectionReason: rejectionReason ?? this.rejectionReason,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      estimatedCompletionTime: estimatedCompletionTime ?? this.estimatedCompletionTime,
    );
  }
} 