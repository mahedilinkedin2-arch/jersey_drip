import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/product.dart';

class AdminProductDetail extends StatelessWidget {
  const AdminProductDetail({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.images.isNotEmpty
        ? product.images.first
        : product.imagePath;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product details'),
        backgroundColor: AppColors.deepBlue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  imageUrl,
                  height: 220,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 220,
                    color: const Color.fromARGB(255, 203, 142, 142),
                    child: const Icon(Icons.image_not_supported, size: 64),
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            Text(product.name, style: AppTextStyles.headingMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(product.category, style: AppTextStyles.label),
            const SizedBox(height: AppSpacing.sm),
            Text(product.description, style: AppTextStyles.body),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                _InfoChip(
                  label: 'Price',
                  value: '\$${product.discountedPrice.toStringAsFixed(0)}',
                ),
                const SizedBox(width: AppSpacing.sm),
                _InfoChip(
                  label: 'Original',
                  value: '\$${product.price.toStringAsFixed(0)}',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Sizes',
              style: AppTextStyles.headingMedium.copyWith(fontSize: 18),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (product.sizes.isEmpty)
              Text('No size variants.', style: AppTextStyles.body)
            else
              ...product.sizes.entries.map(
                (entry) => Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    title: Text(
                      entry.key,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      'Price: \$${entry.value.price} • Stock: ${entry.value.stock}',
                      style: AppTextStyles.body,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: AppColors.surfaceSoft,
      ),
      child: Text(
        '$label: $value',
        style: AppTextStyles.label.copyWith(color: AppColors.textPrimary),
      ),
    );
  }
}
