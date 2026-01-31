import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../core/models/transaction_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/icon_helper.dart';
import '../../core/localization/translation_helper.dart';
import '../../core/theme/theme_provider.dart';
import '../../services/firestore_service.dart';
import '../../core/providers/currency_provider.dart';
import 'new_transaction_screen.dart';

class TransactionDetailsScreen extends ConsumerStatefulWidget {
  final TransactionModel transaction;

  const TransactionDetailsScreen({super.key, required this.transaction});

  @override
  ConsumerState<TransactionDetailsScreen> createState() =>
      _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState
    extends ConsumerState<TransactionDetailsScreen> {
  bool _isDeleting = false;
  late int? _localId;

  @override
  void initState() {
    super.initState();
    _localId = widget.transaction.localId;
  }

  Future<void> _handleDelete() async {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          l10n.deleteTransaction,
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        content: Text(
          l10n.deleteTransactionConfirm,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isDeleting = true);
      try {
        // Use localId for deletion if available, otherwise use id
        final idToDelete = _localId?.toString() ?? widget.transaction.id;
        await ref
            .read(firestoreServiceProvider)
            .deleteTransaction(idToDelete);
        if (mounted) {
          context.pop(); // Go back to history or home
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.transactionDeleted)));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('${l10n.error}: $e')));
        }
      } finally {
        if (mounted) setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeProvider);
    final currencyModel = ref.watch(currencyProvider);
    final currency = NumberFormat.simpleCurrency(name: currencyModel.code);
    final dateFormat = DateFormat.yMMMMEEEEd().add_jm();
    final locale = Localizations.localeOf(context).languageCode;

    // Watch the transaction reactively if we have a localId
    final transactionAsync = _localId != null
        ? ref.watch(transactionByIdProvider(_localId!))
        : null;

    // Use the watched transaction or fall back to the initial one
    final tx = transactionAsync?.value ?? widget.transaction;
    final isIncome = tx.type == 'income';
    final color = isIncome ? AppColors.income : AppColors.expense;

    final displayTitle =
        (locale == 'ar' && tx.titleAr != null && tx.titleAr!.isNotEmpty)
        ? tx.titleAr!
        : tx.title;

    final displayCategory = TranslationHelper.getCategoryName(
      context,
      tx.categoryName,
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Theme-based background
          if (themeMode == AppThemeMode.glassy)
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0F172A),
                      Color(0xFF1E1B4B),
                      Color(0xFF312E81),
                    ],
                  ),
                ),
              ),
            ),

          // Decorative background elements
          if (themeMode != AppThemeMode.glassy) ...[
            Positioned(
              top: -50,
              left: -50,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.05),
                ),
              ),
            ),
            Positioned(
              top: 150,
              right: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.primaryColor.withValues(alpha: 0.03),
                ),
              ),
            ),
          ],

          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context, l10n, theme, tx),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),

                        // Main Transaction Card
                        _buildMainCard(
                          theme,
                          tx,
                          isIncome,
                          color,
                          currency,
                          displayTitle,
                          displayCategory,
                          themeMode,
                        ),

                        const SizedBox(height: 32),

                        // Details section
                        _buildDetailsContainer(
                          l10n,
                          theme,
                          tx,
                          isIncome,
                          color,
                          dateFormat,
                          themeMode,
                        ),

                        const SizedBox(height: 40),

                        // Delete Button
                        _buildDeleteButton(l10n, theme),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    TransactionModel tx,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              color: theme.colorScheme.onSurface,
              onPressed: () => context.pop(),
            ),
          ),
          Text(
            l10n.transactionDetails,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.edit_rounded, size: 20),
              color: theme.colorScheme.onSurface,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        NewTransactionScreen(transaction: tx),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainCard(
    ThemeData theme,
    TransactionModel tx,
    bool isIncome,
    Color color,
    NumberFormat currency,
    String title,
    String category,
    AppThemeMode themeMode,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(30),
        border: themeMode == AppThemeMode.glassy
            ? Border.all(color: Colors.white.withValues(alpha: 0.2))
            : null,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              IconHelper.getIcon(tx.categoryIcon),
              size: 40,
              color: color,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            category,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              '${isIncome ? '+' : '-'}${currency.format(tx.amount)}',
              style: theme.textTheme.displaySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsContainer(
    AppLocalizations l10n,
    ThemeData theme,
    TransactionModel tx,
    bool isIncome,
    Color color,
    DateFormat dateFormat,
    AppThemeMode themeMode,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: themeMode == AppThemeMode.glassy
            ? Border.all(color: Colors.white.withValues(alpha: 0.1))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildDetailItem(
            l10n.date,
            dateFormat.format(tx.createdAt),
            Icons.calendar_today_rounded,
            theme,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: theme.dividerColor),
          ),
          _buildDetailItem(
            l10n.type,
            TranslationHelper.getTransactionType(context, tx.type),
            isIncome
                ? Icons.arrow_downward_rounded
                : Icons.arrow_upward_rounded,
            theme,
            valueColor: color,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: theme.dividerColor),
          ),
          _buildDetailItem(
            l10n.category,
            TranslationHelper.getCategoryName(context, tx.categoryName),
            Icons.category_rounded,
            theme,
          ),
          if (tx.id.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1, color: theme.dividerColor),
            ),
            _buildDetailItem(
              l10n.transactionId, // Using localization
              tx.id.length > 8
                  ? '${tx.id.substring(0, 8).toUpperCase()}...'
                  : tx.id.toUpperCase(),
              Icons.tag_rounded,
              theme,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailItem(
    String label,
    String value,
    IconData icon,
    ThemeData theme, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: valueColor ?? theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeleteButton(AppLocalizations l10n, ThemeData theme) {
    return OutlinedButton.icon(
      onPressed: _isDeleting ? null : _handleDelete,
      icon: _isDeleting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.delete_outline_rounded, color: AppColors.error),
      label: Text(
        l10n.deleteTransaction,
        style: const TextStyle(
          color: AppColors.error,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
