import 'package:drift/drift.dart';
import 'dart:io';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'sqlite_database.g.dart';

class Transactions extends Table {
  IntColumn get localId => integer().autoIncrement()();
  TextColumn get remoteId => text().nullable()();
  TextColumn get userId => text()();
  TextColumn get title => text()();
  TextColumn get titleAr => text().nullable()();
  RealColumn get amount => real()();
  TextColumn get type => text()();
  TextColumn get categoryId => text()();
  TextColumn get categoryName => text()();
  TextColumn get categoryIcon => text()();
  DateTimeColumn get createdAtLocal => dateTime()();
  DateTimeColumn get updatedAtLocal => dateTime()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  TextColumn get syncStatus => text().withDefault(
    const Constant('pending'),
  )(); // pending, synced, failed
  TextColumn get lastSyncError => text().nullable()();
}

class Categories extends Table {
  TextColumn get id => text()(); // Local UUID or Firestore ID
  TextColumn get userId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get nameAr => text().nullable()();
  TextColumn get icon => text()();
  TextColumn get type => text()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}

class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType => text()(); // transaction, category
  TextColumn get entityId => text()(); // The local ID
  TextColumn get operation => text()(); // insert, update, delete
  DateTimeColumn get createdAt => dateTime()();
}

class Friends extends Table {
  IntColumn get localId => integer().autoIncrement()();
  TextColumn get remoteId => text().nullable()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  TextColumn get phoneNumber => text().nullable()();
  DateTimeColumn get createdAtLocal => dateTime()();
  DateTimeColumn get updatedAtLocal => dateTime()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
}

class DebtTransactions extends Table {
  IntColumn get localId => integer().autoIncrement()();
  TextColumn get remoteId => text().nullable()();
  TextColumn get userId => text()();
  IntColumn get friendId => integer().references(Friends, #localId)();
  RealColumn get amount => real()();
  TextColumn get type => text()(); // 'lent' or 'borrowed'
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAtLocal => dateTime()();
  DateTimeColumn get updatedAtLocal => dateTime()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
}

@DriftDatabase(
  tables: [Transactions, Categories, SyncQueue, Friends, DebtTransactions],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.createTable(friends);
        await m.createTable(debtTransactions);
      }
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase(file);
  });
}
