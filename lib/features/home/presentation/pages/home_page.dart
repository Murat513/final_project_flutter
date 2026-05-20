import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../catalog/data/models/product_model.dart';
import '../../../catalog/presentation/providers/catalog_provider.dart';
import '../../../catalog/presentation/widgets/product_card.dart';
import '../../../favorites/presentation/providers/favorites_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allProductsAsync = ref.watch(allProductsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Marketplace'),
            floating: true,
            snap: true,
            actions: [
              IconButton(
                tooltip: 'Favorites',
                icon: const Icon(Icons.favorite_border_rounded),
                onPressed: () => context.go(AppRoutes.favorites),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: _PromoBanner(),
          ),
          SliverToBoxAdapter(
            child: _SectionHeader(
              title: 'Categories',
              onSeeAll: () => context.go(AppRoutes.catalog),
            ),
          ),
          SliverToBoxAdapter(
            child: categoriesAsync.when(
              loading: () => const SizedBox(
                height: 88,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const SizedBox.shrink(),
              data: (categories) => _CategoryRow(categories: categories),
            ),
          ),
          SliverToBoxAdapter(
            child: _SectionHeader(
              title: 'Featured Products',
              onSeeAll: () => context.go(AppRoutes.catalog),
            ),
          ),
          allProductsAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: SizedBox(
                height: 220,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (err, _) => SliverToBoxAdapter(
              child: _ErrorView(
                message: err.toString(),
                onRetry: () => ref.invalidate(allProductsProvider),
              ),
            ),
            data: (products) {
              final featured = products.take(6).toList();
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.68,
                  ),
                  delegate: SliverChildBuilderDelegate(
                        (context, index) => ProductCard(product: featured[index]),
                    childCount: featured.length,
                  ),
                ),
              );
            },
          ),
          SliverToBoxAdapter(
            child: _SectionHeader(
              title: 'Your Favorites',
              onSeeAll: () => context.go(AppRoutes.favorites),
            ),
          ),
          SliverToBoxAdapter(
            child: _FavoritesPreview(),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        // Жесткая высота удалена. Контейнер расширяется под любой размер текста.
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              colorScheme.primaryContainer,
              colorScheme.secondaryContainer,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                Icons.local_offer_rounded,
                size: 160,
                color: colorScheme.primary.withOpacity(0.08),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'New Arrivals',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Explore the latest\ntrends & deals',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => context.go(AppRoutes.catalog),
                    child: const Text('Shop Now'),
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

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.categories});

  final List<String> categories;

  static const _icons = <String, IconData>{
    'electronics': Icons.devices_rounded,
    "men's clothing": Icons.male_rounded,
    "women's clothing": Icons.female_rounded,
    'jewelery': Icons.diamond_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      height: 88,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = categories[index];
          final icon = _icons[category.toLowerCase()] ?? Icons.category_rounded;
          final label = _capitalize(category);

          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              context.go(AppRoutes.catalog);
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: colorScheme.onPrimaryContainer),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 62,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

class _FavoritesPreview extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoritesListProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return favoritesAsync.when(
      loading: () => const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (favorites) {
        if (favorites.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              height: 90,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite_border_rounded,
                        color: colorScheme.outlineVariant),
                    const SizedBox(width: 8),
                    Text(
                      'No favorites saved yet',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final preview = favorites.take(5).toList();
        return SizedBox(
          height: 100,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: preview.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final item = preview[index];
              return GestureDetector(
                onTap: () =>
                    context.go('${AppRoutes.catalog}/${item.productId}'),
                child: Container(
                  width: 80,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Image.network(
                    item.image,
                    fit: BoxFit.contain,
                    loadingBuilder: (_, child, progress) =>
                    progress == null ? child : const SizedBox.shrink(),
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.broken_image_outlined,
                      size: 32,
                      color: colorScheme.outlineVariant,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onSeeAll});

  final String title;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 8, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          TextButton(
            onPressed: onSeeAll,
            child: const Text('See all'),
          ),
        ],
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
    return SizedBox(
      height: 160,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded,
                size: 40, color: theme.colorScheme.error),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
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