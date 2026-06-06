import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/cart_item.dart';
import '../models/product.dart';

class CartService {
  CartService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<List<CartItem>> cartStream() {
    final uid = _requireUid();

    return _cartCollection(uid).snapshots().map(
      (snapshot) =>
          snapshot.docs.map(CartItem.fromDocument).toList(growable: false),
    );
  }

  Future<void> addProduct(Product product) async {
    return addItem(
      productId: product.id,
      name: product.name,
      price: product.discountedPrice.toInt(),
      imagePath: product.imagePath,
    );
  }

  Future<void> addItem({
    required String productId,
    required String name,
    required int price,
    required String imagePath,
  }) async {
    final uid = _requireUid();
    final document = _cartCollection(uid).doc(productId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(document);

      if (snapshot.exists) {
        final data = snapshot.data();
        final currentQuantity = _readInt(data?['quantity'], fallback: 1);
        final cartPrice = _readInt(data?['price'], fallback: price);
        final nextQuantity = currentQuantity + 1;

        transaction.update(document, {
          'quantity': nextQuantity,
          'totalPrice': cartPrice * nextQuantity,
        });
        return;
      }

      transaction.set(document, {
        'productId': productId,
        'name': name,
        'price': price,
        'imagePath': imagePath,
        'quantity': 1,
        'totalPrice': price,
      });
    });
  }

  Future<void> updateQuantity(String productId, int quantity) async {
    final uid = _requireUid();
    final nextQuantity = quantity < 1 ? 1 : quantity;
    final document = _cartCollection(uid).doc(productId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(document);
      if (!snapshot.exists) {
        return;
      }

      final data = snapshot.data();
      final price = _readInt(data?['price']);

      transaction.update(document, {
        'quantity': nextQuantity,
        'totalPrice': price * nextQuantity,
      });
    });
  }

  Future<void> removeItem(String productId) {
    final uid = _requireUid();
    return _cartCollection(uid).doc(productId).delete();
  }

  CollectionReference<Map<String, dynamic>> _cartCollection(String uid) {
    return _firestore.collection('users').doc(uid).collection('cart');
  }

  String _requireUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('A signed-in user is required to access the cart.');
    }
    return uid;
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
}
