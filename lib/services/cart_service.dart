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

  Stream<Map<String, Map<String, SizeVariant>>> productSizesByProductStream() {
    return _firestore.collection('products').snapshots().map((snapshot) {
      return {
        for (final document in snapshot.docs)
          document.id: _sizeVariantsFromProductData(document.data()),
      };
    });
  }

  Future<void> addProduct(Product product) async {
    final variant = product.defaultVariant;
    return addItem(
      productId: product.id,
      size: product.defaultSize,
      name: product.name,
      price: variant.price,
      imagePath: product.imagePath,
    );
  }

  Future<void> addItem({
    required String productId,
    required String size,
    required String name,
    required int price,
    required String imagePath,
    int quantity = 1,
  }) async {
    final uid = _requireUid();
    final normalizedSize = size.trim();
    final document = _cartCollection(
      uid,
    ).doc(_cartDocumentId(productId, normalizedSize));
    final productDocument = _firestore.collection('products').doc(productId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(document);
      final productSnapshot = await transaction.get(productDocument);
      final productData = productSnapshot.data();
      if (!productSnapshot.exists || productData == null) {
        throw StateError('Product is no longer available');
      }

      final stock = _stockForProductSelection(productData, normalizedSize);
      if (stock == null || stock <= 0) {
        throw StateError('Selected size is out of stock');
      }

      if (snapshot.exists) {
        final data = snapshot.data();
        final currentQuantity = _readInt(data?['quantity'], fallback: 1);
        final cartPrice = _readInt(data?['price'], fallback: price);
        final nextQuantity = currentQuantity + quantity;
        if (nextQuantity > stock) {
          throw StateError('Only $stock left in stock');
        }

        transaction.update(document, {
          'quantity': nextQuantity,
          'totalPrice': cartPrice * nextQuantity,
        });
        return;
      }

      if (quantity > stock) {
        throw StateError('Only $stock left in stock');
      }

      transaction.set(document, {
        'productId': productId,
        'size': normalizedSize,
        'name': name,
        'price': price,
        'imagePath': imagePath,
        'quantity': quantity,
        'totalPrice': price * quantity,
      });
    });
  }

  Future<void> updateQuantity(
    String productId,
    int quantity, {
    String size = '',
  }) async {
    final uid = _requireUid();
    final nextQuantity = quantity < 1 ? 1 : quantity;
    final document = _cartCollection(uid).doc(_cartDocumentId(productId, size));
    final productDocument = _firestore.collection('products').doc(productId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(document);
      if (!snapshot.exists) {
        return;
      }

      final data = snapshot.data();
      final price = _readInt(data?['price']);
      final cartSize = _readString(data?['size'], fallback: size);
      final productSnapshot = await transaction.get(productDocument);
      final productData = productSnapshot.data();
      if (!productSnapshot.exists || productData == null) {
        throw StateError('Product is no longer available');
      }
      final stock = _stockForProductSelection(productData, cartSize);
      if (stock == null || stock <= 0) {
        throw StateError('Item out of stock');
      }
      if (nextQuantity > stock) {
        throw StateError('Only $stock left in stock');
      }

      transaction.update(document, {
        'quantity': nextQuantity,
        'totalPrice': price * nextQuantity,
      });
    });
  }

  Future<void> updateCartItemQuantity(CartItem item, int quantity) async {
    final uid = _requireUid();
    final nextQuantity = quantity < 1 ? 1 : quantity;
    final document = _cartCollection(uid).doc(item.id);
    final productDocument = _firestore
        .collection('products')
        .doc(item.productId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(document);
      if (!snapshot.exists) return;

      final data = snapshot.data();
      final price = _readInt(data?['price'], fallback: item.price);
      final cartSize = _readString(data?['size'], fallback: item.size);
      final productSnapshot = await transaction.get(productDocument);
      final productData = productSnapshot.data();
      if (!productSnapshot.exists || productData == null) {
        throw StateError('Product is no longer available');
      }
      final stock = _stockForProductSelection(productData, cartSize);
      if (stock == null || stock <= 0) {
        throw StateError('Item out of stock');
      }
      if (nextQuantity > stock) {
        throw StateError('Only $stock left in stock');
      }

      transaction.update(document, {
        'quantity': nextQuantity,
        'totalPrice': price * nextQuantity,
      });
    });
  }

  Future<void> updateSize(CartItem item, String size) async {
    final uid = _requireUid();
    final nextSize = size.trim();
    if (nextSize.isEmpty || nextSize == item.size) return;

    final currentDocument = _cartCollection(uid).doc(item.id);
    final nextDocument = _cartCollection(
      uid,
    ).doc(_cartDocumentId(item.productId, nextSize));
    final productDocument = _firestore
        .collection('products')
        .doc(item.productId);

    await _firestore.runTransaction((transaction) async {
      final currentSnapshot = await transaction.get(currentDocument);
      if (!currentSnapshot.exists) return;

      final productSnapshot = await transaction.get(productDocument);
      final productData = productSnapshot.data();
      if (!productSnapshot.exists || productData == null) {
        throw StateError('Product is no longer available');
      }

      final variant = _variantForProductSelection(productData, nextSize);
      if (variant == null || variant.stock <= 0) {
        throw StateError('Selected size is out of stock');
      }

      final targetSnapshot = await transaction.get(nextDocument);
      final targetQuantity = targetSnapshot.exists
          ? _readInt(targetSnapshot.data()?['quantity'], fallback: 1)
          : 0;
      final nextQuantity = targetQuantity + item.quantity;
      if (nextQuantity > variant.stock) {
        throw StateError('Only ${variant.stock} left in stock');
      }

      if (targetSnapshot.exists) {
        transaction.update(nextDocument, {
          'quantity': nextQuantity,
          'price': variant.price,
          'totalPrice': variant.price * nextQuantity,
        });
        transaction.delete(currentDocument);
        return;
      }

      final nextData = {
        'size': nextSize,
        'price': variant.price,
        'totalPrice': variant.price * item.quantity,
      };

      if (currentDocument.id == nextDocument.id) {
        transaction.update(currentDocument, nextData);
        return;
      }

      transaction.set(nextDocument, {...currentSnapshot.data()!, ...nextData});
      transaction.delete(currentDocument);
    });
  }

  Stream<Map<String, SizeVariant>> productSizesStream(String productId) {
    return _firestore.collection('products').doc(productId).snapshots().map((
      snapshot,
    ) {
      final data = snapshot.data();
      if (data == null) return const <String, SizeVariant>{};

      return _sizeVariantsFromProductData(data);
    });
  }

  Future<Product?> currentProduct(String productId) async {
    final snapshot = await _firestore
        .collection('products')
        .doc(productId)
        .get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return null;

    final price = _readInt(data['price']);
    return Product(
      id: snapshot.id,
      name: _readString(data['name'], fallback: 'Product'),
      description: _readString(data['description']),
      price: price.toDouble(),
      discountedPrice: price.toDouble(),
      category: _readString(data['category']),
      brand: _readString(data['brand']),
      imagePath: _readString(data['imagePath']),
      stockQuantity: _fallbackStock(data),
      sizes: _sizeVariantsFromProductData(data),
      featured: data['featured'] == true,
      createdAt: DateTime.now(),
    );
  }

  Future<void> removeItem(String productId, {String size = ''}) {
    final uid = _requireUid();
    return _cartCollection(uid).doc(_cartDocumentId(productId, size)).delete();
  }

  Future<void> removeCartItem(CartItem item) {
    final uid = _requireUid();
    return _cartCollection(uid).doc(item.id).delete();
  }

  Future<void> validateItemsInStock(List<CartItem> items) async {
    for (final item in items) {
      final snapshot = await _firestore
          .collection('products')
          .doc(item.productId)
          .get();
      final data = snapshot.data();
      if (!snapshot.exists || data == null) {
        throw StateError('${item.name} is no longer available');
      }

      final stock = _stockForCartItem(data, item);
      if (stock <= 0) {
        final sizeText = item.size.isEmpty ? '' : ' (${item.size})';
        throw StateError('${item.name}$sizeText is out of stock');
      }
      if (item.quantity > stock) {
        final sizeText = item.size.isEmpty ? '' : ' (${item.size})';
        throw StateError('Only $stock ${item.name}$sizeText left in stock');
      }
    }
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

  Map<String, SizeVariant> _sizeVariantsFromProductData(
    Map<String, dynamic> data,
  ) {
    return _readSizeVariants(
      data['sizes'],
      fallbackPrice: _readInt(data['price']),
      fallbackStock: _readInt(
        data['quantity'] ??
            data['stockQuantity'] ??
            data['stockquantity'] ??
            data['stock_quantity'] ??
            data['stock'],
      ),
    );
  }

  int _fallbackStock(Map<String, dynamic> data) {
    return _readInt(
      data['quantity'] ??
          data['stockQuantity'] ??
          data['stockquantity'] ??
          data['stock_quantity'] ??
          data['stock'],
    );
  }

  int _stockForCartItem(Map<String, dynamic> data, CartItem item) {
    final sizes = data['sizes'];
    if (sizes is Map && item.size.isNotEmpty) {
      final variant = sizes[item.size];
      if (variant is Map) {
        return _readInt(variant['stock']);
      }
      return 0;
    }

    return _readInt(
      data['quantity'] ??
          data['stockQuantity'] ??
          data['stockquantity'] ??
          data['stock_quantity'] ??
          data['stock'],
    );
  }

  int? _stockForProductSelection(Map<String, dynamic> data, String size) {
    final sizes = data['sizes'];
    if (sizes is Map && size.isNotEmpty && !sizes.containsKey(size)) {
      return null;
    }

    final variant = _variantForProductSelection(data, size);
    if (variant != null) return variant.stock;

    final stock =
        data['quantity'] ??
        data['stockQuantity'] ??
        data['stockquantity'] ??
        data['stock_quantity'] ??
        data['stock'];
    return stock == null ? null : _readInt(stock);
  }

  SizeVariant? _variantForProductSelection(
    Map<String, dynamic> data,
    String size,
  ) {
    final sizes = data['sizes'];
    if (sizes is Map && size.isNotEmpty) {
      final variant = sizes[size];
      if (variant is Map) {
        return SizeVariant(
          price: _readInt(variant['price'], fallback: _readInt(data['price'])),
          stock: _readInt(variant['stock']),
        );
      }
    }

    return _readSizeVariants(
      sizes,
      fallbackPrice: _readInt(data['price']),
      fallbackStock: _readInt(
        data['quantity'] ??
            data['stockQuantity'] ??
            data['stockquantity'] ??
            data['stock_quantity'] ??
            data['stock'],
      ),
    )[size];
  }

  Map<String, SizeVariant> _readSizeVariants(
    Object? value, {
    required int fallbackPrice,
    required int fallbackStock,
  }) {
    if (value is Map) {
      final variants = value.map((key, rawVariant) {
        final size = key.toString().trim();
        if (rawVariant is Map) {
          return MapEntry(
            size,
            SizeVariant(
              price: _readInt(rawVariant['price'], fallback: fallbackPrice),
              stock: _readInt(rawVariant['stock'], fallback: fallbackStock),
            ),
          );
        }

        return MapEntry(
          size,
          SizeVariant(price: fallbackPrice, stock: fallbackStock),
        );
      });
      final emptyKeys = variants.keys
          .where((key) => key.isEmpty)
          .toList(growable: false);
      for (final key in emptyKeys) {
        variants.remove(key);
      }
      if (variants.isNotEmpty) return variants;
    }

    return const <String, SizeVariant>{};
  }

  String _cartDocumentId(String productId, String size) {
    final trimmedSize = size.trim();
    if (trimmedSize.isEmpty) return productId;
    return '${productId}_${Uri.encodeComponent(trimmedSize)}';
  }

  String _readString(Object? value, {String fallback = ''}) {
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? fallback : trimmed;
    }
    return fallback;
  }
}
