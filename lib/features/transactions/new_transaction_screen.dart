import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../core/models/transaction_model.dart';
import '../../core/theme/app_colors.dart';

import '../../core/utils/icon_helper.dart';

import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../core/models/category_model.dart';
import '../categories/add_edit_category_screen.dart';
import '../../core/theme/theme_provider.dart';

class NewTransactionScreen extends ConsumerStatefulWidget {
  final TransactionModel? transaction;

  const NewTransactionScreen({super.key, this.transaction});

  @override
  ConsumerState<NewTransactionScreen> createState() =>
      _NewTransactionScreenState();
}

class _NewTransactionScreenState extends ConsumerState<NewTransactionScreen> {
  String _type = 'expense'; // expense or income
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();
  final _titleArController =
      TextEditingController(); // Added controller for Arabic title
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  String? _selectedCategoryIcon;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      final tx = widget.transaction!;
      _type = tx.type;
      _amountController.text = tx.amount.toString();
      _titleController.text = tx.title;
      _titleArController.text = tx.titleAr ?? '';
      _selectedCategoryId = tx.categoryId;
      _selectedCategoryName = tx.categoryName;
      _selectedCategoryIcon = tx.categoryIcon;
      _selectedDate = tx.createdAt;
    } else {
      _amountController.text = ''; // Start empty for better UX
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _titleArController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, ThemeData theme) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: theme.primaryColor,
              onPrimary: theme.colorScheme.onPrimary,
              onSurface: theme.colorScheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _navigateToAddCategory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            const AddEditCategoryScreen(fromNewTransaction: true),
      ),
    );
  }

  Future<void> _handleSave() async {
    final l10n = AppLocalizations.of(context);

    // Validate fields
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.pleaseEnterAmount)));
      return;
    }

    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.pleaseEnterTitle)));
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.pleaseSelectCategory)));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = ref.read(authServiceProvider).currentUser;
      if (user == null) return;

      final transaction = TransactionModel(
        id: widget.transaction?.id ?? '', // Use existing ID if editing
        userId: user.uid,
        title: _titleController.text,
        titleAr: _titleArController.text.isNotEmpty
            ? _titleArController.text
            : null,
        amount: amount,
        type: _type,
        categoryId: _selectedCategoryId!,
        categoryName: _selectedCategoryName!,
        categoryIcon: _selectedCategoryIcon!,
        createdAt: _selectedDate,
        updatedAt: DateTime.now(),
      );

      if (widget.transaction != null) {
        // Use the localId directly from the transaction model
        final localId = widget.transaction!.localId;
        await ref.read(firestoreServiceProvider).updateTransaction(
          transaction,
          localId: localId,
        );
      } else {
        await ref.read(firestoreServiceProvider).addTransaction(transaction);
      }
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.transaction != null
                  ? l10n.transactionUpdated
                  : l10n.transactionAdded,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${l10n.error}: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeProvider);
    final isGlassy = themeMode == AppThemeMode.glassy;
    final isModernDark = themeMode == AppThemeMode.modernDark;
    final isExpense = _type == 'expense';
    final activeColor = isExpense ? AppColors.expense : AppColors.income;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background for Glassy
          if (isGlassy)
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

          // Decorative background elements for other themes
          if (!isGlassy) ...[
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: activeColor.withValues(alpha: 0.05),
                ),
              ),
            ),
            Positioned(
              bottom: 200,
              left: -30,
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
                _buildAppBar(context, l10n, theme, isGlassy),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 130),
                    child: Column(
                      children: [
                        // Type Toggle
                        _buildTypeToggle(l10n, activeColor, theme, isGlassy),
                        const SizedBox(height: 32),

                        // Amount Input
                        _buildAmountInput(theme, activeColor, isGlassy),
                        const SizedBox(height: 32),

                        // Input Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isGlassy
                                ? Colors.white.withValues(alpha: 0.1)
                                : theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(24),
                            border: isGlassy
                                ? Border.all(
                                    color: Colors.white.withValues(alpha: 0.1),
                                  )
                                : (isModernDark
                                      ? Border.all(
                                          color: theme.dividerColor.withValues(
                                            alpha: 0.1,
                                          ),
                                        )
                                      : null),
                            boxShadow: isGlassy || isModernDark
                                ? null
                                : [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.02,
                                      ),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Date Selection
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildDateButton(
                                      theme,
                                      l10n,
                                      isGlassy,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Title Input (English)
                              CustomTextField(
                                hintText: l10n.enterTitleEn,
                                controller: _titleController,
                                prefixIcon: Icon(
                                  Icons.edit_outlined,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Title Input (Arabic)
                              CustomTextField(
                                hintText: l10n.enterTitleAr,
                                controller: _titleArController,
                                prefixIcon: Icon(
                                  Icons.translate,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Categories Section
                        _buildCategoriesHeader(l10n, theme, isGlassy),
                        const SizedBox(height: 16),
                        _buildCategoryGrid(categoriesAsync, theme, isGlassy),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Save Button
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: PrimaryButton(
                text: widget.transaction != null ? l10n.save : l10n.save,
                onPressed: _handleSave,
                isLoading: _isLoading,
              ),
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
    bool isGlassy,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isGlassy
                  ? Colors.white.withValues(alpha: 0.1)
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: isGlassy
                  ? Border.all(color: Colors.white.withValues(alpha: 0.1))
                  : null,
              boxShadow: isGlassy
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: IconButton(
              icon: Icon(
                Icons.close_rounded,
                size: 24,
                color: isGlassy ? Colors.white : theme.colorScheme.onSurface,
              ),
              onPressed: () => context.pop(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.transaction != null
                      ? l10n.editTransaction
                      : l10n.newTransaction,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isGlassy
                        ? Colors.white
                        : theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  l10n.manageTransactions,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isGlassy
                        ? Colors.white.withValues(alpha: 0.6)
                        : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton(
    ThemeData theme,
    AppLocalizations l10n,
    bool isGlassy,
  ) {
    return InkWell(
      onTap: () => _selectDate(context, theme),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isGlassy
              ? Colors.white.withValues(alpha: 0.05)
              : theme.colorScheme.surface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isGlassy
                ? Colors.white.withValues(alpha: 0.1)
                : theme.dividerColor.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 20,
              color: isGlassy ? Colors.white : theme.primaryColor,
            ),
            const SizedBox(width: 12),
            Text(
              DateFormat.yMMMd(
                Localizations.localeOf(context).toString(),
              ).format(_selectedDate),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isGlassy ? Colors.white : theme.colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: isGlassy
                  ? Colors.white.withValues(alpha: 0.4)
                  : theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeToggle(
    AppLocalizations l10n,
    Color activeColor,
    ThemeData theme,
    bool isGlassy,
  ) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isGlassy
            ? Colors.white.withValues(alpha: 0.1)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: isGlassy
            ? Border.all(color: Colors.white.withValues(alpha: 0.1))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTypeButton(
              'expense',
              l10n.expenseType,
              activeColor,
              _type == 'expense',
              theme,
              isGlassy,
            ),
          ),
          Expanded(
            child: _buildTypeButton(
              'income',
              l10n.income,
              activeColor,
              _type == 'income',
              theme,
              isGlassy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(
    String type,
    String label,
    Color color,
    bool isActive,
    ThemeData theme,
    bool isGlassy,
  ) {
    return GestureDetector(
      onTap: () => setState(() => _type = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isActive
                  ? Colors.white
                  : (isGlassy
                        ? Colors.white.withValues(alpha: 0.6)
                        : theme.colorScheme.onSurface.withValues(alpha: 0.6)),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountInput(ThemeData theme, Color activeColor, bool isGlassy) {
    return Column(
      children: [
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: theme.textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isGlassy ? Colors.white : theme.colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: '0.00',
            hintStyle: TextStyle(
              color: isGlassy
                  ? Colors.white.withValues(alpha: 0.2)
                  : theme.colorScheme.onSurface.withValues(alpha: 0.1),
            ),
            border: InputBorder.none,
            prefixText: '₪ ',
            prefixStyle: theme.textTheme.headlineLarge?.copyWith(
              color: activeColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesHeader(
    AppLocalizations l10n,
    ThemeData theme,
    bool isGlassy,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          l10n.category,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isGlassy ? Colors.white : theme.colorScheme.onSurface,
          ),
        ),
        TextButton.icon(
          onPressed: _navigateToAddCategory,
          icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
          label: Text(l10n.addCategory),
          style: TextButton.styleFrom(
            foregroundColor: isGlassy ? Colors.white : theme.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryGrid(
    AsyncValue<List<CategoryModel>> categoriesAsync,
    ThemeData theme,
    bool isGlassy,
  ) {
    return categoriesAsync.when(
      data: (categories) {
        final filteredCategories = categories
            .where((c) => c.type == _type || c.type == 'both')
            .toList();

        if (filteredCategories.isEmpty) {
          return Center(
            child: Text(
              'No categories found',
              style: TextStyle(
                color: isGlassy
                    ? Colors.white.withValues(alpha: 0.5)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: filteredCategories.length,
          itemBuilder: (context, index) {
            final category = filteredCategories[index];
            final isSelected = _selectedCategoryId == category.id;
            final locale = Localizations.localeOf(context).languageCode;
            final displayName =
                (locale == 'ar' && (category.nameAr?.isNotEmpty ?? false))
                ? category.nameAr!
                : category.name;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategoryId = category.id;
                  _selectedCategoryName = category.name;
                  _selectedCategoryIcon = category.icon;
                });
              },
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (_type == 'expense'
                                ? AppColors.expense
                                : AppColors.income)
                          : (isGlassy
                                ? Colors.white.withValues(alpha: 0.05)
                                : theme.colorScheme.surface),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : (isGlassy
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : theme.dividerColor.withValues(alpha: 0.1)),
                      ),
                      boxShadow: isSelected || isGlassy
                          ? null
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Icon(
                      IconHelper.getIcon(category.icon),
                      color: isSelected
                          ? Colors.white
                          : (isGlassy
                                ? Colors.white
                                : theme.colorScheme.onSurface),
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    displayName,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isGlassy
                          ? Colors.white.withValues(alpha: isSelected ? 1 : 0.7)
                          : theme.colorScheme.onSurface.withValues(
                              alpha: isSelected ? 1 : 0.6,
                            ),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}
