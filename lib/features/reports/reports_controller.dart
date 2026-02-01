import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/transaction_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../debts/models/debt_transaction_model.dart';
import '../debts/providers/debts_provider.dart';

class ReportState {
  final DateTime startDate;
  final DateTime endDate;
  final bool isLoading;

  ReportState({
    required this.startDate,
    required this.endDate,
    this.isLoading = false,
  });

  ReportState copyWith({
    DateTime? startDate,
    DateTime? endDate,
    bool? isLoading,
  }) {
    return ReportState(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ReportsController extends Notifier<ReportState> {
  @override
  ReportState build() {
    return ReportState(
      startDate: DateTime(DateTime.now().year, DateTime.now().month, 1),
      endDate: DateTime.now(),
    );
  }

  void setDateRange(DateTime start, DateTime end) {
    state = state.copyWith(startDate: start, endDate: end);
  }
}

final reportsControllerProvider =
    NotifierProvider<ReportsController, ReportState>(ReportsController.new);

final filteredTransactionsProvider = StreamProvider<List<TransactionModel>>((
  ref,
) {
  final reportState = ref.watch(reportsControllerProvider);
  final user = ref.watch(authServiceProvider).currentUser;

  if (user == null) return Stream.value([]);

  return ref
      .watch(firestoreServiceProvider)
      .getFilteredTransactions(
        user.uid,
        reportState.startDate,
        reportState.endDate,
      );
});

/// Provider for filtered debt transactions based on selected date range
final filteredDebtTransactionsProvider = Provider<AsyncValue<List<DebtTransactionModel>>>((ref) {
  final reportState = ref.watch(reportsControllerProvider);
  final debtTransactionsAsync = ref.watch(debtTransactionsStreamProvider);

  return debtTransactionsAsync.whenData((debtTransactions) {
    // Filter debt transactions by date range
    return debtTransactions.where((dt) {
      return dt.date.isAfter(reportState.startDate.subtract(const Duration(days: 1))) &&
             dt.date.isBefore(reportState.endDate.add(const Duration(days: 1)));
    }).toList();
  });
});

final reportSummaryProvider = Provider<AsyncValue<Map<String, dynamic>>>((ref) {
  final transactionsAsync = ref.watch(filteredTransactionsProvider);
  final debtTransactionsAsync = ref.watch(filteredDebtTransactionsProvider);

  // Check loading states
  if (transactionsAsync.isLoading || debtTransactionsAsync.isLoading) {
    return const AsyncValue.loading();
  }

  // Check for errors
  if (transactionsAsync.hasError) {
    return AsyncValue.error(transactionsAsync.error!, transactionsAsync.stackTrace!);
  }
  if (debtTransactionsAsync.hasError) {
    return AsyncValue.error(debtTransactionsAsync.error!, debtTransactionsAsync.stackTrace!);
  }

  final transactions = transactionsAsync.value ?? [];
  final debtTransactions = debtTransactionsAsync.value ?? [];

  // Compute transaction stats
  double totalIncome = 0;
  double totalExpense = 0;
  Map<String, double> categoryTotals = {};
  Map<String, String> categoryIcons = {};

  for (var tx in transactions) {
    if (tx.type == 'income') {
      totalIncome += tx.amount;
    } else {
      totalExpense += tx.amount;
    }

    categoryTotals[tx.categoryName] =
        (categoryTotals[tx.categoryName] ?? 0) + tx.amount;
    categoryIcons[tx.categoryName] = tx.categoryIcon;
  }

  // Compute debt stats for the period
  double totalBorrowed = 0;  // What I borrowed (I owe others)
  double totalLent = 0;      // What I lent (others owe me)

  for (var dt in debtTransactions) {
    switch (dt.type) {
      case DebtEventType.borrow:
        totalBorrowed += dt.amount;
        break;
      case DebtEventType.lend:
        totalLent += dt.amount;
        break;
      case DebtEventType.settlePay:
      case DebtEventType.settleReceive:
        // Skip settlement types - not tracked in reports
        break;
    }
  }

  // Net debt: positive means others owe me, negative means I owe others
  final netDebtInPeriod = totalLent - totalBorrowed;

  return AsyncValue.data({
    'totalIncome': totalIncome,
    'totalExpense': totalExpense,
    'netBalance': totalIncome - totalExpense,
    'categoryTotals': categoryTotals,
    'categoryIcons': categoryIcons,
    'transactions': transactions,
    // Debt data
    'debtTransactions': debtTransactions,
    'totalBorrowed': totalBorrowed,
    'totalLent': totalLent,
    'netDebtInPeriod': netDebtInPeriod,
    'hasDebtData': debtTransactions.isNotEmpty,
  });
});
