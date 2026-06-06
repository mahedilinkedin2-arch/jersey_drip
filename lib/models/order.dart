import 'package:cloud_firestore/cloud_firestore.dart';

import 'cart_item.dart';

class OrderItem {
  const OrderItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.imagePath,
    required this.quantity,
    required this.totalPrice,
  });

  final String productId;
  final String name;
  final int price;
  final String imagePath;
  final int quantity;
  final int totalPrice;

  factory OrderItem.fromCartItem(CartItem item) {
    return OrderItem(
      productId: item.productId,
      name: item.name,
      price: item.price,
      imagePath: item.imagePath,
      quantity: item.quantity,
      totalPrice: item.totalPrice,
    );
  }

  factory OrderItem.fromMap(Map<String, dynamic> data) {
    final price = _readInt(data['price']);
    final quantity = _readInt(data['quantity'], fallback: 1);

    return OrderItem(
      productId: _readString(data['productId']),
      name: _readString(data['name'], fallback: 'Order item'),
      price: price,
      imagePath: _readString(data['imagePath']),
      quantity: quantity,
      totalPrice: _readInt(data['totalPrice'], fallback: price * quantity),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'imagePath': imagePath,
      'quantity': quantity,
      'totalPrice': totalPrice,
    };
  }
}

class AppOrder {
  const AppOrder({
    required this.orderId,
    required this.userId,
    required this.items,
    required this.totalPrice,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.status,
    required this.createdAt,
    required this.transactionId,
  });

  final String orderId;
  final String userId;
  final List<OrderItem> items;
  final int totalPrice;
  final String paymentMethod;
  final String paymentStatus;
  final String status;
  final DateTime createdAt;
  final String transactionId;

  factory AppOrder.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final rawItems = data['items'];

    return AppOrder(
      orderId: _readString(data['orderId'], fallback: document.id),
      userId: _readString(data['userId']),
      items: rawItems is Iterable
          ? rawItems
                .whereType<Map>()
                .map((item) => OrderItem.fromMap(item.cast<String, dynamic>()))
                .toList(growable: false)
          : const [],
      totalPrice: _readInt(data['totalPrice']),
      paymentMethod: _readString(data['paymentMethod']),
      paymentStatus: _readString(data['paymentStatus'], fallback: 'paid'),
      status: _readString(data['status'], fallback: 'processing'),
      createdAt: _readDateTime(data['createdAt']),
      transactionId: _readString(data['transactionId']),
    );
  }
}

String _readString(Object? value, {String fallback = ''}) {
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }
  return fallback;
}

int _readInt(Object? value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return fallback;
}

DateTime _readDateTime(Object? value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  return DateTime.fromMillisecondsSinceEpoch(0);
}
