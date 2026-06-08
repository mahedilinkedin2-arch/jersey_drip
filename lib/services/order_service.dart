import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/cart_item.dart';
import '../models/order.dart';

class OrderService {
  OrderService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<List<AppOrder>> ordersStream() {
    final uid = _requireUid();

    return _ordersCollection(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(AppOrder.fromDocument).toList(growable: false),
        );
  }

  Future<AppOrder> createPaidOrder({
    required List<CartItem> items,
    required String paymentMethod,
    required String transactionId,
    required String paymentSessionId,
  }) async {
    final uid = _requireUid();
    final orderDocument = _ordersCollection(uid).doc();
    final paymentSessionDocument = _firestore
        .collection('payment_sessions')
        .doc(paymentSessionId);
    final orderItems = items
        .map(OrderItem.fromCartItem)
        .toList(growable: false);
    final totalPrice = orderItems.fold<int>(
      0,
      (total, item) => total + item.totalPrice,
    );
    final createdAt = DateTime.now();

    await _firestore.runTransaction((transaction) async {
      final paymentSessionSnapshot = await transaction.get(
        paymentSessionDocument,
      );
      final paymentSessionData = paymentSessionSnapshot.data();
      if (!paymentSessionSnapshot.exists || paymentSessionData == null) {
        throw StateError('Payment session not found');
      }
      if (_readString(paymentSessionData['userId']) != uid) {
        throw StateError('Payment session does not belong to this user');
      }
      if (_readString(paymentSessionData['status']) != 'verified' ||
          paymentSessionData['verificationCompleted'] != true ||
          paymentSessionData['verifiedAt'] == null ||
          paymentSessionData['completedAt'] != null) {
        throw StateError('Payment session is not eligible for completion');
      }

      final purchases = _aggregatePurchases(items);
      final productSnapshots =
          <String, DocumentSnapshot<Map<String, dynamic>>>{};
      for (final productId
          in purchases.values.map((purchase) => purchase.productId).toSet()) {
        final productReference = _firestore
            .collection('products')
            .doc(productId);
        productSnapshots[productId] = await transaction.get(productReference);
      }

      for (final productId in productSnapshots.keys) {
        final productSnapshot = productSnapshots[productId];
        final productData = productSnapshot?.data();
        if (productSnapshot == null ||
            !productSnapshot.exists ||
            productData == null) {
          final firstPurchase = purchases.values.firstWhere(
            (purchase) => purchase.productId == productId,
          );
          throw StateError('${firstPurchase.name} is no longer available');
        }

        final productPurchases = purchases.values
            .where((purchase) => purchase.productId == productId)
            .toList(growable: false);
        final update = _stockUpdateForPurchases(productData, productPurchases);
        transaction.update(
          _firestore.collection('products').doc(productId),
          update,
        );
      }

      transaction.set(orderDocument, {
        'orderId': orderDocument.id,
        'userId': uid,
        'items': orderItems.map((item) => item.toMap()).toList(growable: false),
        'totalPrice': totalPrice,
        'paymentMethod': paymentMethod,
        'paymentStatus': 'paid',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'transactionId': transactionId,
      });

      for (final item in items) {
        transaction.delete(_cartCollection(uid).doc(item.id));
      }

      transaction.update(paymentSessionDocument, {
        'status': 'completed',
        'completedAt': DateTime.now().toIso8601String(),
      });
    });

    return AppOrder(
      orderId: orderDocument.id,
      userId: uid,
      items: orderItems,
      totalPrice: totalPrice,
      paymentMethod: paymentMethod,
      paymentStatus: 'paid',
      status: 'pending',
      createdAt: createdAt,
      transactionId: transactionId,
    );
  }

  CollectionReference<Map<String, dynamic>> _ordersCollection(String uid) {
    return _firestore.collection('users').doc(uid).collection('orders');
  }

  CollectionReference<Map<String, dynamic>> _cartCollection(String uid) {
    return _firestore.collection('users').doc(uid).collection('cart');
  }

  Map<String, _StockPurchase> _aggregatePurchases(List<CartItem> items) {
    final purchases = <String, _StockPurchase>{};
    for (final item in items) {
      final key = '${item.productId}::${item.size}';
      final existing = purchases[key];
      if (existing == null) {
        purchases[key] = _StockPurchase(
          productId: item.productId,
          size: item.size,
          name: item.name,
          quantity: item.quantity,
        );
        continue;
      }

      purchases[key] = existing.copyWith(
        quantity: existing.quantity + item.quantity,
      );
    }
    return purchases;
  }

  Map<String, Object?> _stockUpdateForPurchases(
    Map<String, dynamic> productData,
    List<_StockPurchase> purchases,
  ) {
    final firstPurchase = purchases.first;
    final rawSizes = productData['sizes'];
    if (rawSizes is Map) {
      final updatedSizes = Map<String, dynamic>.from(rawSizes);
      for (final purchase in purchases) {
        if (purchase.size.isEmpty || !updatedSizes.containsKey(purchase.size)) {
          throw StateError(
            '${purchase.name} (${purchase.size}) is out of stock',
          );
        }

        final rawVariant = updatedSizes[purchase.size];
        if (rawVariant is! Map) {
          throw StateError(
            '${purchase.name} (${purchase.size}) is out of stock',
          );
        }

        final currentStock = _readInt(rawVariant['stock']);
        if (currentStock <= 0) {
          throw StateError(
            '${purchase.name} (${purchase.size}) is out of stock',
          );
        }
        if (purchase.quantity > currentStock) {
          throw StateError(
            'Only $currentStock ${purchase.name} (${purchase.size}) left in stock',
          );
        }

        updatedSizes[purchase.size] = {
          ...Map<String, dynamic>.from(rawVariant),
          'stock': currentStock - purchase.quantity,
        };
      }

      return {'sizes': updatedSizes};
    }

    final stockField = _stockFieldName(productData);
    if (stockField == null) {
      throw StateError('${firstPurchase.name} is out of stock');
    }

    final totalQuantity = purchases.fold<int>(
      0,
      (total, purchase) => total + purchase.quantity,
    );
    final currentStock = _readInt(productData[stockField]);
    if (currentStock <= 0) {
      throw StateError('${firstPurchase.name} is out of stock');
    }
    if (totalQuantity > currentStock) {
      throw StateError(
        'Only $currentStock ${firstPurchase.name} left in stock',
      );
    }

    return {stockField: currentStock - totalQuantity};
  }

  String? _stockFieldName(Map<String, dynamic> data) {
    for (final field in const [
      'quantity',
      'stockQuantity',
      'stockquantity',
      'stock_quantity',
      'stock',
    ]) {
      if (data.containsKey(field)) return field;
    }
    return null;
  }

  String _requireUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('A signed-in user is required to access orders.');
    }
    return uid;
  }
}

class _StockPurchase {
  const _StockPurchase({
    required this.productId,
    required this.size,
    required this.name,
    required this.quantity,
  });

  final String productId;
  final String size;
  final String name;
  final int quantity;

  _StockPurchase copyWith({int? quantity}) {
    return _StockPurchase(
      productId: productId,
      size: size,
      name: name,
      quantity: quantity ?? this.quantity,
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
