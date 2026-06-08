import 'package:cloud_firestore/cloud_firestore.dart';

class CartItem {
  const CartItem({
    required this.id,
    required this.productId,
    required this.size,
    required this.name,
    required this.price,
    required this.imagePath,
    required this.quantity,
    required this.totalPrice,
  });

  final String id;
  final String productId;
  final String size;
  final String name;
  final int price;
  final String imagePath;
  final int quantity;
  final int totalPrice;

  factory CartItem.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final productId = _readString(data['productId'], fallback: document.id);
    final price = _readInt(data['price']);
    final quantity = _readInt(data['quantity'], fallback: 1);

    return CartItem(
      id: document.id,
      productId: productId,
      size: _readString(data['size']),
      name: _readString(data['name'], fallback: 'Cart item'),
      price: price,
      imagePath: _readString(data['imagePath']),
      quantity: quantity,
      totalPrice: _readInt(data['totalPrice'], fallback: price * quantity),
    );
  }

  CartItem copyWith({
    int? price,
    int? quantity,
    int? totalPrice,
    String? size,
  }) {
    return CartItem(
      id: id,
      productId: productId,
      size: size ?? this.size,
      name: name,
      price: price ?? this.price,
      imagePath: imagePath,
      quantity: quantity ?? this.quantity,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }

  static String _readString(Object? value, {String fallback = ''}) {
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? fallback : trimmed;
    }
    return fallback;
  }

  static int _readInt(Object? value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.toInt();
    }
    if (value is num) {
      final stringValue = value.toString();
      return int.tryParse(stringValue) ?? value.toInt();
    }
    final stringValue = value?.toString();
    if (stringValue != null) {
      return int.tryParse(stringValue) ?? fallback;
    }
    return fallback;
  }
}
