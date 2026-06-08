import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.imagePath,
    required this.name,
    required this.price,
    required this.wishlisted,
    required this.onWishlistToggle,
    this.available = true,
    this.onAddToCart,
  });

  final String imagePath;
  final String name;
  final String price;
  final bool wishlisted;
  final bool available;
  final VoidCallback onWishlistToggle;
  final VoidCallback? onAddToCart;

  static final Map<String, Future<String>> _assetPathCache = {};

  static Future<String> _resolveAssetPath(String imagePath) {
    final normalizedPath = _normalizeAssetPath(imagePath);

    return _assetPathCache.putIfAbsent(normalizedPath, () async {
      if (normalizedPath.isEmpty) {
        return normalizedPath;
      }

      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final assets = manifest.listAssets();

      if (assets.contains(normalizedPath)) {
        return normalizedPath;
      }

      final lowerPath = normalizedPath.toLowerCase();
      for (final asset in assets) {
        if (_normalizeAssetPath(asset).toLowerCase() == lowerPath) {
          return asset;
        }
      }

      final fileName = lowerPath.split('/').last;
      final fileNameMatches = assets
          .where((asset) => asset.toLowerCase().endsWith('/$fileName'))
          .toList();

      if (fileNameMatches.length == 1) {
        return fileNameMatches.single;
      }

      debugPrint('IMAGE ASSET NOT FOUND IN MANIFEST');
      debugPrint('Firestore path: $imagePath');
      debugPrint('Normalized path: $normalizedPath');
      return normalizedPath;
    });
  }

  static String _normalizeAssetPath(String imagePath) {
    var path = imagePath.trim().replaceAll(r'\', '/');

    while (path.startsWith('/')) {
      path = path.substring(1);
    }

    if (path.startsWith('assets/')) {
      path = path.substring('assets/'.length);
    }

    return path;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  child: SizedBox.expand(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.sm,
                        AppSpacing.md,
                        AppSpacing.sm,
                        AppSpacing.xs,
                      ),
                      child: Image.asset(
                        imagePath,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return FutureBuilder<String>(
                            future: _resolveAssetPath(imagePath),
                            builder: (context, snapshot) {
                              final resolvedPath = snapshot.data;

                              if (resolvedPath == null ||
                                  resolvedPath == imagePath) {
                                debugPrint('IMAGE LOAD FAILED');
                                debugPrint('Path: $imagePath');
                                debugPrint('Error: $error');
                                return const Center(
                                  child: Icon(Icons.broken_image, size: 48),
                                );
                              }

                              return Image.asset(
                                resolvedPath,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  debugPrint('IMAGE LOAD FAILED');
                                  debugPrint('Path: $resolvedPath');
                                  debugPrint('Original path: $imagePath');
                                  debugPrint('Error: $error');
                                  return const Center(
                                    child: Icon(Icons.broken_image, size: 48),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: AppSpacing.sm,
                  left: AppSpacing.sm,
                  child: available
                      ? const SizedBox.shrink()
                      : Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'OUT',
                            style: AppTextStyles.label.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ),
                ),
                Positioned(
                  top: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: InkWell(
                    onTap: onWishlistToggle,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withAlpha(220),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadow,
                            blurRadius: 10,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        wishlisted ? Icons.favorite : Icons.favorite_border,
                        color: wishlisted
                            ? AppColors.error
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            price,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.headingMedium.copyWith(
                              fontSize: 18,
                              color: AppColors.backgroundDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Container(
                      decoration: BoxDecoration(
                        color: available ? AppColors.accent : AppColors.border,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadow,
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: IconButton(
                        tooltip: 'Add to cart',
                        onPressed: available ? onAddToCart : null,
                        icon: Icon(
                          Icons.add,
                          color: available
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                        iconSize: 20,
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(
                          minWidth: 34,
                          minHeight: 34,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
