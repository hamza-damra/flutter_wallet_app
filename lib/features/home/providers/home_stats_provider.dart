import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_service.dart';
import '../../debts/providers/debts_provider.dart';

/// Model class to hold computed home statistics
class HomeStats {
  final double totalBalance;
  final double income;
  final double expense;
  final double debtBalance;
  final bool isLoading;
  final Object? error;

  const HomeStats({
    this.totalBalance = 0,
    this.income = 0,
    this.expense = 0,
    this.debtBalance = 0,
    this.isLoading = false,
    this.error,
  });

  HomeStats copyWith({
    double? totalBalance,
    double? income,
    double? expense,
    double? debtBalance,
    bool? isLoading,
    Object? error,
  }) {
    return HomeStats(
      totalBalance: totalBalance ?? this.totalBalance,
      income: income ?? this.income,
      expense: expense ?? this.expense,
      debtBalance: debtBalance ?? this.debtBalance,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Provider that computes home statistics reactively from transactions and debts
final homeStatsProvider = Provider<AsyncValue<HomeStats>>((ref) {
  final authState = ref.watch(authStateProvider);
  final userId = authState.value?.uid;

  if (userId == null) {
    return const AsyncValue.data(HomeStats());
  }

  final transactionsAsync = ref.watch(transactionsProvider(userId));
  final debtTransactionsAsync = ref.watch(debtTransactionsStreamProvider);

  // Check loading states
  if (transactionsAsync.isLoading || debtTransactionsAsync.isLoading) {
    return const AsyncValue.loading();
  }

  // Check for errors
  if (transactionsAsync.hasError) {
    return AsyncValue.error(
      transactionsAsync.error!,
      transactionsAsync.stackTrace!,
    );
  }
  if (debtTransactionsAsync.hasError) {
    return AsyncValue.error(
      debtTransactionsAsync.error!,
      debtTransactionsAsync.stackTrace!,
    );
  }

  // Compute stats from transactions
  double income = 0;
  double expense = 0;

  final transactions = transactionsAsync.value ?? [];
  for (var tx in transactions) {
    if (tx.type == 'income') {
      income += tx.amount;
    } else {
      expense += tx.amount;
    }
  }

  // Compute debt balance (excluding settled debts)
  double debtBalance = 0;
  final debtTransactions = debtTransactionsAsync.value ?? [];
  for (var dt in debtTransactions) {
    // Only count unsettled debts
    if (dt.settled) continue;

    if (dt.type == 'lent') {
      debtBalance += dt.amount;
    } else {
      debtBalance -= dt.amount;
    }
  }

  // Total balance = income - expense + debt balance
  // Debt balance: positive means others owe you, negative means you owe others
  final totalBalance = (income - expense) + debtBalance;

  return AsyncValue.data(HomeStats(
    totalBalance: totalBalance,
    income: income,
    expense: expense,
    debtBalance: debtBalance,
  ));
});
