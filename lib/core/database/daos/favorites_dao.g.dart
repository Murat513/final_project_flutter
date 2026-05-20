// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorites_dao.dart';

// ignore_for_file: type=lint
mixin _$FavoritesDaoMixin on DatabaseAccessor<AppDatabase> {
  $FavoriteItemsTableTable get favoriteItemsTable =>
      attachedDatabase.favoriteItemsTable;
  FavoritesDaoManager get managers => FavoritesDaoManager(this);
}

class FavoritesDaoManager {
  final _$FavoritesDaoMixin _db;
  FavoritesDaoManager(this._db);
  $$FavoriteItemsTableTableTableManager get favoriteItemsTable =>
      $$FavoriteItemsTableTableTableManager(
          _db.attachedDatabase, _db.favoriteItemsTable);
}
