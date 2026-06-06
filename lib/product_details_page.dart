import 'package:flutter/material.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_spacing.dart';
import 'core/theme/app_text_styles.dart';
import 'models/product.dart';
import 'services/cart_service.dart';
import 'services/wishlist_service.dart';

class ProductDetailsPage extends StatefulWidget {
  const ProductDetailsPage({super.key, required this.product});

  final Product product;

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  final CartService _cartService = CartService();
  final WishlistService _wishlistService = WishlistService();

  late final List<String> _sizes = widget.product.sizes.isEmpty
      ? const ['S', 'M', 'L', 'XL']
      : widget.product.sizes;
  late final Stream<Set<String>> _wishlistProductIdsStream = _wishlistService
      .wishlistProductIdsStream();

  late String _selectedSize = _sizes.first;

  Product get product => widget.product;

  int get _selectedSizeStock {
    final index = _sizes.indexOf(_selectedSize);
    final simulatedStock = product.stockQuantity - (index * 2);
    return simulatedStock < 1 ? 1 : simulatedStock;
  }

  String _formatPrice(double amount) {
    return '৳${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2)}';
  }

  String get _description {
    if (product.description.trim().isNotEmpty) {
      return product.description;
    }

    return 'Premium match-day style with a comfortable fit, clean finish, and everyday-ready feel for Jersey Drip shoppers.';
  }

  void _selectSize(String size) {
    setState(() {
      _selectedSize = size;
    });
  }

  Future<void> _addToCart() async {
    try {
      await _cartService.addProduct(product);
      if (!mounted) return;
      _showMessage('${product.name} added to cart');
    } catch (_) {
      if (!mounted) return;
      _showMessage('Unable to add product to cart');
    }
  }

  Future<void> _toggleWishlist(bool isWishlisted) async {
    try {
      await _wishlistService.toggleProduct(product, isWishlisted: isWishlisted);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Unable to update wishlist');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.backgroundDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        foregroundColor: AppColors.backgroundDark,
        centerTitle: true,
        title: Text(
          'Details',
          style: AppTextStyles.label.copyWith(
            color: AppColors.backgroundDark,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md + bottomPadding,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 24,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _addToCart,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.backgroundDark,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  'Add to Cart',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.backgroundDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  'Buy Now',
                  style: AppTextStyles.label.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StreamBuilder<Set<String>>(
                stream: _wishlistProductIdsStream,
                builder: (context, snapshot) {
                  final isWishlisted =
                      snapshot.data?.contains(product.id) ?? false;

                  return _ProductImageSection(
                    imagePath: product.imagePath,
                    wishlisted: isWishlisted,
                    onWishlistToggle: () => _toggleWishlist(isWishlisted),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.headingMedium.copyWith(
                        color: AppColors.backgroundDark,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatPrice(product.discountedPrice),
                        style: AppTextStyles.headingMedium.copyWith(
                          color: AppColors.backgroundDark,
                          fontSize: 24,
                        ),
                      ),
                      if (product.discountedPrice < product.price) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          _formatPrice(product.price),
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textSecondary,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _categoryLabel(product.category),
                style: AppTextStyles.label.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Select Size',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.backgroundDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _sizes.map((size) {
                  final selected = size == _selectedSize;

                  return ChoiceChip(
                    label: Text(size),
                    selected: selected,
                    showCheckmark: false,
                    onSelected: (_) => _selectSize(size),
                    selectedColor: AppColors.accent,
                    backgroundColor: AppColors.surface,
                    side: BorderSide(
                      color: selected ? AppColors.accent : AppColors.border,
                    ),
                    labelStyle: AppTextStyles.label.copyWith(
                      color: selected ? Colors.white : AppColors.backgroundDark,
                      fontWeight: FontWeight.w800,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Only $_selectedSizeStock left in stock',
                style: AppTextStyles.label.copyWith(color: AppColors.success),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Description',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.backgroundDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _description,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _categoryLabel(String category) {
    if (category.isEmpty) {
      return 'Product';
    }

    return category[0].toUpperCase() + category.substring(1);
  }
}

class _ProductImageSection extends StatelessWidget {
  const _ProductImageSection({
    required this.imagePath,
    required this.wishlisted,
    required this.onWishlistToggle,
  });

  final String imagePath;
  final bool wishlisted;
  final VoidCallback onWishlistToggle;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.18,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(Icons.broken_image, size: 56),
                    );
                  },
                ),
              ),
            ),
          ),
          Positioned(
            top: AppSpacing.md,
            right: AppSpacing.md,
            child: Material(
              color: AppColors.surface.withAlpha(230),
              shape: const CircleBorder(),
              elevation: 6,
              shadowColor: AppColors.shadow,
              child: IconButton(
                tooltip: 'Wishlist',
                onPressed: onWishlistToggle,
                icon: Icon(
                  wishlisted ? Icons.favorite : Icons.favorite_border,
                  color: wishlisted ? AppColors.error : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
