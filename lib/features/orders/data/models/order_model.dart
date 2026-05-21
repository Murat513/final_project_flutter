import 'package:flutter/foundation.dart';

import '../../../../core/database/app_database.dart';

@immutable
class OrderItemModel {
  const OrderItemModel({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.title,
    required this.image,
    required this.price,
    required this.quantity,
    required this.category,
  });

  final int id;
  final int orderId;
  final int productId;
  final String title;
  final String image;
  final double price;
  final int quantity;
  final String category;

  double get subtotal => price * quantity;

  factory OrderItemModel.fromTableData(OrderItemsTableData data) {
    return OrderItemModel(
      id: data.id,
      orderId: data.orderId,
      productId: data.productId,
      title: data.title,
      image: data.image,
      price: data.price,
      quantity: data.quantity,
      category: data.category,
    );
  }

  factory OrderItemModel.fromFirestore(Map<String, dynamic> map, int orderId) {
    return OrderItemModel(
      id: 0,
      orderId: orderId,
      productId: map['productId'] as int,
      title: map['title'] as String,
      image: map['image'] as String,
      price: (map['price'] as num).toDouble(),
      quantity: map['quantity'] as int,
      category: map['category'] as String,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'productId': productId,
    'title': title,
    'image': image,
    'price': price,
    'quantity': quantity,
    'category': category,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is OrderItemModel &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;
}

@immutable
class OrderModel {
  const OrderModel({
    required this.id,
    required this.userId,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
    this.firestoreId,
  });

  final int id;
  final String? firestoreId;
  final String userId;
  final double totalAmount;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderItemModel> items;

  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);

  factory OrderModel.fromTableData(
      OrdersTableData order,
      List<OrderItemsTableData> items,
      ) {
    return OrderModel(
      id: order.id,
      firestoreId: order.firestoreId,
      userId: order.userId,
      totalAmount: order.totalAmount,
      status: order.status,
      createdAt: order.createdAt,
      updatedAt: order.updatedAt,
      items: items.map(OrderItemModel.fromTableData).toList(),
    );
  }

  factory OrderModel.fromFirestore(String docId, Map<String, dynamic> map) {
    final rawItems = (map['items'] as List<dynamic>? ?? []);
    return OrderModel(
      id: 0,
      firestoreId: docId,
      userId: map['userId'] as String,
      totalAmount: (map['totalAmount'] as num).toDouble(),
      status: map['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      items: rawItems
          .map((e) => OrderItemModel.fromFirestore(e as Map<String, dynamic>, 0))
          .toList(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'totalAmount': totalAmount,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'items': items.map((i) => i.toFirestore()).toList(),
  };

  OrderModel copyWith({
    int? id,
    String? firestoreId,
    String? userId,
    double? totalAmount,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<OrderItemModel>? items,
  }) {
    return OrderModel(
      id: id ?? this.id,
      firestoreId: firestoreId ?? this.firestoreId,
      userId: userId ?? this.userId,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is OrderModel &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              firestoreId == other.firestoreId;

  @override
  int get hashCode => Object.hash(id, firestoreId);
}