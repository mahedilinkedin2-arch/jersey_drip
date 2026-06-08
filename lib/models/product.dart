class SizeVariant {
  const SizeVariant({required this.price, required this.stock});

  final int price;
  final int stock;

  bool get isAvailable => stock > 0;
}

const List<String> _letterSizeOrder = ['S', 'M', 'L', 'XL'];

String getSmallestAvailableSize(Map<String, SizeVariant> sizes) {
  final orderedSizes = sortedSizeKeys(sizes);
  for (final size in orderedSizes) {
    if ((sizes[size]?.stock ?? 0) > 0) {
      return size;
    }
  }

  return orderedSizes.isEmpty ? '' : orderedSizes.first;
}

List<String> sortedSizeKeys(Map<String, SizeVariant> sizes) {
  final keys = sizes.keys.toList(growable: false);
  keys.sort(_compareSizes);
  return keys;
}

int _compareSizes(String left, String right) {
  final leftNumber = int.tryParse(left);
  final rightNumber = int.tryParse(right);
  if (leftNumber != null && rightNumber != null) {
    return leftNumber.compareTo(rightNumber);
  }

  final leftLetterIndex = _letterSizeOrder.indexOf(left.toUpperCase());
  final rightLetterIndex = _letterSizeOrder.indexOf(right.toUpperCase());
  if (leftLetterIndex != -1 && rightLetterIndex != -1) {
    return leftLetterIndex.compareTo(rightLetterIndex);
  }
  if (leftLetterIndex != -1) return -1;
  if (rightLetterIndex != -1) return 1;

  return left.compareTo(right);
}

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final double discountedPrice;
  final String category;
  final String brand;
  final String imagePath;
  final List<String> images;
  final int stockQuantity;
  final Map<String, SizeVariant> sizes;
  final bool featured;
  final bool isActive;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.discountedPrice,
    required this.category,
    this.brand = '',
    this.imagePath = '',
    List<String>? images,
    this.stockQuantity = 0,
    Map<String, SizeVariant>? sizes,
    this.featured = false,
    this.isActive = true,
    DateTime? createdAt,
  }) : images = images ?? const [],
       sizes = sizes ?? const {},
       createdAt = createdAt ?? DateTime.now();

  List<String> get sizeOptions => sortedSizeKeys(sizes);

  bool get isAvailable {
    if (sizes.isEmpty) return stockQuantity > 0;
    return sizes.values.any((variant) => variant.isAvailable);
  }

  bool isSizeAvailable(String size) {
    return (sizes[size]?.stock ?? 0) > 0;
  }

  SizeVariant? variantForSize(String size) => sizes[size];
  String get imageUrl => imagePath;
  SizeVariant get defaultVariant {
    if (sizes.isEmpty) {
      return SizeVariant(price: discountedPrice.round(), stock: stockQuantity);
    }

    return sizes[defaultSize] ?? sizes.values.first;
  }

  String get defaultSize {
    if (sizes.isEmpty) return '';
    return getSmallestAvailableSize(sizes);
  }
}
