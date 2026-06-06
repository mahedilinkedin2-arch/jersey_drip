import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/product.dart';
import '../models/wishlist_item.dart';

class WishlistService {
  WishlistService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<List<WishlistItem>> wishlistStream() {
    final uid = _requireUid();

    return _wishlistCollection(uid).snapshots().map(
      (snapshot) =>
          snapshot.docs.map(WishlistItem.fromDocument).toList(growable: false),
    );
  }

  Stream<Set<String>> wishlistProductIdsStream() {
    return wishlistStream().map(
      (items) => items.map((item) => item.productId).toSet(),
    );
  }

  Future<void> addProduct(Product product) {
    final uid = _requireUid();
    return _wishlistCollection(uid).doc(product.id).set({
      'productId': product.id,
      'name': product.name,
      'price': product.discountedPrice.toInt(),
      'imagePath': product.imagePath,
    });
  }

  Future<void> removeProduct(String productId) {
    final uid = _requireUid();
    return _wishlistCollection(uid).doc(productId).delete();
  }

  Future<void> toggleProduct(Product product, {required bool isWishlisted}) {
    if (isWishlisted) {
      return removeProduct(product.id);
    }

    return addProduct(product);
  }

  CollectionReference<Map<String, dynamic>> _wishlistCollection(String uid) {
    return _firestore.collection('users').doc(uid).collection('wishlist');
  }

  String _requireUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('A signed-in user is required to access the wishlist.');
    }
    return uid;
  }
}
