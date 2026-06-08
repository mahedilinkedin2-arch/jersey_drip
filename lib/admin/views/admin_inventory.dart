import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/product.dart';
import '../../providers/admin_provider.dart';

class AdminInventory extends ConsumerStatefulWidget {
  const AdminInventory({super.key});

  @override
  ConsumerState<AdminInventory> createState() => _AdminInventoryState();
}

class _AdminInventoryState extends ConsumerState<AdminInventory> {
  String _filter = 'all';
  final Map<String, TextEditingController> _stockControllers = {};
  bool _saving = false;

  TextEditingController _controllerFor(String key, int stock) {
    return _stockControllers.putIfAbsent(
      key,
      () => TextEditingController(text: stock.toString()),
    );
  }

  @override
  void dispose() {
    for (final controller in _stockControllers.values) {
      controller.dispose();
    }
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
          Text('Inventory management', style: AppTextStyles.headingMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'View and update stock across products and focus on out-of-stock variants.',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _FilterChip(
                label: 'All',
                selected: _filter == 'all',
                onTap: () => setState(() => _filter = 'all'),
              ),
              _FilterChip(
                label: 'Out of stock',
                selected: _filter == 'out',
                onTap: () => setState(() => _filter = 'out'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: productsAsync.when(
              data: (products) {
                final rows = _buildInventoryRows(products);
                if (rows.isEmpty) {
                  return Center(
                    child: Text(
                      'No matching inventory rows found.',
                      style: AppTextStyles.body,
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final row = rows[index];
                    final key = '${row.productId}::${row.size}';
                    final controller = _controllerFor(key, row.stock);

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    row.productName,
                                    style: AppTextStyles.body.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    'Size: ${row.size}',
                                    style: AppTextStyles.label,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    'Current stock: ${row.stock}',
                                    style: AppTextStyles.body,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            SizedBox(
                              width: 90,
                              child: TextField(
                                controller: controller,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Stock',
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            ElevatedButton(
                              onPressed: _saving
                                  ? null
                                  : () async {
                                      final value =
                                          int.tryParse(
                                            controller.text.trim(),
                                          ) ??
                                          row.stock;
                                      if (value == row.stock) return;
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
                                            'Stock update requested for ${row.productId} size=${row.size} to $value by uid=$uid role=$roleValue isAdmin=$isAdmin',
                                          );
                                      setState(() => _saving = true);
                                      try {
                                        await ref
                                            .read(adminServiceProvider)
                                            .updateProductSizeStock(
                                              row.productId,
                                              row.size,
                                              value,
                                            );
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Stock updated successfully.',
                                              ),
                                            ),
                                          );
                                        }
                                      } catch (error) {
                                        ref
                                            .read(
                                              adminDebugLogsProvider.notifier,
                                            )
                                            .add('Stock update failed: $error');
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Failed to update stock: $error',
                                              ),
                                            ),
                                          );
                                        }
                                      } finally {
                                        if (mounted)
                                          setState(() => _saving = false);
                                      }
                                    },
                              child: _saving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Update'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text(
                  'Unable to load inventory: ${error.toString()}',
                  style: AppTextStyles.body,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_InventoryRow> _buildInventoryRows(List<Product> products) {
    final rows = <_InventoryRow>[];
    for (final product in products) {
      for (final entry in product.sizes.entries) {
        final stock = entry.value.stock;
        final row = _InventoryRow(
          productId: product.id,
          productName: product.name,
          size: entry.key,
          stock: stock,
        );

        if (_filter == 'out' && stock > 0) continue;
        rows.add(row);
      }
    }
    return rows;
  }
}

class _InventoryRow {
  const _InventoryRow({
    required this.productId,
    required this.productName,
    required this.size,
    required this.stock,
  });

  final String productId;
  final String productName;
  final String size;
  final int stock;
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: AppColors.deepBlue,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.textPrimary,
      ),
      onSelected: (_) => onTap(),
    );
  }
}
