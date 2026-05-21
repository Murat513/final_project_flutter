import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io' show Platform;
import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/orders_dao.dart';
import '../../../../core/errors.dart';
import '../../../favorites/presentation/providers/favorites_provider.dart';
import '../models/order_model.dart';

abstract interface class IOrderRepository {
  Stream<List<OrderModel>> watchOrders(String userId);
  Future<OrderModel?> getOrderById(int localId);
  Future<int> placeOrder({
    required String userId,
    required double totalAmount,
    required List<OrderItemModel> items,
  });
  Future<void> syncOrderToFirestore(int localId);
  Future<void> updateStatus(int localId, String status);
  Future<void> deleteOrder(int localId);
}

class OrderRepository implements IOrderRepository {
  OrderRepository({
    required OrdersDao ordersDao,
    required FirebaseFirestore firestore,
  })  : _dao = ordersDao,
        _firestore = firestore;

  final OrdersDao _dao;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('orders');

  @override
  Stream<List<OrderModel>> watchOrders(String userId) {
    // Добавлена защита .distinct() для предотвращения лишних перерисовок
    return _dao.watchAllOrders().distinct().asyncMap((rows) async {
      print("DEBUG: Получено строк из БД: ${rows.length}"); // <--- Проверьте консоль
      final userRows = rows.where((r) => r.userId == userId).toList();
      final orders = <OrderModel>[];

      for (final row in userRows) {
        try {
          final itemRows = await _dao.getItemsForOrder(row.id);
          orders.add(OrderModel.fromTableData(row, itemRows));
        } catch (e) {
          // Если возникла ошибка при чтении товаров одного заказа,
          // продолжаем цикл, чтобы не "ронять" весь список
          continue;
        }
      }
      return orders;
    });
  }

  @override
  Future<OrderModel?> getOrderById(int localId) async {
    try {
      final row = await _dao.getOrderById(localId);
      if (row == null) return null;
      final itemRows = await _dao.getItemsForOrder(localId);
      return OrderModel.fromTableData(row, itemRows);
    } catch (e) {
      throw DatabaseException(e.toString());
    }
  }

  @override
  Future<int> placeOrder({
    required String userId,
    required double totalAmount,
    required List<OrderItemModel> items,
  }) async {
    try {
      final now = DateTime.now();
      final orderCompanion = OrdersTableCompanion.insert(
        userId: userId,
        totalAmount: totalAmount,
        createdAt: Value(now),
        updatedAt: Value(now),
      );
      final itemCompanions = items
          .map(
            (i) => OrderItemsTableCompanion.insert(
          orderId: 0,
          productId: i.productId,
          title: i.title,
          image: i.image,
          price: i.price,
          quantity: Value(i.quantity),
          category: i.category,
        ),
      )
          .toList();
      return await _dao.createOrderWithItems(
        order: orderCompanion,
        items: itemCompanions,
      );
    } catch (e) {
      throw DatabaseException(e.toString());
    }
  }

  @override
  Future<void> syncOrderToFirestore(int localId) async {
    try {
      final order = await getOrderById(localId);
      if (order == null) return;

      if (Platform.isWindows) {
        await _dao.updateOrder(
          OrdersTableCompanion(
            id: Value(localId),
            firestoreId: const Value('mock_id_windows'),
            updatedAt: Value(DateTime.now()),
          ),
        );
        return;
      }

      final docRef = order.firestoreId != null
          ? _col.doc(order.firestoreId)
          : _col.doc();

      // Добавлен тайм-аут на запись в Firebase
      await docRef.set(order.toFirestore()).timeout(const Duration(seconds: 10));

      await _dao.updateOrder(
        OrdersTableCompanion(
          id: Value(localId),
          firestoreId: Value(docRef.id),
          updatedAt: Value(DateTime.now()),
        ),
      );
    } catch (e) {
      throw DatabaseException(e.toString());
    }
  }

  @override
  Future<void> updateStatus(int localId, String status) async {
    try {
      final row = await _dao.getOrderById(localId);
      if (row == null) return;

      await _dao.updateOrder(
        OrdersTableCompanion(
          id: Value(localId),
          status: Value(status),
          updatedAt: Value(DateTime.now()),
        ),
      );

      if (row.firestoreId != null) {
        await _col.doc(row.firestoreId).update({
          'status': status,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      throw DatabaseException(e.toString());
    }
  }

  @override
  Future<void> deleteOrder(int localId) async {
    try {
      final row = await _dao.getOrderById(localId);
      if (row?.firestoreId != null) {
        await _col.doc(row!.firestoreId).delete();
      }
      await _dao.deleteOrderWithItems(localId);
    } catch (e) {
      throw DatabaseException(e.toString());
    }
  }
}

final orderRepositoryProvider = Provider<IOrderRepository>((ref) {
  return OrderRepository(
    ordersDao: ref.watch(appDatabaseProvider).ordersDao,
    firestore: FirebaseFirestore.instance,
  );
});