import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../models/admin_dashboard_stats.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../models/user_profile.dart';
import '../services/product_service.dart';

class AdminService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ProductService _productService = ProductService();

  Stream<AdminDashboardStats> getDashboardStatsStream() {
    final Stream<QuerySnapshot<Map<String, dynamic>>> orderSnapshots = _db
        .collection('orders')
        .snapshots();
    final Stream<QuerySnapshot<Map<String, dynamic>>> productSnapshots = _db
        .collection('products')
        .snapshots();
    final Stream<QuerySnapshot<Map<String, dynamic>>> userSnapshots = _db
        .collection('users')
        .snapshots();

    return Stream.multi((controller) {
      QuerySnapshot<Map<String, dynamic>>? latestOrders;
      QuerySnapshot<Map<String, dynamic>>? latestProducts;
      QuerySnapshot<Map<String, dynamic>>? latestUsers;

      late final StreamSubscription<QuerySnapshot> orderSub;
      late final StreamSubscription<QuerySnapshot> productSub;
      late final StreamSubscription<QuerySnapshot> userSub;

      void emitStats() {
        if (latestOrders == null ||
            latestProducts == null ||
            latestUsers == null) {
          return;
        }
        try {
          final stats = _computeStats(
            latestOrders!,
            latestProducts!,
            latestUsers!,
          );
          controller.add(stats);
        } catch (error, stack) {
          controller.addError(error, stack);
        }
      }

      orderSub = orderSnapshots.listen((snapshot) {
        latestOrders = snapshot;
        emitStats();
      }, onError: controller.addError);

      productSub = productSnapshots.listen((snapshot) {
        latestProducts = snapshot;
        emitStats();
      }, onError: controller.addError);

      userSub = userSnapshots.listen((snapshot) {
        latestUsers = snapshot;
        emitStats();
      }, onError: controller.addError);

      controller.onCancel = () async {
        await orderSub.cancel();
        await productSub.cancel();
        await userSub.cancel();
      };
    });
  }

  Stream<List<AppOrder>> watchOrders({int limit = 100}) {
    Query<Map<String, dynamic>> query = _db
        .collection('orders')
        .orderBy('createdAt', descending: true);

    if (limit > 0) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map(AppOrder.fromDocument).toList(growable: false);
    });
  }

  Stream<List<Product>> watchProducts() {
    return _productService.productsStream();
  }

  Stream<List<UserProfile>> watchUsers() {
    return _db.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => UserProfile.fromFirestore(doc.data()))
          .toList(growable: false);
    });
  }

  Future<UserProfile?> fetchUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserProfile.fromFirestore(doc.data()!);
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _db.collection('orders').doc(orderId).update({'status': status});
  }

  Future<void> addProduct(Map<String, dynamic> productData) async {
    final document = _db.collection('products').doc();
    final data = Map<String, dynamic>.from(productData)
      ..['createdAt'] = FieldValue.serverTimestamp();
    await document.set(data);
  }

  Future<void> updateProduct(
    String productId,
    Map<String, dynamic> productData,
  ) async {
    final document = _db.collection('products').doc(productId);
    final data = Map<String, dynamic>.from(productData)
      ..['updatedAt'] = FieldValue.serverTimestamp();
    await document.update(data);
  }

  Future<String> uploadProductImage(File image) async {
    final fileName = image.path.split('/').last;
    final storagePath =
        'products/$fileName-${DateTime.now().millisecondsSinceEpoch}';
    final ref = FirebaseStorage.instance.ref(storagePath);
    final uploadTask = ref.putFile(image);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> deleteProduct(String productId) async {
    final document = _db.collection('products').doc(productId);
    final cartSnapshot = await _db
        .collectionGroup('cart')
        .where('productId', isEqualTo: productId)
        .get();
    final wishlistSnapshot = await _db
        .collectionGroup('wishlist')
        .where('productId', isEqualTo: productId)
        .get();

    final deletions = <DocumentReference<Map<String, dynamic>>>[document];
    deletions.addAll(cartSnapshot.docs.map((doc) => doc.reference));
    deletions.addAll(wishlistSnapshot.docs.map((doc) => doc.reference));

    const batchLimit = 500;
    for (var start = 0; start < deletions.length; start += batchLimit) {
      final batch = _db.batch();
      final end = (start + batchLimit).clamp(0, deletions.length);
      for (final reference in deletions.sublist(start, end)) {
        batch.delete(reference);
      }
      await batch.commit();
    }
  }

  Future<void> updateProductActive(String productId, bool isActive) async {
    await _db.collection('products').doc(productId).update({
      'isActive': isActive,
    });
  }

  Future<void> updateProductSizeStock(
    String productId,
    String size,
    int stock,
  ) async {
    final document = _db.collection('products').doc(productId);
    final snapshot = await document.get();
    if (!snapshot.exists) {
      throw StateError('Product not found');
    }

    final data = snapshot.data() ?? {};
    final rawSizes = data['sizes'];
    if (rawSizes is! Map) {
      throw StateError('Product sizes are not available');
    }

    final updatedSizes = Map<String, dynamic>.from(rawSizes);
    final rawVariant = updatedSizes[size];
    if (rawVariant is! Map) {
      throw StateError('Size variant not found');
    }

    updatedSizes[size] = {
      ...Map<String, dynamic>.from(rawVariant),
      'stock': stock,
    };

    await document.update({'sizes': updatedSizes});
  }

  Future<void> updateUserRole(String uid, String role) async {
    final normalizedRole = role.toLowerCase();
    final userRef = _db.collection('users').doc(uid);
    final snapshot = await userRef.get();

    if (!snapshot.exists) {
      throw StateError('User not found');
    }

    final currentRole =
        (snapshot.data()?['role'] as String?)?.toLowerCase() ?? 'user';
    final adminRoles = ['admin', 'superadmin'];
    final isCurrentAdmin = adminRoles.contains(currentRole);
    final willBeAdmin = adminRoles.contains(normalizedRole);

    if (isCurrentAdmin && !willBeAdmin) {
      final adminSnapshot = await _db
          .collection('users')
          .where('role', whereIn: adminRoles)
          .get();
      final remainingAdmins = adminSnapshot.docs
          .where((doc) => doc.id != uid)
          .where((doc) {
            final roleValue =
                (doc.data()['role'] as String?)?.toLowerCase() ?? '';
            return adminRoles.contains(roleValue);
          })
          .length;

      if (remainingAdmins == 0) {
        throw StateError('Cannot remove the last admin from the system.');
      }
    }

    await userRef.update({'role': normalizedRole});
  }

  AdminDashboardStats _computeStats(
    QuerySnapshot<Map<String, dynamic>> orderSnap,
    QuerySnapshot<Map<String, dynamic>> productSnap,
    QuerySnapshot<Map<String, dynamic>> userSnap,
  ) {
    int totalProducts = 0;
    int totalOrders = 0;
    int deliveredOrders = 0;
    double totalRevenue = 0;
    int outOfStockCount = 0;
    int totalUsers = userSnap.docs.length;

    for (var doc in orderSnap.docs) {
      final data = doc.data();
      final status = (data['status'] ?? '').toString().toLowerCase();
      final totalPrice = data['totalPrice'];

      if (status == 'delivered') {
        deliveredOrders++;
        if (totalPrice is int) {
          totalRevenue += totalPrice.toDouble();
        } else if (totalPrice is double) {
          totalRevenue += totalPrice;
        } else if (totalPrice is String) {
          totalRevenue += double.tryParse(totalPrice) ?? 0;
        }
      } else {
        totalOrders++;
      }
    }

    for (var doc in productSnap.docs) {
      final data = doc.data();
      final isActive = data['isActive'];
      if (isActive is bool && !isActive) {
        continue;
      }

      totalProducts++;
      final sizes = data['sizes'] as Map<String, dynamic>?;
      int totalStock = 0;
      final hasSizes = sizes != null;

      if (hasSizes) {
        for (var sizeEntry in sizes.entries) {
          final sizeData = sizeEntry.value as Map<String, dynamic>? ?? {};
          final rawStock = sizeData['stock'];
          final stock = rawStock is int
              ? rawStock
              : rawStock is double
              ? rawStock.toInt()
              : int.tryParse(rawStock?.toString() ?? '') ?? 0;
          totalStock += stock;
          if (stock == 0) {
            outOfStockCount++;
          }
        }
      } else {
        final rawQuantity = data['quantity'];
        totalStock = rawQuantity is int
            ? rawQuantity
            : rawQuantity is double
            ? rawQuantity.toInt()
            : int.tryParse(rawQuantity?.toString() ?? '') ?? 0;
        if (totalStock == 0) {
          outOfStockCount++;
        }
      }
    }

    if (kDebugMode) {
      developer.log(
        'AdminDashboardStats computed',
        name: 'AdminService',
        error: {
          'totalProducts': totalProducts,
          'totalOrders': totalOrders,
          'deliveredOrders': deliveredOrders,
          'totalRevenue': totalRevenue,
          'outOfStockCount': outOfStockCount,
          'totalUsers': totalUsers,
        },
      );
    }

    return AdminDashboardStats(
      totalProducts: totalProducts,
      totalOrders: totalOrders,
      deliveredOrders: deliveredOrders,
      totalRevenue: totalRevenue,
      outOfStockCount: outOfStockCount,
      totalUsers: totalUsers,
    );
  }
}
