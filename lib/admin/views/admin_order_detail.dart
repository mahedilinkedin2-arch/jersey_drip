import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/order.dart';
import '../../models/user_profile.dart';
import '../../providers/admin_provider.dart';

class AdminOrderDetail extends ConsumerStatefulWidget {
  const AdminOrderDetail({super.key, required this.order});

  final AppOrder order;

  @override
  ConsumerState<AdminOrderDetail> createState() => _AdminOrderDetailState();
}

class _AdminOrderDetailState extends ConsumerState<AdminOrderDetail> {
  late String _status;
  bool _saving = false;

  static const statusOptions = ['pending', 'processing', 'delivered'];

  @override
  void initState() {
    super.initState();
    _status = widget.order.status.toLowerCase();
    if (!statusOptions.contains(_status)) {
      _status = 'pending';
    }
  }

  Future<void> _saveStatus() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(adminServiceProvider)
          .updateOrderStatus(widget.order.orderId, _status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order status updated successfully.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<UserProfile?> _fetchCustomer() {
    if (widget.order.userId.isEmpty) {
      return Future.value(null);
    }
    return ref.read(adminServiceProvider).fetchUserProfile(widget.order.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: AppColors.deepBlue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Order ${widget.order.orderId}',
                style: AppTextStyles.headingMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              FutureBuilder<UserProfile?>(
                future: _fetchCustomer(),
                builder: (context, snapshot) {
                  final customer = snapshot.data;
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Customer', style: AppTextStyles.label),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            customer?.name ?? widget.order.userId,
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            customer?.email ?? 'No email stored',
                            style: AppTextStyles.body,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Joined: ${customer?.createdAt?.toLocal().toString().split(' ').first ?? 'Unknown'}',
                            style: AppTextStyles.label,
                          ),
                          if (snapshot.connectionState ==
                              ConnectionState.waiting)
                            const Padding(
                              padding: EdgeInsets.only(top: AppSpacing.sm),
                              child: LinearProgressIndicator(),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              _SectionTitle(title: 'Items'),
              const SizedBox(height: AppSpacing.sm),
              ...widget.order.items.map((item) => _OrderItemRow(item: item)),
              const SizedBox(height: AppSpacing.lg),
              _SectionTitle(title: 'Order summary'),
              const SizedBox(height: AppSpacing.sm),
              _DetailRow(
                label: 'Total amount',
                value: '\$${widget.order.totalPrice}',
              ),
              _DetailRow(
                label: 'Payment status',
                value: widget.order.paymentStatus,
              ),
              _DetailRow(
                label: 'Payment method',
                value: widget.order.paymentMethod,
              ),
              _DetailRow(
                label: 'Transaction ID',
                value: widget.order.transactionId,
              ),
              _DetailRow(
                label: 'Date',
                value: '${widget.order.createdAt.toLocal()}'.split(' ').first,
              ),
              const SizedBox(height: AppSpacing.lg),
              _SectionTitle(title: 'Order status'),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _status,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: statusOptions
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(status.capitalize()),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value != null) setState(() => _status = value);
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  ElevatedButton(
                    onPressed: _saving ? null : _saveStatus,
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({required this.item});

  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            if (item.imagePath.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  item.imagePath,
                  width: 68,
                  height: 68,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 68,
                    height: 68,
                    color: AppColors.backgroundLight,
                    child: const Icon(Icons.image_not_supported),
                  ),
                ),
              ),
            if (item.imagePath.isNotEmpty) const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  if (item.size.isNotEmpty)
                    Text('Size: ${item.size}', style: AppTextStyles.label),
                  Text('Qty: ${item.quantity}', style: AppTextStyles.label),
                  Text(
                    'Line total: \$${item.totalPrice}',
                    style: AppTextStyles.body,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.label),
          Text(
            value,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.headingMedium.copyWith(fontSize: 20),
    );
  }
}

extension on String {
  String capitalize() {
    if (isEmpty) return this;
    return substring(0, 1).toUpperCase() + substring(1);
  }
}
