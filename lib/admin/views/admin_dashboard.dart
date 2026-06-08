import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/admin_provider.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key, required this.onNavigate});

  final void Function(int sectionIndex) onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final currencyFormat = NumberFormat.currency(
      symbol: '৳',
      decimalDigits: 0,
      locale: 'en_US',
    );

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: dashboardAsync.when(
        data: (stats) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Store overview', style: AppTextStyles.headingMedium),
                const SizedBox(height: AppSpacing.md),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columnCount = (constraints.maxWidth / 240)
                        .floor()
                        .clamp(1, 4);
                    final cardWidth = min(
                      (constraints.maxWidth -
                              (columnCount - 1) * AppSpacing.sm) /
                          columnCount,
                      280.0,
                    );
                    final cards = [
                      _DashboardCard(
                        title: 'Revenue',
                        value: currencyFormat.format(stats.totalRevenue),
                        onTap: null,
                      ),
                      _DashboardCard(
                        title: 'Orders',
                        value: stats.totalOrders.toString(),
                        onTap: () => onNavigate(1),
                      ),
                      _DashboardCard(
                        title: 'Delivered',
                        value: stats.deliveredOrders.toString(),
                        onTap: () => onNavigate(1),
                      ),
                      _DashboardCard(
                        title: 'Products',
                        value: stats.totalProducts.toString(),
                        onTap: () => onNavigate(2),
                      ),
                      _DashboardCard(
                        title: 'Out of stock',
                        value: stats.outOfStockCount.toString(),
                        onTap: () => onNavigate(3),
                      ),
                      _DashboardCard(
                        title: 'Users',
                        value: stats.totalUsers.toString(),
                        onTap: () => onNavigate(4),
                      ),
                    ];

                    return Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: cards
                          .map(
                            (card) => SizedBox(width: cardWidth, child: card),
                          )
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'Unable to load dashboard statistics:\n${error.toString()}',
            textAlign: TextAlign.center,
            style: AppTextStyles.body,
          ),
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({required this.title, required this.value, this.onTap});

  final String title;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: SizedBox(
            height: 150,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  value,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headingMedium.copyWith(fontSize: 26),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
