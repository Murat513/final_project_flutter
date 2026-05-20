import 'package:drift/drift.dart';

/// Stores a placed order header (totals, status, Firestore sync id).
class OrdersTable extends Table {
  @override
  String get tableName => 'orders';

  IntColumn get id => integer().autoIncrement()();

  /// Firestore document id — populated after cloud sync, null before.
  TextColumn get firestoreId => text().nullable()();

  /// User uid from Firebase Auth.
  TextColumn get userId => text()();

  RealColumn get totalAmount => real()();

  /// e.g. 'pending' | 'processing' | 'shipped' | 'delivered' | 'cancelled'
  TextColumn get status =>
      text().withDefault(const Constant('pending'))();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}

/// Stores individual line items that belong to an [OrdersTable] row.
class OrderItemsTable extends Table {
  @override
  String get tableName => 'order_items';

  IntColumn get id => integer().autoIncrement()();

  /// Foreign key → [OrdersTable.id]
  IntColumn get orderId => integer()();

  IntColumn get productId => integer()();
  TextColumn get title => text()();
  TextColumn get image => text()();
  RealColumn get price => real()();
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  TextColumn get category => text()();
}