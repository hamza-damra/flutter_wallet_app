import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/local/sqlite_database.dart';
import '../../../data/repositories/transaction_repository.dart'; // for databaseProvider
import '../models/friend_model.dart';
import '../models/debt_transaction_model.dart';

class DebtsRepository {
  final AppDatabase _db;

  DebtsRepository(this._db);

  Stream<List<FriendModel>> watchFriends(String userId) {
    return (_db.select(_db.friends)
          ..where((f) => f.userId.equals(userId))
          ..where((f) => f.deleted.equals(false)))
        .watch()
        .map(
          (rows) => rows
              .map(
                (row) => FriendModel(
                  id: row.localId.toString(),
                  userId: row.userId,
                  name: row.name,
                  nameAr: row.nameAr,
                  phoneNumber: row.phoneNumber,
                  createdAt: row.createdAtLocal,
                  updatedAt: row.updatedAtLocal,
                  netBalance: 0.0, // Calculated in provider
                ),
              )
              .toList(),
        );
  }

  Stream<List<DebtTransactionModel>> watchDebtTransactions(String userId) {
    return (_db.select(_db.debtTransactions)
          ..where((t) => t.userId.equals(userId))
          ..where((t) => t.deleted.equals(false))
          ..orderBy([
            (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
          ]))
        .watch()
        .map(
          (rows) => rows
              .map(
                (row) => DebtTransactionModel(
                  id: row.localId.toString(),
                  userId: row.userId,
                  friendId: row.friendId.toString(),
                  amount: row.amount,
                  type: DebtEventTypeExtension.fromString(row.type),
                  date: row.date,
                  note: row.note,
                  settled: row.settled,
                  settledAt: row.settledAt,
                  createdAt: row.createdAtLocal,
                  updatedAt: row.updatedAtLocal,
                  affectMainBalance: row.affectMainBalance,
                  linkedTransactionId: row.linkedTransactionId,
                ),
              )
              .toList(),
        );
  }

  Future<int> addFriend(FriendModel friend) async {
    final localId = await _db
        .into(_db.friends)
        .insert(
          FriendsCompanion.insert(
            userId: friend.userId,
            name: friend.name,
            nameAr: Value(friend.nameAr),
            phoneNumber: Value(friend.phoneNumber),
            createdAtLocal: friend.createdAt,
            updatedAtLocal: friend.updatedAt,
          ),
        );

    // Add to sync queue
    await _db.into(_db.syncQueue).insert(
          SyncQueueCompanion.insert(
            entityType: 'friend',
            entityId: localId.toString(),
            operation: 'insert',
            createdAt: DateTime.now(),
          ),
        );

    return localId;
  }

  Future<int> addDebtTransaction(DebtTransactionModel transaction) async {
    final localId = await _db
        .into(_db.debtTransactions)
        .insert(
          DebtTransactionsCompanion.insert(
            userId: transaction.userId,
            friendId: int.parse(transaction.friendId),
            amount: transaction.amount,
            type: transaction.type.value,
            date: transaction.date,
            note: Value(transaction.note),
            createdAtLocal: transaction.createdAt,
            updatedAtLocal: transaction.updatedAt,
            affectMainBalance: Value(transaction.affectMainBalance),
            linkedTransactionId: Value(transaction.linkedTransactionId),
          ),
        );

    // Add to sync queue
    await _db.into(_db.syncQueue).insert(
          SyncQueueCompanion.insert(
            entityType: 'debtTransaction',
            entityId: localId.toString(),
            operation: 'insert',
            createdAt: DateTime.now(),
          ),
        );

    return localId;
  }

  Future<void> deleteFriend(String id) async {
    // First, delete all debt transactions for this friend
    final friendTransactions = await (_db.select(_db.debtTransactions)
          ..where((t) => t.friendId.equals(int.parse(id)))
          ..where((t) => t.deleted.equals(false)))
        .get();
    
    for (final tx in friendTransactions) {
      await (_db.update(_db.debtTransactions)
            ..where((t) => t.localId.equals(tx.localId)))
          .write(const DebtTransactionsCompanion(deleted: Value(true)));
      
      // Add each transaction to sync queue
      await _db.into(_db.syncQueue).insert(
            SyncQueueCompanion.insert(
              entityType: 'debtTransaction',
              entityId: tx.localId.toString(),
              operation: 'delete',
              createdAt: DateTime.now(),
            ),
          );
    }
    
    // Then delete the friend
    await (_db.update(_db.friends)
          ..where((t) => t.localId.equals(int.parse(id))))
        .write(const FriendsCompanion(deleted: Value(true)));

    // Add to sync queue
    await _db.into(_db.syncQueue).insert(
          SyncQueueCompanion.insert(
            entityType: 'friend',
            entityId: id,
            operation: 'delete',
            createdAt: DateTime.now(),
          ),
        );
  }

  Future<void> deleteDebtTransaction(String id) async {
    await (_db.update(_db.debtTransactions)
          ..where((t) => t.localId.equals(int.parse(id))))
        .write(const DebtTransactionsCompanion(deleted: Value(true)));

    // Add to sync queue
    await _db.into(_db.syncQueue).insert(
          SyncQueueCompanion.insert(
            entityType: 'debtTransaction',
            entityId: id,
            operation: 'delete',
            createdAt: DateTime.now(),
          ),
        );
  }

  Future<void> updateDebtTransaction(DebtTransactionModel transaction) async {
    await (_db.update(_db.debtTransactions)
          ..where((t) => t.localId.equals(int.parse(transaction.id))))
        .write(
          DebtTransactionsCompanion(
            amount: Value(transaction.amount),
            type: Value(transaction.type.value),
            date: Value(transaction.date),
            note: Value(transaction.note),
            settled: Value(transaction.settled),
            settledAt: Value(transaction.settledAt),
            updatedAtLocal: Value(transaction.updatedAt),
            affectMainBalance: Value(transaction.affectMainBalance),
            linkedTransactionId: Value(transaction.linkedTransactionId),
          ),
        );

    // Add to sync queue
    await _db.into(_db.syncQueue).insert(
          SyncQueueCompanion.insert(
            entityType: 'debtTransaction',
            entityId: transaction.id,
            operation: 'update',
            createdAt: DateTime.now(),
          ),
        );
  }

  Future<void> settleDebtTransaction(String transactionId) async {
    final now = DateTime.now();
    await (_db.update(_db.debtTransactions)
          ..where((t) => t.localId.equals(int.parse(transactionId))))
        .write(
          DebtTransactionsCompanion(
            settled: const Value(true),
            settledAt: Value(now),
            updatedAtLocal: Value(now),
            syncStatus: const Value('pending'),
          ),
        );

    // Add to sync queue
    await _db.into(_db.syncQueue).insert(
          SyncQueueCompanion.insert(
            entityType: 'debtTransaction',
            entityId: transactionId,
            operation: 'update',
            createdAt: DateTime.now(),
          ),
        );
  }

  Future<void> updateFriend(FriendModel friend) async {
    final now = DateTime.now();
    await (_db.update(_db.friends)
          ..where((f) => f.localId.equals(int.parse(friend.id))))
        .write(
          FriendsCompanion(
            name: Value(friend.name),
            nameAr: Value(friend.nameAr),
            phoneNumber: Value(friend.phoneNumber),
            updatedAtLocal: Value(now),
            syncStatus: const Value('pending'),
          ),
        );

    // Add to sync queue
    await _db.into(_db.syncQueue).insert(
          SyncQueueCompanion.insert(
            entityType: 'friend',
            entityId: friend.id,
            operation: 'update',
            createdAt: DateTime.now(),
          ),
        );
  }
}

final debtsRepositoryProvider = Provider<DebtsRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DebtsRepository(db);
});
