import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/transaction_model.dart';
import '../core/models/category_model.dart';
import '../core/models/user_model.dart';
import '../data/repositories/transaction_repository.dart';
import '../data/repositories/category_repository.dart';
import '../data/remote/firestore_service.dart' as remote;
import 'auth_service.dart';

// Bridge providers for backwards compatibility with existing UI
final transactionsProvider = transactionsStreamProvider;
final categoriesProvider = categoriesStreamProvider;

final userProfileProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  final uid = authState.value?.uid;
  if (uid == null) return Stream.value(null);
  return ref.watch(remote.firestoreServiceProvider).getUserStream(uid);
});

final firestoreServiceProvider = Provider((ref) => FirestoreBridge(ref));

class FirestoreBridge {
  final Ref _ref;
  FirestoreBridge(this._ref);

  Future<void> addTransaction(TransactionModel transaction) {
    return _ref.read(transactionRepositoryProvider).addTransaction(transaction);
  }

  Future<void> updateTransaction(TransactionModel transaction, {int? localId}) {
    if (localId != null) {
      return _ref
          .read(transactionRepositoryProvider)
          .updateTransaction(transaction, localId);
    }
    return Future.value();
  }

  Future<void> deleteTransaction(String id) {
    return _ref.read(transactionRepositoryProvider).deleteTransaction(id);
  }

  Future<void> seedDefaultCategories(String userId) {
    return _ref.read(categoryRepositoryProvider).seedDefaultCategories(userId);
  }

  Future<void> addCategory(CategoryModel category) {
    return _ref.read(categoryRepositoryProvider).addCategory(category);
  }

  Future<void> updateCategory(CategoryModel category) {
    return _ref.read(categoryRepositoryProvider).updateCategory(category);
  }

  Future<void> deleteCategory(String id) {
    return _ref.read(categoryRepositoryProvider).deleteCategory(id);
  }

  Future<void> createUser(UserModel user) {
    return _ref.read(remote.firestoreServiceProvider).createUser(user);
  }

  Future<void> updateUser(UserModel user) {
    return _ref.read(remote.firestoreServiceProvider).updateUser(user);
  }

  Stream<List<TransactionModel>> getFilteredTransactions(
    String userId,
    DateTime start,
    DateTime end,
  ) {
    return _ref
        .read(transactionRepositoryProvider)
        .watchTransactions(userId)
        .map((list) {
          final adjustedEnd = DateTime(
            end.year,
            end.month,
            end.day,
            23,
            59,
            59,
            999,
          );
          final adjustedStart = DateTime(
            start.year,
            start.month,
            start.day,
            0,
            0,
            0,
            0,
          );

          return list
              .where(
                (t) =>
                    (t.createdAt.isAfter(adjustedStart) ||
                        t.createdAt.isAtSameMomentAs(adjustedStart)) &&
                    (t.createdAt.isBefore(adjustedEnd) ||
                        t.createdAt.isAtSameMomentAs(adjustedEnd)),
              )
              .toList();
        });
  }
}
