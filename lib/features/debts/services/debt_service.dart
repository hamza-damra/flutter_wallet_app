import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/local/sqlite_database.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../models/debt_transaction_model.dart';

class DebtService {
  final AppDatabase _db;

  DebtService(this._db);

  /// Records a debt event with atomic transaction handling.
  /// If affectMainBalance is true, also creates a transaction entry and updates main balance.
  Future<int> recordDebtEvent({
    required String userId,
    required String friendId,
    required String friendName,
    required double amount,
    required DebtEventType type,
    required DateTime date,
    String? note,
    required bool affectMainBalance,
  }) async {
    // Validation
    if (amount <= 0) {
      throw ArgumentError('Amount must be greater than 0');
    }

    final now = DateTime.now();
    int? linkedTransactionId;

    // Use a database transaction for atomicity
    return await _db.transaction(() async {
      // 1. Create the debt event
      final debtLocalId = await _db.into(_db.debtTransactions).insert(
        DebtTransactionsCompanion.insert(
          userId: userId,
          friendId: int.parse(friendId),
          amount: amount,
          type: type.value,
          date: date,
          note: Value(note),
          createdAtLocal: now,
          updatedAtLocal: now,
          affectMainBalance: Value(affectMainBalance),
          linkedTransactionId: const Value(null),
        ),
      );

      // 2. If affectMainBalance is true, create a linked transaction
      if (affectMainBalance) {
        // Determine transaction type based on debt event type
        final transactionType = type.increasesMainBalance ? 'income' : 'expense';
        
        // Create title based on debt event type
        String title;
        String? titleAr;
        switch (type) {
          case DebtEventType.borrow:
            title = 'Borrowed from $friendName';
            titleAr = 'اقترضت من $friendName';
            break;
          case DebtEventType.lend:
            title = 'Lent to $friendName';
            titleAr = 'أقرضت $friendName';
            break;
          case DebtEventType.settlePay:
            title = 'Paid back $friendName';
            titleAr = 'دفعت إلى $friendName';
            break;
          case DebtEventType.settleReceive:
            title = 'Received from $friendName';
            titleAr = 'استلمت من $friendName';
            break;
        }

        // Insert the linked transaction
        linkedTransactionId = await _db.into(_db.transactions).insert(
          TransactionsCompanion.insert(
            userId: userId,
            title: title,
            titleAr: Value(titleAr),
            amount: amount,
            type: transactionType,
            categoryId: 'debt',
            categoryName: 'Debt',
            categoryIcon: 'account_balance_wallet',
            createdAtLocal: date,
            updatedAtLocal: now,
            syncStatus: const Value('pending'),
          ),
        );

        // Update the debt event with the linked transaction ID
        await (_db.update(_db.debtTransactions)
              ..where((d) => d.localId.equals(debtLocalId)))
            .write(DebtTransactionsCompanion(
              linkedTransactionId: Value(linkedTransactionId),
            ));

        // Add transaction to sync queue
        await _db.into(_db.syncQueue).insert(
          SyncQueueCompanion.insert(
            entityType: 'transaction',
            entityId: linkedTransactionId.toString(),
            operation: 'insert',
            createdAt: now,
          ),
        );
      }

      // 3. Add debt event to sync queue
      await _db.into(_db.syncQueue).insert(
        SyncQueueCompanion.insert(
          entityType: 'debtTransaction',
          entityId: debtLocalId.toString(),
          operation: 'insert',
          createdAt: now,
        ),
      );

      return debtLocalId;
    });
  }

  /// Validates settlement amount against outstanding debt
  Future<bool> validateSettlementAmount({
    required String friendId,
    required double amount,
    required DebtEventType type,
  }) async {
    if (!type.isSettlement) return true;

    // Get all unsettled transactions for this friend
    final transactions = await (_db.select(_db.debtTransactions)
          ..where((t) => t.friendId.equals(int.parse(friendId)))
          ..where((t) => t.deleted.equals(false)))
        .get();

    double iOwe = 0;
    double owesMe = 0;

    for (final tx in transactions) {
      final txType = DebtEventTypeExtension.fromString(tx.type);
      switch (txType) {
        case DebtEventType.borrow:
          iOwe += tx.amount;
          break;
        case DebtEventType.lend:
          owesMe += tx.amount;
          break;
        case DebtEventType.settlePay:
          iOwe -= tx.amount;
          break;
        case DebtEventType.settleReceive:
          owesMe -= tx.amount;
          break;
      }
    }

    // settlePay reduces what I owe, settleReceive reduces what they owe me
    if (type == DebtEventType.settlePay) {
      return amount <= iOwe;
    } else if (type == DebtEventType.settleReceive) {
      return amount <= owesMe;
    }

    return true;
  }

  /// Gets debt summary for a friend (iOwe, owesMe)
  Future<({double iOwe, double owesMe})> getDebtSummary(String friendId) async {
    final transactions = await (_db.select(_db.debtTransactions)
          ..where((t) => t.friendId.equals(int.parse(friendId)))
          ..where((t) => t.deleted.equals(false)))
        .get();

    double iOwe = 0;
    double owesMe = 0;

    for (final tx in transactions) {
      final txType = DebtEventTypeExtension.fromString(tx.type);
      switch (txType) {
        case DebtEventType.borrow:
          iOwe += tx.amount;
          break;
        case DebtEventType.lend:
          owesMe += tx.amount;
          break;
        case DebtEventType.settlePay:
          iOwe -= tx.amount;
          break;
        case DebtEventType.settleReceive:
          owesMe -= tx.amount;
          break;
      }
    }

    return (iOwe: iOwe > 0 ? iOwe : 0.0, owesMe: owesMe > 0 ? owesMe : 0.0);
  }

  /// Settles a debt with optional main balance effect
  Future<void> settleDebt({
    required String debtEventId,
    required String friendName,
    required double amount,
    required DebtEventType originalType,
    required bool affectMainBalance,
  }) async {
    final localId = int.parse(debtEventId);
    final now = DateTime.now();

    await _db.transaction(() async {
      // Get the debt event
      final debtEvent = await (_db.select(_db.debtTransactions)
            ..where((d) => d.localId.equals(localId)))
          .getSingleOrNull();

      if (debtEvent == null) return;

      int? linkedTransactionId;

      // If affectMainBalance is true, create a linked transaction
      if (affectMainBalance) {
        // Determine transaction type based on original debt type
        // If I lent money and now receiving it back -> income
        // If I borrowed money and now paying it back -> expense
        final isReceiving = originalType == DebtEventType.lend;
        final transactionType = isReceiving ? 'income' : 'expense';

        String title;
        String? titleAr;
        if (isReceiving) {
          title = 'Received from $friendName (Settlement)';
          titleAr = 'استلمت من $friendName (تسوية)';
        } else {
          title = 'Paid back $friendName (Settlement)';
          titleAr = 'دفعت إلى $friendName (تسوية)';
        }

        // Insert the linked transaction
        linkedTransactionId = await _db.into(_db.transactions).insert(
          TransactionsCompanion.insert(
            userId: debtEvent.userId,
            title: title,
            titleAr: Value(titleAr),
            amount: amount,
            type: transactionType,
            categoryId: 'debt',
            categoryName: 'Debt',
            categoryIcon: 'account_balance_wallet',
            createdAtLocal: now,
            updatedAtLocal: now,
            syncStatus: const Value('pending'),
          ),
        );

        // Add transaction to sync queue
        await _db.into(_db.syncQueue).insert(
          SyncQueueCompanion.insert(
            entityType: 'transaction',
            entityId: linkedTransactionId.toString(),
            operation: 'insert',
            createdAt: now,
          ),
        );
      }

      // Mark the debt as settled
      await (_db.update(_db.debtTransactions)
            ..where((d) => d.localId.equals(localId)))
          .write(DebtTransactionsCompanion(
            settled: const Value(true),
            settledAt: Value(now),
            updatedAtLocal: Value(now),
            syncStatus: const Value('pending'),
            linkedTransactionId: Value(linkedTransactionId),
          ));

      // Add debt to sync queue
      await _db.into(_db.syncQueue).insert(
        SyncQueueCompanion.insert(
          entityType: 'debtTransaction',
          entityId: debtEventId,
          operation: 'update',
          createdAt: now,
        ),
      );
    });
  }

  /// Deletes a debt event and its linked transaction if exists
  Future<void> deleteDebtEvent(String debtEventId) async {
    final localId = int.parse(debtEventId);
    
    await _db.transaction(() async {
      // Get the debt event to check for linked transaction
      final debtEvent = await (_db.select(_db.debtTransactions)
            ..where((d) => d.localId.equals(localId)))
          .getSingleOrNull();

      if (debtEvent == null) return;

      // If there's a linked transaction, delete it too
      if (debtEvent.linkedTransactionId != null) {
        await (_db.update(_db.transactions)
              ..where((t) => t.localId.equals(debtEvent.linkedTransactionId!)))
            .write(const TransactionsCompanion(
              deleted: Value(true),
              syncStatus: Value('pending'),
            ));

        await _db.into(_db.syncQueue).insert(
          SyncQueueCompanion.insert(
            entityType: 'transaction',
            entityId: debtEvent.linkedTransactionId.toString(),
            operation: 'delete',
            createdAt: DateTime.now(),
          ),
        );
      }

      // Delete the debt event
      await (_db.update(_db.debtTransactions)
            ..where((d) => d.localId.equals(localId)))
          .write(const DebtTransactionsCompanion(
            deleted: Value(true),
            syncStatus: Value('pending'),
          ));

      await _db.into(_db.syncQueue).insert(
        SyncQueueCompanion.insert(
          entityType: 'debtTransaction',
          entityId: debtEventId,
          operation: 'delete',
          createdAt: DateTime.now(),
        ),
      );
    });
  }
}

final debtServiceProvider = Provider<DebtService>((ref) {
  final db = ref.watch(databaseProvider);
  return DebtService(db);
});
