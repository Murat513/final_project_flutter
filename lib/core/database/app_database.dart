import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../app_constants.dart';
import 'daos/cart_dao.dart';
import 'daos/favorite_items_table.dart';
import 'daos/favorites_dao.dart';
import 'daos/orders_dao.dart';
import 'tables/cart_items_table.dart';
import 'tables/favorite_items_table.dart';
import 'tables/orders_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    CartItemsTable,
    FavoriteItemsTable,
    OrdersTable,
    OrderItemsTable,
  ],
  daos: [
    CartDao,
    FavoritesDao,
    OrdersDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // Future migrations go here
    },
    beforeOpen: (details) async {
      // Enable foreign keys
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    if (kIsWeb) {
      // Web support via drift_db_worker or sqflite_web — stub for now
      throw UnsupportedError('Web is not supported in this build.');
    }
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, AppConstants.dbName));
    return NativeDatabase.createInBackground(file);
  });
}
