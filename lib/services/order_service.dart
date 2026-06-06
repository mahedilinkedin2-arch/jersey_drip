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
  }) async {
    final uid = _requireUid();
    final orderDocument = _ordersCollection(uid).doc();
    final orderItems = items
        .map(OrderItem.fromCartItem)
        .toList(growable: false);
    final totalPrice = orderItems.fold<int>(
      0,
      (total, item) => total + item.totalPrice,
    );
    final createdAt = DateTime.now();

    final batch = _firestore.batch();
    batch.set(orderDocument, {
      'orderId': orderDocument.id,
      'userId': uid,
      'items': orderItems.map((item) => item.toMap()).toList(growable: false),
      'totalPrice': totalPrice,
      'paymentMethod': paymentMethod,
      'paymentStatus': 'paid',
      'status': 'processing',
      'createdAt': FieldValue.serverTimestamp(),
      'transactionId': transactionId,
    });

    for (final item in items) {
      batch.delete(_cartCollection(uid).doc(item.productId));
    }

    await batch.commit();

    return AppOrder(
      orderId: orderDocument.id,
      userId: uid,
      items: orderItems,
      totalPrice: totalPrice,
      paymentMethod: paymentMethod,
      paymentStatus: 'paid',
      status: 'processing',
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

  String _requireUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('A signed-in user is required to access orders.');
    }
    return uid;
  }
}
