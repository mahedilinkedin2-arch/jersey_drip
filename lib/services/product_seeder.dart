import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../data/seed_products.dart';

class ProductSeeder {
  const ProductSeeder._();

  static Future<void> seedProducts() async {
    final productsCollection = FirebaseFirestore.instance.collection(
      'products',
    );

    final existingProducts = await productsCollection.get();
    final existingProductNames = existingProducts.docs
        .map((document) => document.data()['name'])
        .whereType<String>()
        .map(_normalizeProductName)
        .toSet();
    final existingProductIds = existingProducts.docs
        .map((document) => document.id)
        .map(_normalizeProductName)
        .toSet();
    final existingProductImagePaths = existingProducts.docs
        .map(
          (document) => _readFirstValue(document.data(), const [
            'imagePath',
            'imagepath',
            'image_path',
            'image path',
            'image',
            'assetPath',
            'asset_path',
            'path',
            'imageUrl',
            'imageURL',
          ]),
        )
        .whereType<String>()
        .map(_normalizeImagePath)
        .where((path) => path.isNotEmpty)
        .toSet();

    for (final product in SeedProducts.products) {
      final name = product['name'] as String;
      final documentId = _productDocumentId(name);
      final normalizedName = _normalizeProductName(name);
      final normalizedImagePath = _normalizeImagePath(
        product['imagePath'] as String,
      );

      if (existingProductIds.contains(documentId) ||
          existingProductNames.contains(normalizedName) ||
          existingProductImagePaths.contains(normalizedImagePath)) {
        continue;
      }

      await productsCollection.doc(documentId).set(product);
      existingProductIds.add(documentId);
      existingProductNames.add(normalizedName);
      existingProductImagePaths.add(normalizedImagePath);
    }
  }
}

String _productDocumentId(String name) {
  return _normalizeProductName(name).replaceAll(RegExp(r'[^a-z0-9]'), '');
}

String _normalizeProductName(String name) {
  return name.trim().toLowerCase();
}

Object? _readFirstValue(Map<String, dynamic> data, List<String> keys) {
  final normalizedDataKeys = {
    for (final key in data.keys) _normalizeFieldName(key): key,
  };

  for (final key in keys) {
    final dataKey = data.containsKey(key)
        ? key
        : normalizedDataKeys[_normalizeFieldName(key)];
    if (dataKey == null) {
      continue;
    }

    final value = data[dataKey];
    if (value is String && value.trim().isEmpty) {
      continue;
    }
    if (value != null) {
      return value;
    }
  }

  return null;
}

String _normalizeFieldName(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[\s_-]'), '');
}

String _normalizeImagePath(String value) {
  var path = value.trim().toLowerCase().replaceAll(r'\', '/');

  while (path.startsWith('/')) {
    path = path.substring(1);
  }

  if (path.startsWith('assets/')) {
    path = path.substring('assets/'.length);
  }

  return path;
}
