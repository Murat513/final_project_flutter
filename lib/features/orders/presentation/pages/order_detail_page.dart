import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/order_model.dart';
import '../providers/orders_provider.dart';

class OrderDetailPage extends ConsumerWidget {
  const OrderDetailPage({super.key, required this.orderId});

  final String orderId;

  int get _localId => int.tryParse(orderId) ?? 0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(_localId));
    final notifier = ref.watch(ordersNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #$orderId'),
        actions: [
          orderAsync.whenOrNull(
            data: (order) {
              if (order == null || order.status == 'cancelled') return null;
              return PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'cancel') {
                    _confirmCancel(context, ref, order.id);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'cancel', child: Text('Cancel Order')),
                ],
              );
            },
          ) ?? const SizedBox.shrink(),
        ],
      ),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline,
                    size: 56, color: theme.colorScheme.error),
                const SizedBox(height: 12),
                Text(e.toString(),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ),
        data: (order) {
          if (order == null) {
            return const Center(child: Text('Order not found'));
          }
          return _OrderDetailBody(order: order, isMutating: notifier.isLoading);
        },
      ),
    );
  }

  Future<void> _confirmCancel(
      BuildContext context, WidgetRef ref, int localId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text(
          'Are you sure you want to cancel this order? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Order'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(ordersNotifierProvider.notifier).cancelOrder(localId);
    }
  }
}

class _OrderDetailBody extends StatelessWidget {
  const _OrderDetailBody({required this.order, required this.isMutating});

  final OrderModel order;
  final bool isMutating;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currencyFmt = NumberFormat.currency(symbol: '\$');
    final dateFmt = DateFormat('MMMM d, yyyy • h:mm a');

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionCard(
                      children: [
                        _InfoRow(
                          icon: Icons.tag,
                          label: 'Order ID',
                          value: '#${order.id}',
                        ),
                        _InfoRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Placed',
                          value: dateFmt.format(order.createdAt),
                        ),
                        _InfoRow(
                          icon: Icons.update_outlined,
                          label: 'Updated',
                          value: dateFmt.format(order.updatedAt),
                        ),
                        _InfoRow(
                          icon: Icons.local_shipping_outlined,
                          label: 'Status',
                          value: '',
                          trailing: _StatusBadge(status: order.status),
                        ),
                        if (order.firestoreId != null)
                          _InfoRow(
                            icon: Icons.cloud_done_outlined,
                            label: 'Cloud ID',
                            value: order.firestoreId!,
                            valueMaxLines: 1,
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Items (${order.itemCount})',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.separated(
                itemCount: order.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  return _OrderItemTile(item: order.items[index]);
                },
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _SectionCard(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Subtotal',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          currencyFmt.format(order.totalAmount),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          currencyFmt.format(order.totalAmount),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
        if (isMutating)
          const Positioned.fill(
            child: ColoredBox(
              color: Colors.black26,
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}

class _OrderItemTile extends StatelessWidget {
  const _OrderItemTile({required this.item});

  final OrderItemModel item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currencyFmt = NumberFormat.currency(symbol: '\$');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.image,
                width: 64,
                height: 64,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  width: 64,
                  height: 64,
                  color: colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.image_not_supported_outlined),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.category,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Qty: ${item.quantity}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        currencyFmt.format(item.subtotal),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
    this.valueMaxLines,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;
  final int? valueMaxLines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: trailing ??
                Text(
                  value,
                  maxLines: valueMaxLines,
                  overflow: valueMaxLines != null
                      ? TextOverflow.ellipsis
                      : TextOverflow.visible,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.end,
                ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = _color(status, Theme.of(context).colorScheme);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _color(String status, ColorScheme cs) {
    return switch (status) {
      'pending' => Colors.orange,
      'processing' => Colors.blue,
      'shipped' => Colors.indigo,
      'delivered' => Colors.green,
      'cancelled' => cs.error,
      _ => cs.outline,
    };
  }
}