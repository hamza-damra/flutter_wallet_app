import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';
import '../models/friend_model.dart';
import 'package:intl/intl.dart';

class FriendCard extends ConsumerWidget {
  final FriendModel friend;
  final VoidCallback onTap;

  const FriendCard({super.key, required this.friend, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    
    // Get display name based on locale
    final displayName = (locale.languageCode == 'ar' &&
            friend.nameAr != null &&
            friend.nameAr!.isNotEmpty)
        ? friend.nameAr!
        : friend.name;

    final currencyFormatter = NumberFormat.currency(
      symbol: '₪',
      decimalDigits: 2,
    );

    // Logic for display
    final isZero = friend.netBalance.abs() < 0.01;
    final isPositive = friend.netBalance > 0;

    final color = isZero
        ? Colors.grey
        : (isPositive ? Colors.green : Colors.red);

    final statusText = isZero
        ? l10n.settled
        : (isPositive ? l10n.owedToMe : l10n.owedByMe);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme
              .colorScheme
              .surface, // Standard opaque helpful for blending?
          // To match glassy theme, we might need to check theme mode, but keeping it simple/consistent with standard cards first.
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                style: TextStyle(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (friend.phoneNumber != null &&
                      friend.phoneNumber!.isNotEmpty)
                    Text(
                      friend.phoneNumber!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currencyFormatter.format(friend.netBalance.abs()),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  statusText,
                  style: theme.textTheme.bodySmall?.copyWith(color: color),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
