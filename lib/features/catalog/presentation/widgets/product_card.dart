import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_router.dart';
import '../../data/models/product_model.dart';
import '../../../favorites/presentation/providers/favorites_provider.dart';
import '../../data/models/product_model.dart';

class ProductCard extends ConsumerWidget {
  const ProductCard({super.key, required this.product, this.onAddToCart});

  final ProductModel product;
  final VoidCallback? onAddToCart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isFavAsync = ref.watch(isFavoriteProvider(product.id));
    final isFav = isFavAsync.value ?? false;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('${AppRoutes.catalog}/${product.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(
                      product.image,
                      fit: BoxFit.contain,
                      loadingBuilder: (_, child, progress) => progress == null
                          ? child
                          : const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.broken_image_outlined, size: 40),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: _FavoriteButton(product: product, isFav: isFav),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
              child: Text(
                product.category.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.primary,
                  letterSpacing: 0.8,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                product.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.star_rounded,
                          size: 13, color: Colors.amber.shade600),
                      const SizedBox(width: 2),
                      Text(
                        product.rating.toStringAsFixed(1),
                        style: theme.textTheme.labelSmall,
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

class _FavoriteButton extends ConsumerWidget {
  const _FavoriteButton({required this.product, required this.isFav});

  final ProductModel product;
  final bool isFav;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.white.withOpacity(0.85),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () =>
            ref.read(favoritesNotifierProvider.notifier).toggle(product),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            size: 18,
            color: isFav ? Colors.redAccent : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}