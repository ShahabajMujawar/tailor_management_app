import 'dart:convert';

/// Business entity representing a tailoring order.
class Order {
  final int? orderId;
  final String receiptNumber;
  final int customerId;
  final String? customerName; // Cached/joined helper field
  final DateTime orderDate;
  final DateTime deliveryDate;
  final String status; // Pending, Cutting, Stitching, Ready, Delivered
  final String? remarks;
  final DateTime createdAt;
  final List<Garment> garments;

  const Order({
    this.orderId,
    required this.receiptNumber,
    required this.customerId,
    this.customerName,
    required this.orderDate,
    required this.deliveryDate,
    required this.status,
    this.remarks,
    required this.createdAt,
    this.garments = const [],
  });

  Order copyWith({
    int? orderId,
    String? receiptNumber,
    int? customerId,
    String? customerName,
    DateTime? orderDate,
    DateTime? deliveryDate,
    String? status,
    String? remarks,
    DateTime? createdAt,
    List<Garment>? garments,
  }) {
    return Order(
      orderId: orderId ?? this.orderId,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      orderDate: orderDate ?? this.orderDate,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
      garments: garments ?? this.garments,
    );
  }
}

/// Business entity representing a garment included in an order.
class Garment {
  final int? garmentId;
  final int? orderId;
  final String garmentType; // Shirt, Pant, Kurta, Pajama
  final Map<String, dynamic> measurements; // Decoded measurement_json
  final Map<String, dynamic> preferences; // Decoded preference_json

  const Garment({
    this.garmentId,
    this.orderId,
    required this.garmentType,
    required this.measurements,
    required this.preferences,
  });

  Garment copyWith({
    int? garmentId,
    int? orderId,
    String? garmentType,
    Map<String, dynamic>? measurements,
    Map<String, dynamic>? preferences,
  }) {
    return Garment(
      garmentId: garmentId ?? this.garmentId,
      orderId: orderId ?? this.orderId,
      garmentType: garmentType ?? this.garmentType,
      measurements: measurements ?? this.measurements,
      preferences: preferences ?? this.preferences,
    );
  }
}
