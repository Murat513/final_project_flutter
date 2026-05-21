import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/orders_table.dart';

part 'orders_dao.g.dart';

@DriftAccessor(tables: [OrdersTable, OrderItemsTable])
class OrdersDao extends DatabaseAccessor<AppDatabase> with _$OrdersDaoMixin {
  OrdersDao(super.db);

  // ── Orders ──────────────────────────────────────────────────────────────

  /// Watch all orders sorted by newest first (reactive stream).
  Stream<List<OrdersTableData>> watchAllOrders() {
    return (select(ordersTable)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  /// Fetch all orders once, newest first.
  Future<List<OrdersTableData>> getAllOrders() {
    return (select(ordersTable)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// Get a single order by its local [id].
  Future<OrdersTableData?> getOrderById(int id) {
    return (select(ordersTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Get a single order by its Firestore [firestoreId].
  Future<OrdersTableData?> getOrderByFirestoreId(String firestoreId) {
    return (select(ordersTable)
      ..where((t) => t.firestoreId.equals(firestoreId)))
        .getSingleOrNull();
  }

  /// Insert a new order and return its auto-incremented local id.
  Future<int> insertOrder(OrdersTableCompanion order) {
    return into(ordersTable).insert(order);
  }

  /// Update an existing order (e.g. status change after sync).
  Future<bool> updateOrder(OrdersTableCompanion order) {
    return update(ordersTable).replace(order);
  }

  /// Delete a single order by local [id].
  Future<int> deleteOrder(int id) {
    return (delete(ordersTable)..where((t) => t.id.equals(id))).go();
  }

  /// Watch orders filtered by [status] (e.g. 'pending', 'shipped').
  Stream<List<OrdersTableData>> watchOrdersByStatus(String status) {
    return (select(ordersTable)
      ..where((t) => t.status.equals(status))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  // ── Order Items ──────────────────────────────────────────────────────────

  /// Fetch all items belonging to a given [orderId].
  Future<List<OrderItemsTableData>> getItemsForOrder(int orderId) {
    return (select(orderItemsTable)
      ..where((t) => t.orderId.equals(orderId)))
        .get();
  }

  /// Watch items for a given [orderId] as a reactive stream.
  Stream<List<OrderItemsTableData>> watchItemsForOrder(int orderId) {
    return (select(orderItemsTable)
      ..where((t) => t.orderId.equals(orderId)))
        .watch();
  }

  /// Insert a single order item.
  Future<int> insertOrderItem(OrderItemsTableCompanion item) {
    return into(orderItemsTable).insert(item);
  }

  /// Batch-insert a list of order items for a newly created order.
  Future<void> insertOrderItems(List<OrderItemsTableCompanion> items) async {
    await batch((b) => b.insertAll(orderItemsTable, items));
  }

  /// Delete all items for a given [orderId] (used when deleting an order).
  Future<int> deleteItemsForOrder(int orderId) {
    return (delete(orderItemsTable)
      ..where((t) => t.orderId.equals(orderId)))
        .go();
  }

  // ── Transactions ─────────────────────────────────────────────────────────

  /// Atomically create an order together with all its items.
  ///
  /// Returns the local id of the newly created order.
  Future<int> createOrderWithItems({
    required OrdersTableCompanion order,
    required List<OrderItemsTableCompanion> items,
  }) async {
    return transaction(() async {
      final orderId = await insertOrder(order);
      final itemsWithOrderId = items
          .map((item) => item.copyWith(orderId: Value(orderId)))
          .toList();
      await insertOrderItems(itemsWithOrderId);
      return orderId;
    });
  }

  /// Atomically delete an order and all its items.
  Future<void> deleteOrderWithItems(int orderId) async {
    await transaction(() async {
      await deleteItemsForOrder(orderId);
      await deleteOrder(orderId);
    });
  }
}