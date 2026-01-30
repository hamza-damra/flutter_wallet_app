import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../l10n/app_localizations.dart';
import '../models/friend_model.dart';
import '../models/debt_transaction_model.dart';
import '../repositories/debts_repository.dart';
import '../../../services/auth_service.dart';

class AddDebtTransactionScreen extends ConsumerStatefulWidget {
  final FriendModel friend;
  final DebtTransactionModel? existingTransaction;

  const AddDebtTransactionScreen({
    super.key,
    required this.friend,
    this.existingTransaction,
  });

  bool get isEditMode => existingTransaction != null;

  @override
  ConsumerState<AddDebtTransactionScreen> createState() =>
      _AddDebtTransactionScreenState();
}

class _AddDebtTransactionScreenState
    extends ConsumerState<AddDebtTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _type = 'lent'; // 'lent' or 'borrowed'
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.existingTransaction != null) {
      final tx = widget.existingTransaction!;
      _amountController.text = tx.amount.toString();
      _noteController.text = tx.note ?? '';
      _type = tx.type;
      _selectedDate = tx.date;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      final user = ref.read(authStateProvider).value;
      if (user == null) return;

      if (widget.isEditMode) {
        // Update existing transaction
        final updatedTransaction = DebtTransactionModel(
          id: widget.existingTransaction!.id,
          userId: widget.existingTransaction!.userId,
          friendId: widget.existingTransaction!.friendId,
          amount: amount,
          type: _type,
          date: _selectedDate,
          note: _noteController.text.isEmpty ? null : _noteController.text,
          createdAt: widget.existingTransaction!.createdAt,
          updatedAt: DateTime.now(),
        );

        await ref.read(debtsRepositoryProvider).updateDebtTransaction(updatedTransaction);
      } else {
        // Add new transaction
        final transaction = DebtTransactionModel(
          id: '0',
          userId: user.uid,
          friendId: widget.friend.id,
          amount: amount,
          type: _type,
          date: _selectedDate,
          note: _noteController.text.isEmpty ? null : _noteController.text,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await ref.read(debtsRepositoryProvider).addDebtTransaction(transaction);
      }

      if (mounted) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isLent = _type == 'lent';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditMode ? l10n.editDebtTransaction : l10n.newDebtTransaction,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: theme.colorScheme.onSurface),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Friend Name Display
              Text(
                '${l10n.friendName}: ${widget.friend.name}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Type Selector (Toggle)
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _type = 'lent'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isLent ? Colors.green : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            l10n.lent,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isLent
                                  ? Colors.white
                                  : theme.colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _type = 'borrowed'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !isLent ? Colors.red : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            l10n.borrowed,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: !isLent
                                  ? Colors.white
                                  : theme.colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Amount Field
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '0.00',
                  prefixText: '₪ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.pleaseEnterAmount;
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return l10n.amountValidation;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Date Picker
              GestureDetector(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.grey),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat.yMMMd().format(_selectedDate),
                        style: theme.textTheme.bodyLarge,
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Note Field
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: l10n.notes,
                  prefixIcon: const Icon(Icons.note_alt_outlined),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                maxLines: 3,
              ), // Corrected maxLines syntax

              const SizedBox(height: 40),

              // Save Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: Text(
                    l10n.save,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
