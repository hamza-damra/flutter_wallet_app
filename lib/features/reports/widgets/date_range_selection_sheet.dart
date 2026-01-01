import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../l10n/app_localizations.dart';

class DateRangeSelectionSheet extends ConsumerStatefulWidget {
  final DateTime startDate;
  final DateTime endDate;

  const DateRangeSelectionSheet({
    super.key,
    required this.startDate,
    required this.endDate,
  });

  @override
  ConsumerState<DateRangeSelectionSheet> createState() =>
      _DateRangeSelectionSheetState();
}

class _DateRangeSelectionSheetState
    extends ConsumerState<DateRangeSelectionSheet> {
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _startDate = widget.startDate;
    _endDate = widget.endDate;
  }

  void _applyRange(DateTime start, DateTime end) {
    setState(() {
      _startDate = start;
      _endDate = end;
    });
  }

  // Helper to check if a range matches
  bool _isRange(DateTime start, DateTime end) {
    return DateUtils.isSameDay(_startDate, start) &&
        DateUtils.isSameDay(_endDate, end);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeProvider);
    final isGlassy = themeMode == AppThemeMode.glassy;
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();

    // Preset Ranges
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final thisMonthEnd = now;

    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final lastMonthEnd = DateTime(now.year, now.month, 0);

    final last30DaysStart = now.subtract(const Duration(days: 30));
    final last30DaysEnd = now;

    final thisYearStart = DateTime(now.year, 1, 1);
    final thisYearEnd = now;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: isGlassy
            ? const Color(0xFF1E293B) // Dark background for glassy fallback
            : theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.selectDateRange,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isGlassy ? Colors.white : theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 24),

            // Presets
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildChip(
                    context,
                    label: l10n.thisMonth,
                    isSelected: _isRange(thisMonthStart, thisMonthEnd),
                    onTap: () => _applyRange(thisMonthStart, thisMonthEnd),
                    isGlassy: isGlassy,
                    theme: theme,
                  ),
                  const SizedBox(width: 8),
                  _buildChip(
                    context,
                    label: l10n.lastMonth,
                    isSelected: _isRange(lastMonthStart, lastMonthEnd),
                    onTap: () => _applyRange(lastMonthStart, lastMonthEnd),
                    isGlassy: isGlassy,
                    theme: theme,
                  ),
                  const SizedBox(width: 8),
                  _buildChip(
                    context,
                    label: l10n.last30Days,
                    isSelected: _isRange(last30DaysStart, last30DaysEnd),
                    onTap: () => _applyRange(last30DaysStart, last30DaysEnd),
                    isGlassy: isGlassy,
                    theme: theme,
                  ),
                  const SizedBox(width: 8),
                  _buildChip(
                    context,
                    label: l10n.thisYear,
                    isSelected: _isRange(thisYearStart, thisYearEnd),
                    onTap: () => _applyRange(thisYearStart, thisYearEnd),
                    isGlassy: isGlassy,
                    theme: theme,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Divider(color: theme.dividerColor.withValues(alpha: 0.1)),
            const SizedBox(height: 24),

            // Custom Range inputs
            Row(
              children: [
                Expanded(
                  child: _buildDateInput(
                    context,
                    label: l10n.startDate,
                    date: _startDate,
                    onTap: () => _pickDate(context, true),
                    isGlassy: isGlassy,
                    theme: theme,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDateInput(
                    context,
                    label: l10n.endDate,
                    date: _endDate,
                    onTap: () => _pickDate(context, false),
                    isGlassy: isGlassy,
                    theme: theme,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Apply Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    DateTimeRange(start: _startDate, end: _endDate),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: isGlassy ? 0 : 4,
                ),
                child: Text(
                  l10n.applyFilter,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isGlassy,
    required ThemeData theme,
  }) {
    final selectedColor = theme.primaryColor;
    final unselectedBg = isGlassy
        ? Colors.white.withValues(alpha: 0.05)
        : theme.colorScheme.surface;
    final unselectedBorder = isGlassy
        ? Colors.white.withValues(alpha: 0.1)
        : theme.dividerColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : unselectedBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? selectedColor : unselectedBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isGlassy ? Colors.white70 : theme.colorScheme.onSurface),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildDateInput(
    BuildContext context, {
    required String label,
    required DateTime date,
    required VoidCallback onTap,
    required bool isGlassy,
    required ThemeData theme,
  }) {
    final dateFormat = DateFormat.yMMMd();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isGlassy
                ? Colors.white.withValues(alpha: 0.6)
                : theme.colorScheme.onSurface.withValues(alpha: 0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isGlassy
                  ? Colors.white.withValues(alpha: 0.05)
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isGlassy
                    ? Colors.white.withValues(alpha: 0.1)
                    : theme.dividerColor,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 18,
                  color: isGlassy ? Colors.white70 : theme.iconTheme.color,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    dateFormat.format(date),
                    style: TextStyle(
                      color: isGlassy
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final theme = Theme.of(context);
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)), // Allow today
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: theme.primaryColor,
              onPrimary: Colors.white,
              onSurface: theme.colorScheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          if (picked.isAfter(_endDate)) {
            _endDate = picked;
          }
          _startDate = picked;
        } else {
          if (picked.isBefore(_startDate)) {
            _startDate = picked;
          }
          _endDate = picked;
        }
      });
    }
  }
}
