import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../core/models/category_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/localization/translation_helper.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/primary_button.dart';

import '../../services/firestore_service.dart';

class AddEditCategoryScreen extends ConsumerStatefulWidget {
  final CategoryModel? category; // null = add mode, non-null = edit mode

  const AddEditCategoryScreen({super.key, this.category});

  @override
  ConsumerState<AddEditCategoryScreen> createState() =>
      _AddEditCategoryScreenState();
}

class _AddEditCategoryScreenState extends ConsumerState<AddEditCategoryScreen> {
  final _nameController = TextEditingController();
  String _selectedType = 'expense';
  String _selectedIcon = 'other';
  bool _isLoading = false;

  bool get isEditMode => widget.category != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      _nameController.text = widget.category!.name;
      _selectedType = widget.category!.type;
      _selectedIcon = widget.category!.icon;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Available icons with localized labels
  List<Map<String, dynamic>> _getIconOptions(AppLocalizations l10n) {
    return [
      {'name': 'food', 'icon': Icons.fastfood, 'label': l10n.cat_food},
      {
        'name': 'shopping',
        'icon': Icons.shopping_cart,
        'label': l10n.cat_shopping,
      },
      {
        'name': 'transportation',
        'icon': Icons.directions_car,
        'label': l10n.cat_transportation,
      },
      {
        'name': 'entertainment',
        'icon': Icons.movie,
        'label': l10n.cat_entertainment,
      },
      {'name': 'bills', 'icon': Icons.receipt, 'label': l10n.cat_bills},
      {'name': 'income', 'icon': Icons.attach_money, 'label': l10n.cat_income},
      {'name': 'home', 'icon': Icons.home, 'label': l10n.cat_home},
      {
        'name': 'hair cut',
        'icon': Icons.content_cut,
        'label': l10n.cat_haircut,
      },
      {
        'name': 'health',
        'icon': Icons.medical_services,
        'label': l10n.cat_health,
      },
      {'name': 'education', 'icon': Icons.school, 'label': l10n.cat_education},
      {'name': 'travel', 'icon': Icons.flight, 'label': l10n.cat_travel},
      {'name': 'gift', 'icon': Icons.card_giftcard, 'label': l10n.cat_gift},
      {
        'name': 'salary',
        'icon': Icons.account_balance_wallet,
        'label': l10n.cat_salary,
      },
      {
        'name': 'investment',
        'icon': Icons.trending_up,
        'label': l10n.cat_investment,
      },
      {
        'name': 'freelance',
        'icon': Icons.work_outline,
        'label': l10n.cat_freelance,
      },
      {'name': 'other', 'icon': Icons.more_horiz, 'label': l10n.cat_other},
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
        icon: _selectedIcon,
        type: _selectedType,
      );

      if (isEditMode) {
        await ref.read(firestoreServiceProvider).updateCategory(category);
      } else {
        await ref.read(firestoreServiceProvider).addCategory(category);
      }

      if (mounted) {
        context.pop();
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
          context.pop();
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isEditMode ? l10n.editCategory : l10n.addCategory,
          style: theme.textTheme.headlineSmall,
        ),
        centerTitle: true,
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        actions: isEditMode
            ? [
                IconButton(
                  icon: const Icon(Icons.delete, color: AppColors.error),
                  onPressed: _isLoading ? null : _handleDelete,
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Name
            Text(l10n.category, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 12),
            CustomTextField(
              hintText: l10n.enterCategoryName,
              controller: _nameController,
              prefixIcon: const Icon(Icons.label_outline, color: Colors.grey),
            ),
            const SizedBox(height: 32),

            // Type Toggle
            Text(l10n.type, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedType = 'expense'),
                      child: Container(
                        padding: const EdgeInsetsDirectional.symmetric(
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedType == 'expense'
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Center(
                          child: Text(
                            l10n.expenseType,
                            style: TextStyle(
                              color: _selectedType == 'expense'
                                  ? Colors.white
                                  : Colors.grey,
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
                      child: Container(
                        padding: const EdgeInsetsDirectional.symmetric(
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedType == 'income'
                              ? AppColors.income
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Center(
                          child: Text(
                            l10n.incomeType,
                            style: TextStyle(
                              color: _selectedType == 'income'
                                  ? Colors.white
                                  : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Icon Selection
            Text(l10n.selectIcon, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: iconOptions.map((option) {
                final isSelected = _selectedIcon == option['name'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = option['name']),
                  child: Container(
                    width: 70,
                    padding: const EdgeInsetsDirectional.symmetric(
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          option['icon'],
                          size: 24,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          option['label'],
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 40),

            // Save Button
            PrimaryButton(
              text: isEditMode ? l10n.save : l10n.addCategory,
              onPressed: _handleSave,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
