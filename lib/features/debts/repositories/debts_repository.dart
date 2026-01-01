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
                  type: row.type,
                  date: row.date,
                  note: row.note,
                  createdAt: row.createdAtLocal,
                  updatedAt: row.updatedAtLocal,
                ),
              )
              .toList(),
        );
  }

  Future<int> addFriend(FriendModel friend) async {
    return await _db
        .into(_db.friends)
        .insert(
          FriendsCompanion.insert(
            userId: friend.userId,
            name: friend.name,
            phoneNumber: Value(friend.phoneNumber),
            createdAtLocal: friend.createdAt,
            updatedAtLocal: friend.updatedAt,
          ),
        );
  }

  Future<int> addDebtTransaction(DebtTransactionModel transaction) async {
    return await _db
        .into(_db.debtTransactions)
        .insert(
          DebtTransactionsCompanion.insert(
            userId: transaction.userId,
            friendId: int.parse(transaction.friendId),
            amount: transaction.amount,
            type: transaction.type,
            date: transaction.date,
            note: Value(transaction.note),
            createdAtLocal: transaction.createdAt,
            updatedAtLocal: transaction.updatedAt,
          ),
        );
  }

  Future<void> deleteFriend(String id) async {
    await (_db.update(_db.friends)
          ..where((t) => t.localId.equals(int.parse(id))))
        .write(const FriendsCompanion(deleted: Value(true)));
    // Also delete related transactions or mark them
    // Ideally we should cascade or handle this logic.
    // For now, simplicity: just delete friend.
  }

  Future<void> deleteDebtTransaction(String id) async {
    await (_db.update(_db.debtTransactions)
          ..where((t) => t.localId.equals(int.parse(id))))
        .write(const DebtTransactionsCompanion(deleted: Value(true)));
  }
}

final debtsRepositoryProvider = Provider<DebtsRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DebtsRepository(db);
});
