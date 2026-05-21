import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../data/models/order_model.dart';
import '../../data/repositories/order_repository.dart';

final ordersStreamProvider = StreamProvider<List<OrderModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  return ref.watch(orderRepositoryProvider).watchOrders(user.uid);
});

final orderDetailProvider =
FutureProvider.family<OrderModel?, int>((ref, localId) {
  return ref.watch(orderRepositoryProvider).getOrderById(localId);
});

class OrdersNotifier extends AsyncNotifier<void> {
  IOrderRepository get _repo => ref.read(orderRepositoryProvider);

  @override
  Future<void> build() async {}

  Future<void> placeOrderFromCart() async {
    final user = ref.read(currentUserProvider);
    if (user == null) throw Exception('Not authenticated');

    final cartItems = ref.read(cartItemsProvider).value ?? [];
    if (cartItems.isEmpty) throw Exception('Cart is empty');

    final total = ref.read(cartTotalProvider);

    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final items = cartItems
          .map(
            (c) => OrderItemModel(
          id: 0,
          orderId: 0,
          productId: c.productId,
          title: c.title,
          image: c.image,
          price: c.price,
          quantity: c.quantity,
          category: c.category,
        ),
      )
          .toList();

      final localId = await _repo.placeOrder(
        userId: user.uid,
        totalAmount: total,
        items: items,
      );

      try {
        await _repo.syncOrderToFirestore(localId).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception('Превышено время ожидания сервера (Firebase)');
          },
        );
      } catch (e) {
        debugPrint("Ошибка синхронизации с Firebase: $e");
        // Здесь можно решить: либо пробросить ошибку (rethrow),
        // либо оставить как есть, если локальная копия важнее
      }

      await ref.read(cartNotifierProvider.notifier).clear();
    });
  }

  Future<void> cancelOrder(int localId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
          () => _repo.updateStatus(localId, 'cancelled'),
    );
  }

  Future<void> deleteOrder(int localId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.deleteOrder(localId));
  }
}

final ordersNotifierProvider =
AsyncNotifierProvider<OrdersNotifier, void>(OrdersNotifier.new);

final orderCountProvider = Provider<int>((ref) {
  return ref.watch(ordersStreamProvider).value?.length ?? 0;
});