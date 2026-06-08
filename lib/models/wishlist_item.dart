import 'package:cloud_firestore/cloud_firestore.dart';

class WishlistItem {
  const WishlistItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.imagePath,
  });

  final String productId;
  final String name;
  final int price;
  final String imagePath;

  factory WishlistItem.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    return WishlistItem(
      productId: _readString(data['productId'], fallback: document.id),
      name: _readString(data['name'], fallback: 'Wishlist item'),
      price: _readInt(data['price']),
      imagePath: _readString(data['imagePath']),
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
