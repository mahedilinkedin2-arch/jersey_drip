import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../models/admin_dashboard_stats.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../models/user_profile.dart';
import '../services/product_service.dart';

class AdminService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'us-central1',
  );
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
    final orderRef = _db.collection('orders').doc(orderId);
    try {
      await _db.runTransaction((txn) async {
        final snap = await txn.get(orderRef);
        if (!snap.exists) {
          throw StateError('Order not found');
        }
        final current =
            (snap.data()?['status'] as String?)?.toLowerCase() ?? '';
        if (current == 'delivered' && status.toLowerCase() != 'delivered') {
          throw StateError(
            'Delivered orders are immutable and cannot be modified',
          );
        }
        txn.update(orderRef, {'status': status});
      });
      if (kDebugMode) {
        developer.log(
          'Order $orderId status updated -> $status',
          name: 'AdminService',
        );
      }
    } catch (e, st) {
      developer.log(
        'Failed to update order $orderId: $e',
        name: 'AdminService',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
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
    try {
      await _functions.httpsCallable('deleteProductAdmin').call(
        <String, dynamic>{'productId': productId},
      );
    } on FirebaseFunctionsException catch (error) {
      if (error.code == 'not-found') {
        await _functions.httpsCallable('deleteProduct').call(<String, dynamic>{
          'productId': productId,
        });
        return;
      }
      rethrow;
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

    if (normalizedRole != 'user' && normalizedRole != 'admin') {
      throw ArgumentError.value(
        role,
        'role',
        'Role must be either user or admin.',
      );
    }

    try {
      try {
        await _functions.httpsCallable('updateUserRoleAdmin').call(
          <String, dynamic>{'uid': uid, 'role': normalizedRole},
        );
      } on FirebaseFunctionsException catch (error) {
        if (error.code == 'not-found') {
          await _functions.httpsCallable('updateUserRole').call(
            <String, dynamic>{'uid': uid, 'role': normalizedRole},
          );
        } else {
          rethrow;
        }
      }

      if (kDebugMode) {
        developer.log(
          'Requested backend role update for user $uid -> $normalizedRole',
          name: 'AdminService',
        );
      }
    } catch (e, st) {
      developer.log(
        'Failed to request backend role update for $uid: $e',
        name: 'AdminService',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
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
      final totalPrice = _readDouble(data['totalPrice']);

      if (status == 'delivered') {
        deliveredOrders++;
        totalRevenue += totalPrice;
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
          final stock = _readInt(sizeData['stock']);
          totalStock += stock;
          if (stock == 0) {
            outOfStockCount++;
          }
        }
      } else {
        totalStock = _readInt(
          data['quantity'] ??
              data['stockQuantity'] ??
              data['stockquantity'] ??
              data['stock_quantity'] ??
              data['stock'],
        );
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

  double _readDouble(Object? value, {double fallback = 0}) {
    if (value is double) {
      return value;
    }
    if (value is int) {
      return value.toDouble();
    }
    if (value is num) {
      final stringValue = value.toString();
      return double.tryParse(stringValue) ?? value.toDouble();
    }
    final stringValue = value?.toString();
    if (stringValue != null) {
      return double.tryParse(stringValue) ?? fallback;
    }
    return fallback;
  }
}
