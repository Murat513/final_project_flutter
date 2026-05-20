import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/product_model.dart';
import '../providers/catalog_provider.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../favorites/presentation/providers/favorites_provider.dart';

class ProductDetailPage extends ConsumerWidget {
  const ProductDetailPage({super.key, required this.productId});

  final int productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productDetailProvider(productId));

    return productAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(),
        body: _ErrorView(
          message: err.toString(),
          onRetry: () => ref.invalidate(productDetailProvider(productId)),
        ),
      ),
      data: (product) => _ProductDetailView(product: product),
    );
  }
}

class _ProductDetailView extends ConsumerWidget {
  const _ProductDetailView({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isFavAsync = ref.watch(isFavoriteProvider(product.id));
    final isFav = isFavAsync.value ?? false;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 340,
            pinned: true,
            actions: [
              IconButton(
                tooltip: isFav ? 'Remove from favorites' : 'Add to favorites',
                icon: Icon(
                  isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isFav ? Colors.redAccent : null,
                ),
                onPressed: () =>
                    ref.read(favoritesNotifierProvider.notifier).toggle(product),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: ColoredBox(
                color: colorScheme.surfaceContainerLowest,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Image.network(
                    product.image,
                    fit: BoxFit.contain,
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : const Center(child: CircularProgressIndicator()),
                    errorBuilder: (_, __, ___) => Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 64,
                        color: colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.category.toUpperCase(),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.title,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      _RatingChip(
                        rating: product.rating,
                        count: product.ratingCount,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    'Description',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _AddToCartBar(product: product),
    );
  }
}

class _RatingChip extends StatelessWidget {
  const _RatingChip({required this.rating, required this.count});

  final double rating;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 16, color: Colors.amber.shade700),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.amber.shade900,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '($count)',
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.amber.shade800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddToCartBar extends ConsumerWidget {
  const _AddToCartBar({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final inCart = ref.watch(isInCartProvider(product.id));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: inCart
                      ? theme.colorScheme.secondaryContainer
                      : theme.colorScheme.primary,
                  foregroundColor: inCart
                      ? theme.colorScheme.onSecondaryContainer
                      : theme.colorScheme.onPrimary,
                ),
                icon: Icon(
                  inCart
                      ? Icons.shopping_cart_checkout_rounded
                      : Icons.add_shopping_cart_rounded,
                ),
                label: Text(inCart ? 'Added to Cart' : 'Add to Cart'),
                onPressed: inCart
                    ? null
                    : () {
                  ref
                      .read(cartNotifierProvider.notifier)
                      .addItem(product);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Added to cart'),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                      action: SnackBarAction(
                        label: 'OK',
                        onPressed: () {},
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded,
                size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text('Something went wrong', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}