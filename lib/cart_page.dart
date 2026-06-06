import 'package:flutter/material.dart';

import 'checkout_page.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_spacing.dart';
import 'core/theme/app_text_styles.dart';
import 'models/cart_item.dart';
import 'services/cart_service.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final CartService _cartService = CartService();
  final Set<String> _selectedProductIds = {};
  late final Stream<List<CartItem>> _cartStream = _cartService.cartStream();

  String _formatPrice(int amount) {
    return '৳$amount';
  }

  Future<void> _updateQuantity(CartItem item, int quantity) async {
    try {
      await _cartService.updateQuantity(item.productId, quantity);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Unable to update cart item');
    }
  }

  Future<void> _removeItem(CartItem item) async {
    try {
      _selectedProductIds.remove(item.productId);
      await _cartService.removeItem(item.productId);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Unable to remove cart item');
    }
  }

  void _syncSelectionWithCart(List<CartItem> items) {
    final cartProductIds = items.map((item) => item.productId).toSet();
    _selectedProductIds.removeWhere(
      (productId) => !cartProductIds.contains(productId),
    );
  }

  void _toggleItemSelection(String productId, bool selected) {
    setState(() {
      if (selected) {
        _selectedProductIds.add(productId);
      } else {
        _selectedProductIds.remove(productId);
      }
    });
  }

  void _toggleSelectAll(List<CartItem> items, bool selected) {
    setState(() {
      if (selected) {
        _selectedProductIds.addAll(items.map((item) => item.productId));
      } else {
        _selectedProductIds.clear();
      }
    });
  }

  void _checkoutSelected(List<CartItem> selectedItems) {
    if (selectedItems.isEmpty) {
      _showMessage('Please select at least one item');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CheckoutPage(items: selectedItems)),
    );
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
      child: StreamBuilder<List<CartItem>>(
        stream: _cartStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _CartStateMessage(
              title: 'Unable to load cart',
              message: 'Please try again in a moment.',
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data!;
          _syncSelectionWithCart(items);

          final selectedItems = items
              .where((item) => _selectedProductIds.contains(item.productId))
              .toList(growable: false);
          final selectedTotal = selectedItems.fold<int>(
            0,
            (total, item) => total + item.totalPrice,
          );
          final allSelected =
              items.isNotEmpty && _selectedProductIds.length == items.length;
          final partiallySelected =
              _selectedProductIds.isNotEmpty && !allSelected;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CartHeader(
                itemCount: items.length,
                allSelected: allSelected,
                partiallySelected: partiallySelected,
                onSelectAllChanged: items.isEmpty
                    ? null
                    : (selected) => _toggleSelectAll(items, selected ?? false),
              ),
              Expanded(
                child: items.isEmpty
                    ? const _CartStateMessage(
                        title: 'Your cart is empty',
                        message: 'Add products to see them here.',
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
                          return _CartItemTile(
                            item: item,
                            selected: _selectedProductIds.contains(
                              item.productId,
                            ),
                            priceText: _formatPrice(item.price),
                            subtotalText: _formatPrice(item.totalPrice),
                            onSelectedChanged: (selected) =>
                                _toggleItemSelection(
                                  item.productId,
                                  selected ?? false,
                                ),
                            onDecrease: item.quantity == 1
                                ? () => _removeItem(item)
                                : () =>
                                      _updateQuantity(item, item.quantity - 1),
                            onIncrease: () =>
                                _updateQuantity(item, item.quantity + 1),
                            onDelete: () => _removeItem(item),
                          );
                        },
                      ),
              ),
              _CartTotalBar(
                selectedCount: selectedItems.length,
                totalText: _formatPrice(selectedTotal),
                checkoutEnabled: selectedItems.isNotEmpty,
                onCheckout: () => _checkoutSelected(selectedItems),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CartHeader extends StatelessWidget {
  const _CartHeader({
    required this.itemCount,
    required this.allSelected,
    required this.partiallySelected,
    required this.onSelectAllChanged,
  });

  final int itemCount;
  final bool allSelected;
  final bool partiallySelected;
  final ValueChanged<bool?>? onSelectAllChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Cart',
            style: AppTextStyles.headingLarge.copyWith(
              color: AppColors.backgroundDark,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$itemCount item${itemCount == 1 ? '' : 's'}',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Checkbox(
                value: partiallySelected ? null : allSelected,
                tristate: true,
                activeColor: AppColors.accent,
                onChanged: onSelectAllChanged,
              ),
              Text(
                'Select All',
                style: AppTextStyles.label.copyWith(
                  color: onSelectAllChanged == null
                      ? AppColors.textSecondary
                      : AppColors.backgroundDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({
    required this.item,
    required this.selected,
    required this.priceText,
    required this.subtotalText,
    required this.onSelectedChanged,
    required this.onDecrease,
    required this.onIncrease,
    required this.onDelete,
  });

  final CartItem item;
  final bool selected;
  final String priceText;
  final String subtotalText;
  final ValueChanged<bool?> onSelectedChanged;
  final VoidCallback? onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onDelete;

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
          SizedBox(
            width: 36,
            child: Checkbox(
              value: selected,
              activeColor: AppColors.accent,
              onChanged: onSelectedChanged,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 72,
              height: 72,
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
                        tooltip: 'Remove',
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline),
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
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Subtotal $subtotalText',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.backgroundDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _QuantityControls(
                  quantity: item.quantity,
                  onDecrease: onDecrease,
                  onIncrease: onIncrease,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityControls extends StatelessWidget {
  const _QuantityControls({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int quantity;
  final VoidCallback? onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _QuantityButton(icon: Icons.remove, onPressed: onDecrease),
        SizedBox(
          width: 38,
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: AppTextStyles.label.copyWith(
              color: AppColors.backgroundDark,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        _QuantityButton(icon: Icons.add, onPressed: onIncrease),
      ],
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: AppColors.surfaceSoft,
          disabledBackgroundColor: AppColors.backgroundLight,
          foregroundColor: AppColors.backgroundDark,
          disabledForegroundColor: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _CartTotalBar extends StatelessWidget {
  const _CartTotalBar({
    required this.selectedCount,
    required this.totalText,
    required this.checkoutEnabled,
    required this.onCheckout,
  });

  final int selectedCount;
  final String totalText;
  final bool checkoutEnabled;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$selectedCount selected',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  totalText,
                  style: AppTextStyles.headingMedium.copyWith(
                    color: AppColors.backgroundDark,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: checkoutEnabled ? onCheckout : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              disabledBackgroundColor: AppColors.border,
              foregroundColor: Colors.white,
              disabledForegroundColor: AppColors.textSecondary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'Checkout',
              style: AppTextStyles.label.copyWith(
                color: checkoutEnabled ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartStateMessage extends StatelessWidget {
  const _CartStateMessage({required this.title, required this.message});

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
