import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/sqlite_database.dart';
import '../data/remote/firestore_service.dart';
import '../data/repositories/transaction_repository.dart';
import 'connectivity_service.dart';
import 'auth_service.dart';
import '../core/models/transaction_model.dart';
import '../core/models/category_model.dart';

class SyncService {
  final Ref _ref;
  final AppDatabase _db;
  final FirestoreService _remote;
  bool _isSyncing = false;

  SyncService(this._ref, this._db, this._remote);

  void init() {
    // Listen to connectivity changes
    _ref.listen(connectivityServiceProvider, (previous, next) {
      if (next == ConnectivityStatus.online &&
          previous != ConnectivityStatus.online) {
        sync();
      }
    });

    // Initial sync check if already online
    final status = _ref.read(connectivityServiceProvider);
    if (status == ConnectivityStatus.online) {
      sync();
    }
  }

  Future<void> sync() async {
    if (_isSyncing) return;
    _isSyncing = true;

    // Update global state to syncing
    _ref.read(syncStatusNotifierProvider.notifier).setSyncing(true);

    try {
      final user = _ref.read(authStateProvider).value;
      if (user == null) return;

      // 1. Process Upload (Local -> Remote)
      await _processSyncQueue();

      // 2. Process Download (Remote -> Local)
      final hadConflicts = await _pullRemoteData(user.uid);

      if (hadConflicts) {
        _ref
            .read(syncConflictProvider.notifier)
            .setMessage('Some items were updated after syncing');
      }

      debugPrint('Sync completed successfully');
    } catch (e) {
      debugPrint('Sync error: $e');
    } finally {
      _isSyncing = false;
      _ref.read(syncStatusNotifierProvider.notifier).setSyncing(false);
    }
  }

  Future<void> _processSyncQueue() async {
    final queueItems = await (_db.select(
      _db.syncQueue,
    )..orderBy([(t) => OrderingTerm(expression: t.createdAt)])).get();

    for (final item in queueItems) {
      try {
        if (item.entityType == 'transaction') {
          await _syncTransaction(item);
        } else if (item.entityType == 'category') {
          await _syncCategory(item);
        }

        await (_db.delete(
          _db.syncQueue,
        )..where((t) => t.id.equals(item.id))).go();
      } catch (e) {
        debugPrint('Error syncing item ${item.id}: $e');
      }
    }
  }

  Future<void> _syncTransaction(SyncQueueData item) async {
    final localId = int.parse(item.entityId);
    final row = await (_db.select(
      _db.transactions,
    )..where((t) => t.localId.equals(localId))).getSingleOrNull();
    if (row == null) return;

    final model = TransactionModel(
      id: row.remoteId ?? '',
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

    if (item.operation == 'insert') {
      final remoteId = await _remote.addTransaction(model);
      await (_db.update(
        _db.transactions,
      )..where((t) => t.localId.equals(localId))).write(
        TransactionsCompanion(
          remoteId: Value(remoteId),
          syncStatus: const Value('synced'),
        ),
      );
    } else if (item.operation == 'update') {
      if (row.remoteId != null) {
        await _remote.updateTransaction(model);
        await (_db.update(_db.transactions)
              ..where((t) => t.localId.equals(localId)))
            .write(const TransactionsCompanion(syncStatus: Value('synced')));
      }
    } else if (item.operation == 'delete') {
      if (row.remoteId != null) {
        await _remote.deleteTransaction(row.remoteId!);
      }
      await (_db.delete(
        _db.transactions,
      )..where((t) => t.localId.equals(localId))).go();
    }
  }

  Future<void> _syncCategory(SyncQueueData item) async {
    final categoryId = item.entityId;
    final row = await (_db.select(
      _db.categories,
    )..where((c) => c.id.equals(categoryId))).getSingleOrNull();
    if (row == null) return;

    final model = CategoryModel(
      id: row.id,
      userId: row.userId,
      name: row.name,
      nameAr: row.nameAr,
      icon: row.icon,
      type: row.type,
      updatedAt: row.updatedAt,
    );

    if (item.operation == 'insert') {
      await _remote.addCategory(model);
      await (_db.update(_db.categories)..where((c) => c.id.equals(categoryId)))
          .write(const CategoriesCompanion(syncStatus: Value('synced')));
    } else if (item.operation == 'update') {
      await _remote.updateCategory(model);
      await (_db.update(_db.categories)..where((c) => c.id.equals(categoryId)))
          .write(const CategoriesCompanion(syncStatus: Value('synced')));
    } else if (item.operation == 'delete') {
      try {
        await _remote.deleteCategory(row.id);
      } catch (e) {
        // If it doesn't exist on remote, that's fine
      }
      await (_db.delete(
        _db.categories,
      )..where((c) => c.id.equals(categoryId))).go();
    }
  }

  Future<bool> _pullRemoteData(String userId) async {
    bool hadConflicts = false;

    // 1. Pull Categories
    final remoteCategories = await _remote.getRecentCategories(
      userId,
      DateTime(2000),
    );
    for (final remote in remoteCategories) {
      final local = await (_db.select(
        _db.categories,
      )..where((c) => c.id.equals(remote.id))).getSingleOrNull();
      if (local == null) {
        await _db
            .into(_db.categories)
            .insert(
              CategoriesCompanion.insert(
                id: remote.id,
                userId: Value(remote.userId),
                name: remote.name,
                nameAr: Value(remote.nameAr),
                icon: remote.icon,
                type: remote.type,
                updatedAt: remote.updatedAt,
                syncStatus: const Value('synced'),
              ),
            );
      } else if (remote.updatedAt.isAfter(local.updatedAt)) {
        await (_db.update(
          _db.categories,
        )..where((c) => c.id.equals(remote.id))).write(
          CategoriesCompanion(
            name: Value(remote.name),
            nameAr: Value(remote.nameAr),
            icon: Value(remote.icon),
            type: Value(remote.type),
            updatedAt: Value(remote.updatedAt),
            syncStatus: const Value('synced'),
          ),
        );
      }
    }

    // 2. Pull Transactions
    final remoteTransactions = await _remote.getRecentTransactions(
      userId,
      DateTime(2000),
    );
    for (final remote in remoteTransactions) {
      final local = await (_db.select(
        _db.transactions,
      )..where((t) => t.remoteId.equals(remote.id))).getSingleOrNull();

      if (local == null) {
        await _db
            .into(_db.transactions)
            .insert(
              TransactionsCompanion.insert(
                remoteId: Value(remote.id),
                userId: remote.userId,
                title: remote.title,
                titleAr: Value(remote.titleAr),
                amount: remote.amount,
                type: remote.type,
                categoryId: remote.categoryId,
                categoryName: remote.categoryName,
                categoryIcon: remote.categoryIcon,
                createdAtLocal: remote.createdAt,
                updatedAtLocal: remote.updatedAt,
                syncStatus: const Value('synced'),
              ),
            );
      } else {
        // Last-Write-Wins: Compare timestamps
        if (remote.updatedAt.isAfter(local.updatedAtLocal)) {
          // Check if local was soft-deleted
          if (local.deleted) {
            // If remote is newer than the deletion, we "undelete" it with remote data
            hadConflicts = true;
          }

          await (_db.update(
            _db.transactions,
          )..where((t) => t.localId.equals(local.localId))).write(
            TransactionsCompanion(
              title: Value(remote.title),
              titleAr: Value(remote.titleAr),
              amount: Value(remote.amount),
              type: Value(remote.type),
              categoryId: Value(remote.categoryId),
              categoryName: Value(remote.categoryName),
              categoryIcon: Value(remote.categoryIcon),
              updatedAtLocal: Value(remote.updatedAt),
              syncStatus: const Value('synced'),
              deleted: const Value(false), // Undelete if it was deleted
            ),
          );
        } else if (local.updatedAtLocal.isAfter(remote.updatedAt) &&
            local.syncStatus == 'synced') {
          // Local is newer but marked as synced?
          // This shouldn't normally happen unless sync() just finished pushing.
        }
      }
    }
    return hadConflicts;
  }
}

class SyncStatusNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void setSyncing(bool syncing) => state = syncing;
}

final syncStatusNotifierProvider = NotifierProvider<SyncStatusNotifier, bool>(
  () => SyncStatusNotifier(),
);

class SyncConflictNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void setMessage(String? msg) => state = msg;
}

final syncConflictProvider = NotifierProvider<SyncConflictNotifier, String?>(
  () => SyncConflictNotifier(),
);

final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(databaseProvider);
  final remote = ref.watch(firestoreServiceProvider);
  final service = SyncService(ref, db, remote);
  service.init();
  return service;
});
