import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../core/models/category_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/localization/translation_helper.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/primary_button.dart';

import '../../services/firestore_service.dart';

class AddEditCategoryScreen extends ConsumerStatefulWidget {
  final CategoryModel? category; // null = add mode, non-null = edit mode
  final bool fromNewTransaction; // If true, came from new transaction screen

  const AddEditCategoryScreen({
    super.key,
    this.category,
    this.fromNewTransaction = false,
  });

  @override
  ConsumerState<AddEditCategoryScreen> createState() =>
      _AddEditCategoryScreenState();
}

class _AddEditCategoryScreenState extends ConsumerState<AddEditCategoryScreen> {
  final _nameController = TextEditingController();
  final _nameArController = TextEditingController();
  String _selectedType = 'expense';
  String _selectedIcon = 'other';
  bool _isLoading = false;

  bool get isEditMode => widget.category != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      _nameController.text = widget.category!.name;
      _nameArController.text = widget.category!.nameAr ?? '';
      _selectedType = widget.category!.type;
      _selectedIcon = widget.category!.icon;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameArController.dispose();
    super.dispose();
  }

  // Available icons with localized labels
  List<Map<String, dynamic>> _getIconOptions(AppLocalizations l10n) {
    return [
      {'name': 'food', 'icon': Icons.fastfood_rounded, 'label': l10n.cat_food},
      {
        'name': 'shopping',
        'icon': Icons.shopping_bag_rounded,
        'label': l10n.cat_shopping,
      },
      {
        'name': 'transportation',
        'icon': Icons.directions_car_rounded,
        'label': l10n.cat_transportation,
      },
      {
        'name': 'entertainment',
        'icon': Icons.movie_rounded,
        'label': l10n.cat_entertainment,
      },
      {
        'name': 'bills',
        'icon': Icons.receipt_long_rounded,
        'label': l10n.cat_bills,
      },
      {
        'name': 'income',
        'icon': Icons.payments_rounded,
        'label': l10n.cat_income,
      },
      {'name': 'home', 'icon': Icons.home_rounded, 'label': l10n.cat_home},
      {
        'name': 'hair cut',
        'icon': Icons.content_cut_rounded,
        'label': l10n.cat_haircut,
      },
      {
        'name': 'health',
        'icon': Icons.medical_services_rounded,
        'label': l10n.cat_health,
      },
      {
        'name': 'education',
        'icon': Icons.school_rounded,
        'label': l10n.cat_education,
      },
      {
        'name': 'travel',
        'icon': Icons.flight_rounded,
        'label': l10n.cat_travel,
      },
      {
        'name': 'gift',
        'icon': Icons.card_giftcard_rounded,
        'label': l10n.cat_gift,
      },
      {
        'name': 'salary',
        'icon': Icons.account_balance_wallet_rounded,
        'label': l10n.cat_salary,
      },
      {
        'name': 'investment',
        'icon': Icons.trending_up_rounded,
        'label': l10n.cat_investment,
      },
      {
        'name': 'freelance',
        'icon': Icons.work_rounded,
        'label': l10n.cat_freelance,
      },
      {
        'name': 'other',
        'icon': Icons.more_horiz_rounded,
        'label': l10n.cat_other,
      },
    ];
  }

  Future<void> _handleSave() async {
    final l10n = AppLocalizations.of(context);

    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.enterCategoryName)));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final category = CategoryModel(
        id: isEditMode ? widget.category!.id : '',
        name: _nameController.text.trim(),
        nameAr: _nameArController.text.trim().isNotEmpty
            ? _nameArController.text.trim()
            : null,
        icon: _selectedIcon,
        type: _selectedType,
        updatedAt: DateTime.now(),
      );

      if (isEditMode) {
        await ref.read(firestoreServiceProvider).updateCategory(category);
      } else {
        await ref.read(firestoreServiceProvider).addCategory(category);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditMode ? l10n.categoryUpdated : l10n.categoryAdded,
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

  Future<void> _handleDelete() async {
    final l10n = AppLocalizations.of(context);
    final displayName = TranslationHelper.getCategoryName(
      context,
      widget.category!.name,
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.deleteCategoryConfirm(displayName)),
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

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await ref
            .read(firestoreServiceProvider)
            .deleteCategory(widget.category!.id);
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.categoryDeleted)));
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
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final iconOptions = _getIconOptions(l10n);
    final activeColor = _selectedType == 'income'
        ? AppColors.income
        : AppColors.expense;

    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Decorative background elements
          Positioned(
            top: -60,
            left: -60,
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
            bottom: 150,
            right: -40,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.03),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context, l10n, theme, themeMode),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon Preview
                        Center(child: _buildIconPreview(activeColor)),
                        const SizedBox(height: 32),

                        // Form Card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: themeMode == AppThemeMode.glassy
                                ? Colors.white.withValues(alpha: 0.05)
                                : theme.cardColor,
                            borderRadius: BorderRadius.circular(24),
                            border: themeMode == AppThemeMode.glassy
                                ? Border.all(
                                    color: Colors.white.withValues(alpha: 0.1),
                                  )
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.enterCategoryNameEn,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 12),
                              CustomTextField(
                                hintText: l10n.enterCategoryName,
                                controller: _nameController,
                                prefixIcon: Icon(
                                  Icons.label_rounded,
                                  color:
                                      theme.iconTheme.color?.withValues(
                                        alpha: 0.5,
                                      ) ??
                                      Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                l10n.enterCategoryNameAr,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 12),
                              CustomTextField(
                                hintText: l10n.enterCategoryNameAr,
                                controller: _nameArController,
                                prefixIcon: Icon(
                                  Icons.translate_rounded,
                                  color:
                                      theme.iconTheme.color?.withValues(
                                        alpha: 0.5,
                                      ) ??
                                      Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Type Selection
                        Text(
                          l10n.type,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildTypeToggle(
                          l10n,
                          themeMode: themeMode,
                          theme: theme,
                        ),
                        const SizedBox(height: 32),

                        // Icon Grid
                        Text(
                          l10n.selectIcon,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildIconGrid(
                          iconOptions,
                          themeMode: themeMode,
                          theme: theme,
                        ),
                        const SizedBox(height: 40),

                        // Save Button
                        PrimaryButton(
                          text: isEditMode ? l10n.save : l10n.addCategory,
                          onPressed: _handleSave,
                          isLoading: _isLoading,
                        ),
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
    AppThemeMode themeMode,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            decoration: BoxDecoration(
              color: themeMode == AppThemeMode.glassy
                  ? Colors.white.withValues(alpha: 0.1)
                  : theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: themeMode == AppThemeMode.glassy
                  ? Border.all(color: Colors.white.withValues(alpha: 0.1))
                  : null,
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
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Text(
            isEditMode ? l10n.editCategory : l10n.addCategory,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          if (isEditMode)
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.error,
              ),
              onPressed: _isLoading ? null : _handleDelete,
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildIconPreview(Color activeColor) {
    final iconData =
        _getIconOptions(
              AppLocalizations.of(context),
            ).firstWhere((e) => e['name'] == _selectedIcon)['icon']
            as IconData;

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: activeColor.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: activeColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(iconData, size: 36, color: activeColor),
        ),
      ),
    );
  }

  Widget _buildTypeToggle(
    AppLocalizations l10n, {
    required AppThemeMode themeMode,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: themeMode == AppThemeMode.glassy
            ? Colors.black.withValues(alpha: 0.1)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedType = 'expense'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedType == 'expense'
                      ? (themeMode == AppThemeMode.glassy
                            ? Colors.white.withValues(alpha: 0.2)
                            : theme.cardColor)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: _selectedType == 'expense'
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    l10n.expenseType,
                    style: TextStyle(
                      color: _selectedType == 'expense'
                          ? AppColors.expense
                          : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedType = 'income'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedType == 'income'
                      ? (themeMode == AppThemeMode.glassy
                            ? Colors.white.withValues(alpha: 0.2)
                            : theme.cardColor)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: _selectedType == 'income'
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    l10n.incomeType,
                    style: TextStyle(
                      color: _selectedType == 'income'
                          ? AppColors.income
                          : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconGrid(
    List<Map<String, dynamic>> options, {
    required AppThemeMode themeMode,
    required ThemeData theme,
  }) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.9,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final option = options[index];
        final isSelected = _selectedIcon == option['name'];
        final color = _selectedType == 'income'
            ? AppColors.income
            : AppColors.expense;

        return GestureDetector(
          onTap: () => setState(() => _selectedIcon = option['name']),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color
                      : (themeMode == AppThemeMode.glassy
                            ? Colors.white.withValues(alpha: 0.1)
                            : theme.cardColor),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    else
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Icon(
                  option['icon'],
                  size: 24,
                  color: isSelected
                      ? Colors.white
                      : theme.iconTheme.color?.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                option['label'],
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected
                      ? color
                      : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
  }
}
