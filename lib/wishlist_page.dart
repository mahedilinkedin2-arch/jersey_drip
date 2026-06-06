import 'package:flutter/material.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_spacing.dart';
import 'core/theme/app_text_styles.dart';
import 'models/wishlist_item.dart';
import 'services/cart_service.dart';
import 'services/wishlist_service.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  final WishlistService _wishlistService = WishlistService();
  final CartService _cartService = CartService();
  late final Stream<List<WishlistItem>> _wishlistStream = _wishlistService
      .wishlistStream();

  String _formatPrice(int amount) {
    return '৳$amount';
  }

  Future<void> _addToCart(WishlistItem item) async {
    try {
      await _cartService.addItem(
        productId: item.productId,
        name: item.name,
        price: item.price,
        imagePath: item.imagePath,
      );
      if (!mounted) return;
      _showMessage('${item.name} added to cart');
    } catch (_) {
      if (!mounted) return;
      _showMessage('Unable to add product to cart');
    }
  }

  Future<void> _removeFromWishlist(WishlistItem item) async {
    try {
      await _wishlistService.removeProduct(item.productId);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Unable to remove wishlist item');
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
    return SafeArea(
      child: StreamBuilder<List<WishlistItem>>(
        stream: _wishlistStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const _WishlistStateMessage(
              title: 'Unable to load wishlist',
              message: 'Please try again in a moment.',
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Text(
                  'Wishlist',
                  style: AppTextStyles.headingLarge.copyWith(
                    color: AppColors.backgroundDark,
                  ),
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? const _WishlistStateMessage(
                        title: 'Your wishlist is empty',
                        message: 'Save products to find them here later.',
                      )
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.sm,
                          AppSpacing.lg,
                          AppSpacing.lg,
                        ),
                        itemCount: items.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return _WishlistItemTile(
                            item: item,
                            priceText: _formatPrice(item.price),
                            onAddToCart: () => _addToCart(item),
                            onRemove: () => _removeFromWishlist(item),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WishlistItemTile extends StatelessWidget {
  const _WishlistItemTile({
    required this.item,
    required this.priceText,
    required this.onAddToCart,
    required this.onRemove,
  });

  final WishlistItem item;
  final String priceText;
  final VoidCallback onAddToCart;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 76,
              height: 76,
              color: AppColors.surfaceSoft,
              padding: const EdgeInsets.all(AppSpacing.xs),
              child: Image.asset(
                item.imagePath,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.broken_image, size: 34),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: IconButton(
                        tooltip: 'Remove from wishlist',
                        onPressed: onRemove,
                        icon: const Icon(Icons.favorite),
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  priceText,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton.icon(
                    onPressed: onAddToCart,
                    icon: const Icon(Icons.shopping_cart_outlined, size: 18),
                    label: const Text('Add to Cart'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WishlistStateMessage extends StatelessWidget {
  const _WishlistStateMessage({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.headingMedium.copyWith(
                color: AppColors.backgroundDark,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
