import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/favorite_items_table.dart';

part 'favorites_dao.g.dart';

@DriftAccessor(tables: [FavoriteItemsTable])
class FavoritesDao extends DatabaseAccessor<AppDatabase>
    with _$FavoritesDaoMixin {
  FavoritesDao(super.db);

  Stream<List<FavoriteItemsTableData>> watchAllFavorites() {
    return select(favoriteItemsTable).watch();
  }

  Future<List<FavoriteItemsTableData>> getAllFavorites() {
    return select(favoriteItemsTable).get();
  }

  Future<void> addFavorite(FavoriteItemsTableCompanion item) async {
    await into(favoriteItemsTable).insertOnConflictUpdate(item);
  }

  Future<void> removeFavorite(int productId) async {
    await (delete(favoriteItemsTable)
      ..where((t) => t.productId.equals(productId)))
        .go();
  }

  Future<bool> toggleFavorite(FavoriteItemsTableCompanion item) async {
    final existing = await isFavorite(item.productId.value);
    if (existing) {
      await removeFavorite(item.productId.value);
      return false;
    } else {
      await addFavorite(item);
      return true;
    }
  }

  Future<bool> isFavorite(int productId) async {
    final result = await (select(favoriteItemsTable)
      ..where((t) => t.productId.equals(productId)))
        .getSingleOrNull();
    return result != null;
  }

  Stream<bool> watchIsFavorite(int productId) {
    return (select(favoriteItemsTable)
      ..where((t) => t.productId.equals(productId)))
        .watchSingleOrNull()
        .map((item) => item != null);
  }
}