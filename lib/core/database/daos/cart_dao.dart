import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/cart_items_table.dart';

part 'cart_dao.g.dart';

@DriftAccessor(tables: [CartItemsTable])
class CartDao extends DatabaseAccessor<AppDatabase> with _$CartDaoMixin {
  CartDao(super.db);

  Stream<List<CartItemsTableData>> watchAllCartItems() {
    return select(cartItemsTable).watch();
  }

  Future<List<CartItemsTableData>> getAllCartItems() {
    return select(cartItemsTable).get();
  }

  Future<void> upsertCartItem(CartItemsTableCompanion item) async {
    await into(cartItemsTable).insertOnConflictUpdate(item);
  }

  Future<void> incrementQuantity(int productId) async {
    final item = await (select(cartItemsTable)
      ..where((t) => t.productId.equals(productId)))
        .getSingleOrNull();

    if (item != null) {
      await (update(cartItemsTable)
        ..where((t) => t.productId.equals(productId)))
          .write(CartItemsTableCompanion(
        quantity: Value(item.quantity + 1),
      ));
    }
  }

  Future<void> decrementQuantity(int productId) async {
    final item = await (select(cartItemsTable)
      ..where((t) => t.productId.equals(productId)))
        .getSingleOrNull();

    if (item == null) return;

    if (item.quantity <= 1) {
      await removeCartItem(productId);
    } else {
      await (update(cartItemsTable)
        ..where((t) => t.productId.equals(productId)))
          .write(CartItemsTableCompanion(
        quantity: Value(item.quantity - 1),
      ));
    }
  }

  Future<void> removeCartItem(int productId) async {
    await (delete(cartItemsTable)
      ..where((t) => t.productId.equals(productId)))
        .go();
  }

  Future<void> clearCart() async {
    await delete(cartItemsTable).go();
  }

  Future<bool> isInCart(int productId) async {
    final result = await (select(cartItemsTable)
      ..where((t) => t.productId.equals(productId)))
        .getSingleOrNull();
    return result != null;
  }
}