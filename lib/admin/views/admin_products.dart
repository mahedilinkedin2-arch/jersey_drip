import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/admin_provider.dart';
import '../views/admin_product_detail.dart';
import '../widgets/admin_product_form.dart';

class AdminProducts extends ConsumerStatefulWidget {
  const AdminProducts({super.key});

  @override
  ConsumerState<AdminProducts> createState() => _AdminProductsState();
}

class _AdminProductsState extends ConsumerState<AdminProducts> {
  final _searchController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Product catalog', style: AppTextStyles.headingMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Create or remove products from your store. Editing and toggling active state is not available in this admin flow.',
                      style: AppTextStyles.body,
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminProductForm()),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Add product'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Search products',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: productsAsync.when(
              data: (products) {
                final query = _searchController.text.trim().toLowerCase();
                final filtered = products
                    .where((product) {
                      if (query.isEmpty) return true;
                      return product.name.toLowerCase().contains(query) ||
                          product.category.toLowerCase().contains(query);
                    })
                    .toList(growable: false);

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'No products match the search.',
                      style: AppTextStyles.body,
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final product = filtered[index];
                    final minPrice = product.sizes.isNotEmpty
                        ? product.sizes.values
                              .map((variant) => variant.price)
                              .reduce((a, b) => a < b ? a : b)
                        : 0;
                    final totalStock = product.sizes.values.fold<int>(
                      0,
                      (sum, variant) => sum + variant.stock,
                    );
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrow = constraints.maxWidth < 560;
                        final productImage = product.imagePath.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  product.imagePath,
                                  width: 84,
                                  height: 84,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 84,
                                    height: 84,
                                    color: AppColors.backgroundLight,
                                    child: const Icon(
                                      Icons.image_not_supported,
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink();

                        final productDetails = Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: AppTextStyles.body.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                product.category,
                                style: AppTextStyles.label,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Price from: ৳$minPrice',
                                style: AppTextStyles.body,
                              ),
                              Text(
                                'Stock: $totalStock',
                                style: AppTextStyles.body,
                              ),
                            ],
                          ),
                        );

                        final actionButtons = Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        AdminProductDetail(product: product),
                                  ),
                                );
                              },
                              child: const Text('View'),
                            ),
                            TextButton(
                              onPressed: _saving
                                  ? null
                                  : () async {
                                      final uid =
                                          FirebaseAuth
                                              .instance
                                              .currentUser
                                              ?.uid ??
                                          'unknown';
                                      final roleValue = ref
                                          .read(roleProvider)
                                          .maybeWhen(
                                            data: (role) => role.name,
                                            orElse: () => 'unknown',
                                          );
                                      final isAdmin =
                                          roleValue == 'admin' ||
                                          roleValue == 'superadmin';
                                      ref
                                          .read(adminDebugLogsProvider.notifier)
                                          .add(
                                            'Delete requested for product ${product.id} by uid=$uid role=$roleValue isAdmin=$isAdmin',
                                          );
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: const Text('Delete product?'),
                                          content: const Text(
                                            'This action cannot be undone.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(
                                                context,
                                              ).pop(false),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.of(
                                                context,
                                              ).pop(true),
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirmed != true) return;
                                      setState(() => _saving = true);
                                      try {
                                        await ref
                                            .read(adminServiceProvider)
                                            .deleteProduct(product.id);
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text('Product deleted.'),
                                            ),
                                          );
                                        }
                                      } catch (error) {
                                        ref
                                            .read(
                                              adminDebugLogsProvider.notifier,
                                            )
                                            .add(
                                              'Product delete failed: $error',
                                            );
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Unable to delete product: $error',
                                              ),
                                            ),
                                          );
                                        }
                                      } finally {
                                        if (mounted)
                                          setState(() => _saving = false);
                                      }
                                    },
                              child: const Text(
                                'Delete',
                                style: TextStyle(color: AppColors.error),
                              ),
                            ),
                          ],
                        );

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: isNarrow
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          productImage,
                                          if (product.imagePath.isNotEmpty)
                                            const SizedBox(
                                              width: AppSpacing.md,
                                            ),
                                          productDetails,
                                        ],
                                      ),
                                      const SizedBox(height: AppSpacing.md),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [actionButtons],
                                      ),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      productImage,
                                      if (product.imagePath.isNotEmpty)
                                        const SizedBox(width: AppSpacing.md),
                                      productDetails,
                                      actionButtons,
                                    ],
                                  ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text(
                  'Unable to load products: ${error.toString()}',
                  style: AppTextStyles.body,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
