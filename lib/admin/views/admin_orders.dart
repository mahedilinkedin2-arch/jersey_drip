import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/admin_provider.dart';

String _normalizeStatus(String status) {
  final normalized = status.toLowerCase();
  const allowedStatuses = ['pending', 'processing', 'delivered'];
  if (allowedStatuses.contains(normalized)) return normalized;
  return 'pending';
}

class AdminOrders extends ConsumerStatefulWidget {
  const AdminOrders({super.key});

  @override
  ConsumerState<AdminOrders> createState() => _AdminOrdersState();
}

class _AdminOrdersState extends ConsumerState<AdminOrders> {
  final _searchController = TextEditingController();
  String _status = 'all';
  final Set<String> _savingOrders = {};

  static const _statusOptions = ['all', 'pending', 'processing', 'delivered'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _updateOrderStatus(String orderId, String status) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
    final roleValue = await ref
        .read(adminServiceProvider)
        .fetchUserProfile(uid)
        .then((p) => p?.role ?? 'unknown')
        .catchError((_) => 'unknown');
    final isAdmin = roleValue == 'admin' || roleValue == 'superadmin';
    ref
        .read(adminDebugLogsProvider.notifier)
        .add(
          'Order status update requested for $orderId to $status by uid=$uid role=$roleValue isAdmin=$isAdmin',
        );

    if (!isAdmin) {
      ref
          .read(adminDebugLogsProvider.notifier)
          .add('Order update aborted: not an admin');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission denied: admin only.')),
        );
      }
      return;
    }

    setState(() => _savingOrders.add(orderId));
    try {
      await ref.read(adminServiceProvider).updateOrderStatus(orderId, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Order updated to ${status[0].toUpperCase()}${status.substring(1)}',
            ),
          ),
        );
      }
    } catch (error) {
      ref
          .read(adminDebugLogsProvider.notifier)
          .add('Order update failed: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update order: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _savingOrders.remove(orderId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersProvider);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Order management', style: AppTextStyles.headingMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Search, filter, and update order status from a single place.',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Search orders',
                    hintText: 'Search by order ID or customer ID',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              DropdownButton<String>(
                value: _status,
                items: _statusOptions
                    .map(
                      (status) => DropdownMenuItem(
                        value: status,
                        child: Text(
                          status == 'all'
                              ? 'All'
                              : status[0].toUpperCase() + status.substring(1),
                        ),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _status = value);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: ordersAsync.when(
              data: (orders) {
                final searchValue = _searchController.text.trim().toLowerCase();
                final filtered = orders
                    .where((order) {
                      if (searchValue.isEmpty) return true;
                      return order.orderId.toLowerCase().contains(
                            searchValue,
                          ) ||
                          order.userId.toLowerCase().contains(searchValue);
                    })
                    .toList(growable: false);

                final activeOrders = filtered
                    .where(
                      (o) =>
                          o.status.toLowerCase() == 'pending' ||
                          o.status.toLowerCase() == 'processing',
                    )
                    .toList(growable: false);

                final deliveredOrders = filtered
                    .where((o) => o.status.toLowerCase() == 'delivered')
                    .toList(growable: false);

                if (activeOrders.isEmpty && deliveredOrders.isEmpty) {
                  return Center(
                    child: Text(
                      'No orders match the current search or filter.',
                      style: AppTextStyles.body,
                    ),
                  );
                }

                final deliveredRevenue = deliveredOrders.fold<int>(
                  0,
                  (sum, order) => sum + order.totalPrice,
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Active Orders
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Text(
                        'Active orders',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: activeOrders.isEmpty
                          ? Center(
                              child: Text(
                                'No active orders',
                                style: AppTextStyles.body,
                              ),
                            )
                          : ListView.separated(
                              itemCount: activeOrders.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: AppSpacing.sm),
                              itemBuilder: (context, index) {
                                final order = activeOrders[index];
                                return Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                  child: ListTile(
                                    title: Text(
                                      order.orderId,
                                      style: AppTextStyles.body.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    trailing: DropdownButton<String>(
                                      value: _normalizeStatus(order.status),
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'pending',
                                          child: Text('Pending'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'processing',
                                          child: Text('Processing'),
                                        ),
                                      ],
                                      onChanged:
                                          _savingOrders.contains(order.orderId)
                                          ? null
                                          : (value) {
                                              if (value != null) {
                                                _updateOrderStatus(
                                                  order.orderId,
                                                  value,
                                                );
                                              }
                                            },
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Delivered Orders - read-only history
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Text(
                        'Delivered orders',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Delivered revenue',
                                style: AppTextStyles.body.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.color,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                '৳${NumberFormat.decimalPattern().format(deliveredRevenue)}',
                                style: AppTextStyles.headingMedium.copyWith(
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: deliveredOrders.isEmpty
                          ? Center(
                              child: Text(
                                'No delivered orders',
                                style: AppTextStyles.body,
                              ),
                            )
                          : ListView.separated(
                              itemCount: deliveredOrders.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: AppSpacing.sm),
                              itemBuilder: (context, index) {
                                final order = deliveredOrders[index];
                                return Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 1,
                                  child: ListTile(
                                    title: Text(
                                      order.orderId,
                                      style: AppTextStyles.body.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    trailing: Text(
                                      'Delivered',
                                      style: AppTextStyles.label,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text(
                  'Unable to load orders: ${error.toString()}',
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
