import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_router.dart';
import '../providers/cart_provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/cart_item_tile.dart';
import '../../../orders/presentation/providers/orders_provider.dart';

class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsync = ref.watch(cartItemsProvider);
    final total = ref.watch(cartTotalProvider);
    final ordersState = ref.watch(ordersNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
        actions: [
          cartAsync.maybeWhen(
            data: (items) => items.isNotEmpty
                ? TextButton.icon(
              onPressed: () => _confirmClear(context, ref),
              icon: const Icon(Icons.delete_sweep_outlined),
              label: const Text('Clear'),
            )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: cartAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(message: e.toString()),
        data: (items) {
          if (items.isEmpty) return const _EmptyCartView();
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.only(top: 8, bottom: 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (_, index) => CartItemTile(item: items[index]),
                    childCount: items.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomSheet: cartAsync.maybeWhen(
        data: (items) => items.isNotEmpty
            ? _CheckoutSheet(
          total: total,
          isLoading: ordersState.isLoading,
          onCheckout: () => _placeOrder(context, ref),
        )
            : null,
        orElse: () => null,
      ),
    );
  }

  Future<void> _placeOrder(BuildContext context, WidgetRef ref) async {
    await ref.read(ordersNotifierProvider.notifier).placeOrderFromCart();
    final state = ref.read(ordersNotifierProvider);
    if (!context.mounted) return;
    state.when(
      data: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order placed successfully!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go(AppRoutes.orders);
      },
      error: (e, _) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to place order: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      ),
      loading: () {},
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear cart?'),
        content: const Text('All items will be removed from your cart.'),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => ctx.pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(cartNotifierProvider.notifier).clear();
    }
  }
}

class _CheckoutSheet extends StatelessWidget {
  const _CheckoutSheet({
    required this.total,
    required this.isLoading,
    required this.onCheckout,
  });

  final double total;
  final bool isLoading;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: FilledButton(
                  onPressed: isLoading ? null : onCheckout,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text('Place Order'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCartView extends StatelessWidget {
  const _EmptyCartView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: theme.colorScheme.onSurface.withOpacity(0.25),
          ),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => GoRouter.of(context).go(AppRoutes.catalog),
            child: const Text('Browse catalog'),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 56,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}