import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/database/app_database.dart';
import '../../../../../core/database/daos/cart_dao.dart';
import '../../../catalog/data/models/product_model.dart';
import '../../../favorites/presentation/providers/favorites_provider.dart';

final cartDaoProvider = Provider<CartDao>((ref) {
  return ref.watch(appDatabaseProvider).cartDao;
});

final cartItemsProvider = StreamProvider<List<CartItemsTableData>>((ref) {
  return ref.watch(cartDaoProvider).watchAllCartItems();
});

final cartItemCountProvider = Provider<int>((ref) {
  final items = ref.watch(cartItemsProvider).value ?? [];
  return items.fold(0, (sum, item) => sum + item.quantity);
});

final cartTotalProvider = Provider<double>((ref) {
  final items = ref.watch(cartItemsProvider).value ?? [];
  return items.fold(0.0, (sum, item) => sum + item.price * item.quantity);
});

final isInCartProvider = Provider.family<bool, int>((ref, productId) {
  final items = ref.watch(cartItemsProvider).value ?? [];
  return items.any((item) => item.productId == productId);
});

class CartNotifier extends AsyncNotifier<void> {
  CartDao get _dao => ref.read(cartDaoProvider);

  @override
  Future<void> build() async {}

  Future<void> addItem(ProductModel product) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final companion = CartItemsTableCompanion.insert(
        productId: product.id,
        title: product.title,
        image: product.image,
        price: product.price,
        category: product.category,
      );
      await _dao.upsertCartItem(companion);
    });
  }

  Future<void> increment(int productId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _dao.incrementQuantity(productId));
  }

  Future<void> decrement(int productId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _dao.decrementQuantity(productId));
  }

  Future<void> remove(int productId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _dao.removeCartItem(productId));
  }

  Future<void> clear() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _dao.clearCart());
  }
}

final cartNotifierProvider =
AsyncNotifierProvider<CartNotifier, void>(CartNotifier.new);