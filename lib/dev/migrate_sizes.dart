import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';

Future<void> main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final firestore = FirebaseFirestore.instance;
  final products = await firestore.collection('products').get();

  print('Found ${products.docs.length} products.');

  for (final document in products.docs) {
    final data = document.data();
    final existingSizes = data['sizes'];
    final price = _readInt(data['price']);
    final category = _readString(data['category']).toLowerCase();
    final sizes = _defaultSizesForCategory(category, price);

    if (_hasExpectedSizes(existingSizes, sizes.keys)) {
      print('Skipping ${document.id}: sizes already has the target shape.');
      continue;
    }

    await document.reference.update({'sizes': sizes});
    print(
      'Updated ${document.id}: added ${sizes.keys.join(', ')} size variants.',
    );
  }

  print('Size migration complete.');
}

bool _hasExpectedSizes(Object? value, Iterable<String> expectedKeys) {
  if (value is! Map || value.isEmpty) return false;

  for (final size in expectedKeys) {
    final variant = value[size];
    if (variant is! Map) return false;
    if (!variant.containsKey('price') || !variant.containsKey('stock')) {
      return false;
    }
  }

  return true;
}

Map<String, Map<String, int>> _defaultSizesForCategory(
  String category,
  int price,
) {
  final labels = switch (category) {
    'jersey' ||
    'jerseys' ||
    'clothing' ||
    'shirt' ||
    'shirts' => const {'S': 5, 'M': 10, 'L': 7, 'XL': 2},
    'socks' => const {'S': 5, 'M': 10, 'L': 7},
    'trainers' ||
    'boots' ||
    'shoes' => const {'40': 5, '41': 10, '42': 7, '43': 4, '44': 2},
    _ => const {'One Size': 10},
  };

  return {
    for (final entry in labels.entries)
      entry.key: {'price': price, 'stock': entry.value},
  };
}

int _readInt(Object? value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is num) {
    final stringValue = value.toString();
    return int.tryParse(stringValue) ?? value.toInt();
  }
  final stringValue = value?.toString();
  if (stringValue != null) return int.tryParse(stringValue) ?? 0;
  return 0;
}

String _readString(Object? value) {
  if (value is String) return value.trim();
  return '';
}
