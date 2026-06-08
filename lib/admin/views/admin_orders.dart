import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/order.dart';
import '../../providers/admin_provider.dart';
import 'admin_order_detail.dart';

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
    final roleValue = ref
        .read(roleProvider)
        .maybeWhen(data: (role) => role.name, orElse: () => 'unknown');
    final isAdmin = roleValue == 'admin' || roleValue == 'superadmin';
    ref
        .read(adminDebugLogsProvider.notifier)
        .add(
          'Order status update requested for $orderId to $status by uid=$uid role=$roleValue isAdmin=$isAdmin',
        );
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
                final filteredOrders = orders
                    .where((order) {
                      if (_status != 'all' &&
                          order.status.toLowerCase() != _status) {
                        return false;
                      }
                      if (searchValue.isEmpty) return true;
                      return order.orderId.toLowerCase().contains(
                            searchValue,
                          ) ||
                          order.userId.toLowerCase().contains(searchValue);
                    })
                    .toList(growable: false);

                if (filteredOrders.isEmpty) {
                  return Center(
                    child: Text(
                      'No orders match the current search or filter.',
                      style: AppTextStyles.body,
                    ),
                  );
                }

                final deliveredRevenue = filteredOrders
                    .where((order) => order.status.toLowerCase() == 'delivered')
                    .fold<int>(0, (sum, order) => sum + order.totalPrice);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_status == 'delivered')
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
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
                                    fontSize: 28,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: ListView.separated(
                        itemCount: filteredOrders.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final order = filteredOrders[index];
                          return _OrderCard(
                            order: order,
                            isSaving: _savingOrders.contains(order.orderId),
                            onStatusChanged: (newStatus) =>
                                _updateOrderStatus(order.orderId, newStatus),
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

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.isSaving,
    required this.onStatusChanged,
  });

  final AppOrder order;
  final bool isSaving;
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        title: Text(
          order.orderId,
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.xs),
            Text('User: ${order.userId}', style: AppTextStyles.label),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Payment: ${order.paymentStatus} • ${order.paymentMethod}',
              style: AppTextStyles.body,
            ),
          ],
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DropdownButton<String>(
              value: _normalizeStatus(order.status),
              items: const [
                DropdownMenuItem(value: 'pending', child: Text('Pending')),
                DropdownMenuItem(
                  value: 'processing',
                  child: Text('Processing'),
                ),
                DropdownMenuItem(value: 'delivered', child: Text('Delivered')),
              ],
              onChanged: isSaving
                  ? null
                  : (value) {
                      if (value != null) {
                        onStatusChanged(value);
                      }
                    },
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '৳${NumberFormat.decimalPattern().format(order.totalPrice)}',
              style: AppTextStyles.headingMedium.copyWith(fontSize: 18),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${order.createdAt.toLocal()}'.split(' ').first,
              style: AppTextStyles.label,
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AdminOrderDetail(order: order)),
          );
        },
      ),
    );
  }
}
