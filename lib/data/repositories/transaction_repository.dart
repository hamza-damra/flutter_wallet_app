import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../local/sqlite_database.dart';
import '../../core/models/transaction_model.dart';

class TransactionRepository {
  final AppDatabase _db;

  TransactionRepository(this._db);

  Stream<List<TransactionModel>> watchTransactions(String userId) {
    return (_db.select(_db.transactions)
          ..where((t) => t.userId.equals(userId))
          ..where((t) => t.deleted.equals(false))
          ..orderBy([
            (t) => OrderingTerm(
              expression: t.createdAtLocal,
              mode: OrderingMode.desc,
            ),
          ]))
        .watch()
        .map((rows) => rows.map((row) => _mapRowToModel(row)).toList());
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    final companion = TransactionsCompanion.insert(
      userId: transaction.userId,
      title: transaction.title,
      titleAr: Value(transaction.titleAr),
      amount: transaction.amount,
      type: transaction.type,
      categoryId: transaction.categoryId,
      categoryName: transaction.categoryName,
      categoryIcon: transaction.categoryIcon,
      createdAtLocal: transaction.createdAt,
      updatedAtLocal: transaction.updatedAt,
      syncStatus: const Value('pending'),
    );

    final localId = await _db.into(_db.transactions).insert(companion);

    await _db
        .into(_db.syncQueue)
        .insert(
          SyncQueueCompanion.insert(
            entityType: 'transaction',
            entityId: localId.toString(),
            operation: 'insert',
            createdAt: DateTime.now(),
          ),
        );
  }

  Future<void> updateTransaction(
    TransactionModel transaction,
    int localId,
  ) async {
    await (_db.update(
      _db.transactions,
    )..where((t) => t.localId.equals(localId))).write(
      TransactionsCompanion(
        title: Value(transaction.title),
        titleAr: Value(transaction.titleAr),
        amount: Value(transaction.amount),
        type: Value(transaction.type),
        categoryId: Value(transaction.categoryId),
        categoryName: Value(transaction.categoryName),
        categoryIcon: Value(transaction.categoryIcon),
        updatedAtLocal: Value(DateTime.now()),
        syncStatus: const Value('pending'),
      ),
    );

    await _db
        .into(_db.syncQueue)
        .insert(
          SyncQueueCompanion.insert(
            entityType: 'transaction',
            entityId: localId.toString(),
            operation: 'update',
            createdAt: DateTime.now(),
          ),
        );
  }

  Future<void> deleteTransaction(String id) async {
    final localIdInt = int.tryParse(id);

    // Find the record to get its localId
    final query = _db.select(_db.transactions);
    if (localIdInt != null) {
      query.where((t) => t.localId.equals(localIdInt));
    } else {
      query.where((t) => t.remoteId.equals(id));
    }

    final row = await query.getSingleOrNull();
    if (row == null) return;

    final localId = row.localId;

    await (_db.update(
      _db.transactions,
    )..where((t) => t.localId.equals(localId))).write(
      const TransactionsCompanion(
        deleted: Value(true),
        syncStatus: Value('pending'),
      ),
    );

    await _db
        .into(_db.syncQueue)
        .insert(
          SyncQueueCompanion.insert(
            entityType: 'transaction',
            entityId: localId.toString(),
            operation: 'delete',
            createdAt: DateTime.now(),
          ),
        );
  }

  TransactionModel _mapRowToModel(Transaction row) {
    return TransactionModel(
      id: row.remoteId ?? row.localId.toString(),
      userId: row.userId,
      title: row.title,
      titleAr: row.titleAr,
      amount: row.amount,
      type: row.type,
      categoryId: row.categoryId,
      categoryName: row.categoryName,
      categoryIcon: row.categoryIcon,
      createdAt: row.createdAtLocal,
      updatedAt: row.updatedAtLocal,
    );
  }
}

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return TransactionRepository(db);
});

final transactionsStreamProvider =
    StreamProvider.family<List<TransactionModel>, String>((ref, userId) {
      return ref.watch(transactionRepositoryProvider).watchTransactions(userId);
    });
