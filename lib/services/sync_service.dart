import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/sqlite_database.dart';
import '../data/remote/firestore_service.dart';
import '../data/repositories/transaction_repository.dart';
import 'connectivity_service.dart';
import 'auth_service.dart';
import '../core/models/transaction_model.dart';
import '../core/models/category_model.dart';
import '../features/debts/models/friend_model.dart';
import '../features/debts/models/debt_transaction_model.dart';

class SyncService with WidgetsBindingObserver {
  final Ref _ref;
  final AppDatabase _db;
  final FirestoreService _remote;
  bool _isSyncing = false;
  StreamSubscription? _queueSubscription;
  Timer? _pollingTimer;

  SyncService(this._ref, this._db, this._remote);

  void init() {
    WidgetsBinding.instance.addObserver(this);
    debugPrint('🔄 SYNC: SyncService initializing...');

    // Listen to connectivity changes
    _ref.listen(connectivityServiceProvider, (previous, next) {
      debugPrint('🔄 SYNC: Connectivity changed: $previous -> $next');
      if (next == ConnectivityStatus.online &&
          previous != ConnectivityStatus.online) {
        debugPrint(
          'SyncService: Connectivity changed to online, triggering sync',
        );
        sync();
      }
    });

    // Listen to auth changes
    _ref.listen(authStateProvider, (previous, next) {
      final previousUser = previous?.value;
      final nextUser = next.value;

      debugPrint('🔄 SYNC: Auth state changed: ${previousUser?.uid} -> ${nextUser?.uid}');
      if (nextUser != null && previousUser?.uid != nextUser.uid) {
        debugPrint('SyncService: User logged in, triggering sync');
        // Delay slightly to ensure connectivity check has completed
        Future.delayed(const Duration(milliseconds: 500), () => sync());
      }
    });

    // Watch Sync Queue for local changes
    _queueSubscription = _db.select(_db.syncQueue).watch().listen((items) {
      if (items.isNotEmpty) {
        debugPrint('SyncService: Queue has ${items.length} items, triggering sync');
        sync();
      }
    });

    // Start periodic polling
    _startPolling();

    // Initial sync check - delay to allow connectivity to be determined
    Future.delayed(const Duration(seconds: 1), () {
      debugPrint('🔄 SYNC: Initial delayed sync check');
      sync();
    });
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      debugPrint('SyncService: Periodic sync trigger');
      sync();
    });
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _queueSubscription?.cancel();
    _pollingTimer?.cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint(
        'SyncService: App resumed, triggering sync and restarting poller',
      );
      sync();
      _startPolling();
    } else if (state == AppLifecycleState.paused) {
      _pollingTimer?.cancel();
    }
  }

  Future<void> sync() async {
    if (_isSyncing) {
      debugPrint('🔄 SYNC: Already syncing, skipping');
      return;
    }

    // Check connectivity
    final status = _ref.read(connectivityServiceProvider);
    if (status != ConnectivityStatus.online) {
      debugPrint('🔄 SYNC: Offline, skipping sync');
      return;
    }

    _isSyncing = true;
    _ref.read(syncStatusNotifierProvider.notifier).setSyncing(true);
    debugPrint('🔄 SYNC: Starting sync...');

    try {
      final user = _ref.read(authStateProvider).value;
      if (user == null) {
        debugPrint('🔄 SYNC: No user logged in, skipping sync');
        return;
      }
      debugPrint('🔄 SYNC: User ID = ${user.uid}');

      // 1. Process Upload (Local -> Remote)
      debugPrint('🔄 SYNC: Processing upload queue...');
      await _processSyncQueue();
      debugPrint('🔄 SYNC: Upload queue processed');

      // 2. Process Download (Remote -> Local)
      debugPrint('🔄 SYNC: Pulling remote data...');
      final hadConflicts = await _pullRemoteData(user.uid);
      debugPrint('🔄 SYNC: Pull complete, hadConflicts=$hadConflicts');

      if (hadConflicts) {
        _ref
            .read(syncConflictProvider.notifier)
            .setMessage('Some items were updated after syncing');
      }

      debugPrint('🔄 SYNC: ✅ Sync completed successfully');
    } catch (e, stack) {
      debugPrint('🔄 SYNC: ❌ Error: $e');
      debugPrint('🔄 SYNC: Stack: $stack');
    } finally {
      _isSyncing = false;
      _ref.read(syncStatusNotifierProvider.notifier).setSyncing(false);
    }
  }

  Future<void> _processSyncQueue() async {
    final queueItems = await (_db.select(
      _db.syncQueue,
    )..orderBy([(t) => OrderingTerm(expression: t.createdAt)])).get();

    debugPrint('🔄 SYNC: Queue has ${queueItems.length} items');

    for (final item in queueItems) {
      debugPrint('🔄 SYNC: Processing ${item.entityType} ${item.operation} id=${item.entityId}');
      try {
        if (item.entityType == 'transaction') {
          await _syncTransaction(item);
        } else if (item.entityType == 'category') {
          await _syncCategory(item);
        } else if (item.entityType == 'friend') {
          await _syncFriend(item);
        } else if (item.entityType == 'debtTransaction') {
          await _syncDebtTransaction(item);
        }

        await (_db.delete(
          _db.syncQueue,
        )..where((t) => t.id.equals(item.id))).go();
        debugPrint('🔄 SYNC: ✅ Item ${item.id} synced and removed from queue');
      } catch (e, stack) {
        debugPrint('🔄 SYNC: ❌ Error syncing item ${item.id}: $e');
        debugPrint('🔄 SYNC: Stack: $stack');
      }
    }
  }

  Future<void> _syncTransaction(SyncQueueData item) async {
    final localId = int.parse(item.entityId);
    final row = await (_db.select(
      _db.transactions,
    )..where((t) => t.localId.equals(localId))).getSingleOrNull();
    if (row == null) {
      debugPrint('🔄 SYNC: Transaction localId=$localId not found in local DB');
      return;
    }
    debugPrint('🔄 SYNC: Found transaction: ${row.title} (${row.amount})');

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
      debugPrint('🔄 SYNC: Inserting transaction to Firestore...');
      final remoteId = await _remote.addTransaction(model);
      debugPrint('🔄 SYNC: ✅ Transaction added to Firestore, remoteId=$remoteId');
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
    if (row == null) {
      debugPrint('🔄 SYNC: Category id=$categoryId not found in local DB');
      return;
    }
    debugPrint('🔄 SYNC: Found category: ${row.name} (id=${row.id})');

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
      debugPrint('🔄 SYNC: Inserting category to Firestore...');
      await _remote.addCategory(model);
      debugPrint('🔄 SYNC: ✅ Category added to Firestore');
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

  Future<void> _syncFriend(SyncQueueData item) async {
    final localId = int.parse(item.entityId);
    final row = await (_db.select(_db.friends)
          ..where((f) => f.localId.equals(localId)))
        .getSingleOrNull();
    if (row == null) {
      debugPrint('🔄 SYNC: Friend localId=$localId not found in local DB');
      return;
    }
    debugPrint('🔄 SYNC: Found friend: ${row.name}');

    final model = FriendModel(
      id: row.remoteId ?? '',
      userId: row.userId,
      name: row.name,
      phoneNumber: row.phoneNumber,
      createdAt: row.createdAtLocal,
      updatedAt: row.updatedAtLocal,
    );

    if (item.operation == 'insert') {
      debugPrint('🔄 SYNC: Inserting friend to Firestore...');
      final remoteId = await _remote.addFriend(model);
      debugPrint('🔄 SYNC: ✅ Friend added to Firestore, remoteId=$remoteId');
      await (_db.update(_db.friends)..where((f) => f.localId.equals(localId)))
          .write(FriendsCompanion(
            remoteId: Value(remoteId),
            syncStatus: const Value('synced'),
          ));
    } else if (item.operation == 'update') {
      if (row.remoteId != null) {
        await _remote.updateFriend(model);
        await (_db.update(_db.friends)..where((f) => f.localId.equals(localId)))
            .write(const FriendsCompanion(syncStatus: Value('synced')));
      }
    } else if (item.operation == 'delete') {
      if (row.remoteId != null) {
        try {
          await _remote.deleteFriend(row.remoteId!);
        } catch (e) {
          // If it doesn't exist on remote, that's fine
        }
      }
      await (_db.delete(_db.friends)..where((f) => f.localId.equals(localId))).go();
    }
  }

  Future<void> _syncDebtTransaction(SyncQueueData item) async {
    final localId = int.parse(item.entityId);
    final row = await (_db.select(_db.debtTransactions)
          ..where((d) => d.localId.equals(localId)))
        .getSingleOrNull();
    if (row == null) {
      debugPrint('🔄 SYNC: DebtTransaction localId=$localId not found in local DB');
      return;
    }
    debugPrint('🔄 SYNC: Found debtTransaction: amount=${row.amount}');

    // Look up the friend's remoteId to store in Firestore
    final friend = await (_db.select(_db.friends)
          ..where((f) => f.localId.equals(row.friendId)))
        .getSingleOrNull();
    final remoteFriendId = friend?.remoteId ?? '';
    debugPrint('🔄 SYNC: Friend localId=${row.friendId} -> remoteId=$remoteFriendId');

    if (remoteFriendId.isEmpty) {
      debugPrint('🔄 SYNC: ⚠️ Friend not synced yet, skipping debtTransaction sync');
      return;
    }

    final model = DebtTransactionModel(
      id: row.remoteId ?? '',
      userId: row.userId,
      friendId: remoteFriendId, // Use the REMOTE friendId for Firestore
      amount: row.amount,
      type: row.type,
      date: row.date,
      note: row.note,
      createdAt: row.createdAtLocal,
      updatedAt: row.updatedAtLocal,
    );

    if (item.operation == 'insert') {
      debugPrint('🔄 SYNC: Inserting debtTransaction to Firestore...');
      final remoteId = await _remote.addDebtTransaction(model);
      debugPrint('🔄 SYNC: ✅ DebtTransaction added to Firestore, remoteId=$remoteId');
      await (_db.update(_db.debtTransactions)..where((d) => d.localId.equals(localId)))
          .write(DebtTransactionsCompanion(
            remoteId: Value(remoteId),
            syncStatus: const Value('synced'),
          ));
    } else if (item.operation == 'update') {
      if (row.remoteId != null) {
        await _remote.updateDebtTransaction(model);
        await (_db.update(_db.debtTransactions)..where((d) => d.localId.equals(localId)))
            .write(const DebtTransactionsCompanion(syncStatus: Value('synced')));
      }
    } else if (item.operation == 'delete') {
      if (row.remoteId != null) {
        try {
          await _remote.deleteDebtTransaction(row.remoteId!);
        } catch (e) {
          // If it doesn't exist on remote, that's fine
        }
      }
      await (_db.delete(_db.debtTransactions)..where((d) => d.localId.equals(localId))).go();
    }
  }

  Future<bool> _pullRemoteData(String userId) async {
    bool hadConflicts = false;
    debugPrint('🔄 SYNC: Pulling data for userId=$userId');

    // 1. Pull Categories
    final remoteCategories = await _remote.getRecentCategories(
      userId,
      DateTime(2000),
    );
    debugPrint('🔄 SYNC: Found ${remoteCategories.length} remote categories');
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
    debugPrint('🔄 SYNC: Found ${remoteTransactions.length} remote transactions');
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

    // 3. Pull Friends
    final remoteFriends = await _remote.getRecentFriends(userId, DateTime(2000));
    debugPrint('🔄 SYNC: Found ${remoteFriends.length} remote friends');
    for (final remote in remoteFriends) {
      final local = await (_db.select(_db.friends)
            ..where((f) => f.remoteId.equals(remote.id)))
          .getSingleOrNull();

      if (local == null) {
        await _db.into(_db.friends).insert(
              FriendsCompanion.insert(
                remoteId: Value(remote.id),
                userId: remote.userId,
                name: remote.name,
                phoneNumber: Value(remote.phoneNumber),
                createdAtLocal: remote.createdAt,
                updatedAtLocal: remote.updatedAt,
                syncStatus: const Value('synced'),
              ),
            );
      } else if (remote.updatedAt.isAfter(local.updatedAtLocal)) {
        await (_db.update(_db.friends)..where((f) => f.localId.equals(local.localId)))
            .write(FriendsCompanion(
              name: Value(remote.name),
              phoneNumber: Value(remote.phoneNumber),
              updatedAtLocal: Value(remote.updatedAt),
              syncStatus: const Value('synced'),
              deleted: const Value(false),
            ));
      }
    }

    // 4. Pull DebtTransactions
    final remoteDebts = await _remote.getRecentDebtTransactions(userId, DateTime(2000));
    debugPrint('🔄 SYNC: Found ${remoteDebts.length} remote debtTransactions');
    for (final remote in remoteDebts) {
      debugPrint('🔄 SYNC: Processing debtTransaction id=${remote.id}, friendId=${remote.friendId}');
      final local = await (_db.select(_db.debtTransactions)
            ..where((d) => d.remoteId.equals(remote.id)))
          .getSingleOrNull();

      if (local == null) {
        debugPrint('🔄 SYNC: DebtTransaction not in local DB, looking up friend...');
        // Need to find the local friendId from remote friendId
        final friend = await (_db.select(_db.friends)
              ..where((f) => f.remoteId.equals(remote.friendId)))
            .getSingleOrNull();
        final localFriendId = friend?.localId ?? 0;
        debugPrint('🔄 SYNC: Friend lookup: remoteFriendId=${remote.friendId} -> localFriendId=$localFriendId');

        if (localFriendId > 0) {
          debugPrint('🔄 SYNC: ✅ Inserting debtTransaction into local DB');
          await _db.into(_db.debtTransactions).insert(
                DebtTransactionsCompanion.insert(
                  remoteId: Value(remote.id),
                  userId: remote.userId,
                  friendId: localFriendId,
                  amount: remote.amount,
                  type: remote.type,
                  date: remote.date,
                  note: Value(remote.note),
                  createdAtLocal: remote.createdAt,
                  updatedAtLocal: remote.updatedAt,
                  syncStatus: const Value('synced'),
                ),
              );
        }
      } else if (remote.updatedAt.isAfter(local.updatedAtLocal)) {
        await (_db.update(_db.debtTransactions)..where((d) => d.localId.equals(local.localId)))
            .write(DebtTransactionsCompanion(
              amount: Value(remote.amount),
              type: Value(remote.type),
              date: Value(remote.date),
              note: Value(remote.note),
              updatedAtLocal: Value(remote.updatedAt),
              syncStatus: const Value('synced'),
              deleted: const Value(false),
            ));
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
  ref.onDispose(() => service.dispose());
  return service;
});
