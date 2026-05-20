import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/database/app_database.dart';
import '../../../../../core/database/daos/favorites_dao.dart';
import '../../../catalog/data/models/product_model.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final favoritesDaoProvider = Provider<FavoritesDao>((ref) {
  return ref.watch(appDatabaseProvider).favoritesDao;
});

final favoritesListProvider =
StreamProvider<List<FavoriteItemsTableData>>((ref) {
  return ref.watch(favoritesDaoProvider).watchAllFavorites();
});

final favoriteIdsProvider = Provider<Set<int>>((ref) {
  final asyncFavorites = ref.watch(favoritesListProvider);
  return asyncFavorites.maybeWhen(
    data: (items) => {for (final item in items) item.productId},
    orElse: () => {},
  );
});

final isFavoriteProvider =
StreamProvider.family<bool, int>((ref, productId) {
  return ref.watch(favoritesDaoProvider).watchIsFavorite(productId);
});

class FavoritesNotifier extends AsyncNotifier<void> {
  FavoritesDao get _dao => ref.read(favoritesDaoProvider);

  @override
  Future<void> build() async {}

  Future<bool> toggle(ProductModel product) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      final companion = FavoriteItemsTableCompanion.insert(
        productId: product.id,
        title: product.title,
        image: product.image,
        price: product.price,
        rating: product.rating,
        category: product.category,
      );
      return _dao.toggleFavorite(companion);
    });
    state = result.whenData((_) {});
    if (result is AsyncError) throw result.error!;
    return result.value ?? false;
  }

  Future<void> remove(int productId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _dao.removeFavorite(productId));
  }

  Future<void> clearAll() async {
    final dao = _dao;
    final all = await dao.getAllFavorites();
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      for (final item in all) {
        await dao.removeFavorite(item.productId);
      }
    });
  }
}

final favoritesNotifierProvider =
AsyncNotifierProvider<FavoritesNotifier, void>(FavoritesNotifier.new);