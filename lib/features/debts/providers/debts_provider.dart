import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/auth_service.dart';
import '../repositories/debts_repository.dart';
import '../models/friend_model.dart';
import '../models/debt_transaction_model.dart';

final rawFriendsStreamProvider = StreamProvider<List<FriendModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final userId = authState.value?.uid;
  if (userId == null) return Stream.value([]);

  return ref.watch(debtsRepositoryProvider).watchFriends(userId);
});

final debtTransactionsStreamProvider =
    StreamProvider<List<DebtTransactionModel>>((ref) {
      final authState = ref.watch(authStateProvider);
      final userId = authState.value?.uid;
      if (userId == null) return Stream.value([]);

      return ref.watch(debtsRepositoryProvider).watchDebtTransactions(userId);
    });

final friendsProvider = Provider<AsyncValue<List<FriendModel>>>((ref) {
  final friendsAsync = ref.watch(rawFriendsStreamProvider);
  final transactionsAsync = ref.watch(debtTransactionsStreamProvider);

  if (friendsAsync.isLoading || transactionsAsync.isLoading) {
    return const AsyncValue.loading();
  }

  if (friendsAsync.hasError) {
    return AsyncValue.error(friendsAsync.error!, friendsAsync.stackTrace!);
  }
  if (transactionsAsync.hasError) {
    return AsyncValue.error(
      transactionsAsync.error!,
      transactionsAsync.stackTrace!,
    );
  }

  final friends = friendsAsync.value ?? [];
  final transactions = transactionsAsync.value ?? [];

  final updatedFriends = friends.map((f) {
    double iOwe = 0;
    double owesMe = 0;
    // Filter transactions for this friend
    final friendTx = transactions.where((t) => t.friendId == f.id);

    for (var t in friendTx) {
      switch (t.type) {
        case DebtEventType.borrow:
          iOwe += t.amount;
          break;
        case DebtEventType.lend:
          owesMe += t.amount;
          break;
        case DebtEventType.settlePay:
          iOwe -= t.amount;
          break;
        case DebtEventType.settleReceive:
          owesMe -= t.amount;
          break;
      }
    }

    // Net balance: positive means they owe me, negative means I owe them
    final netBalance = owesMe - iOwe;

    return FriendModel(
      id: f.id,
      userId: f.userId,
      name: f.name,
      phoneNumber: f.phoneNumber,
      createdAt: f.createdAt,
      updatedAt: f.updatedAt,
      netBalance: netBalance,
      iOwe: iOwe > 0 ? iOwe : 0,
      owesMe: owesMe > 0 ? owesMe : 0,
    );
  }).toList();

  return AsyncValue.data(updatedFriends);
});

final friendDetailsProvider = Provider.family<AsyncValue<FriendModel>, String>((
  ref,
  friendId,
) {
  final friendsAsync = ref.watch(friendsProvider);

  return friendsAsync.when(
    data: (friends) {
      final friend = friends.firstWhere(
        (f) => f.id == friendId,
        orElse: () => throw Exception('Friend not found'),
      );
      return AsyncValue.data(friend);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
  );
});

final friendTransactionsProvider =
    Provider.family<AsyncValue<List<DebtTransactionModel>>, String>((
      ref,
      friendId,
    ) {
      final transactionsAsync = ref.watch(debtTransactionsStreamProvider);

      return transactionsAsync.when(
        data: (transactions) {
          final friendTx = transactions
              .where((t) => t.friendId == friendId)
              .toList();
          return AsyncValue.data(friendTx);
        },
        loading: () => const AsyncValue.loading(),
        error: (e, s) => AsyncValue.error(e, s),
      );
    });
