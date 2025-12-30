import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_provider.dart';
import '../../l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background blobs for visual depth
          if (themeMode == AppThemeMode.glassy) ...[
            Positioned(
              top: -100,
              right: -50,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.pink.withValues(alpha: 0.1),
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              left: -100,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.withValues(alpha: 0.1),
                ),
              ),
            ),
          ] else ...[
            Positioned(
              top: -50,
              left: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.primaryColor.withValues(alpha: 0.05),
                ),
              ),
            ),
          ],

          SafeArea(
            child: Column(
              children: [
                _buildAppBar(
                  context,
                  l10n,
                  theme,
                  themeMode == AppThemeMode.glassy,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(
                          theme,
                          l10n.appTheme,
                          themeMode == AppThemeMode.glassy,
                        ),
                        const SizedBox(height: 20),
                        _buildThemeCard(context, ref, l10n, theme, themeMode),
                        const SizedBox(height: 32),
                        // Add more settings sections here as needed
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
    bool isGlassy,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios_new,
              size: 20,
              color: isGlassy ? Colors.white : theme.colorScheme.onSurface,
            ),
            style: IconButton.styleFrom(
              backgroundColor: isGlassy
                  ? Colors.white.withValues(alpha: 0.1)
                  : theme.colorScheme.surface,
              padding: const EdgeInsets.all(12),
              elevation: isGlassy ? 0 : 2,
              shadowColor: Colors.black.withValues(alpha: 0.1),
            ),
          ),
          const SizedBox(width: 20),
          Text(
            l10n.appSettings,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isGlassy ? Colors.white : theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, bool isGlassy) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: isGlassy ? Colors.white : theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildThemeCard(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    ThemeData theme,
    AppThemeMode themeMode,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(
          alpha: themeMode == AppThemeMode.glassy ? 0.4 : 1.0,
        ),
        borderRadius: BorderRadius.circular(24),
        border: themeMode == AppThemeMode.glassy
            ? Border.all(color: Colors.white.withValues(alpha: 0.2))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: _buildThemeOption(
                  context,
                  ref,
                  l10n.classicTheme,
                  AppThemeMode.classic,
                  AppColors.primary,
                  themeMode == AppThemeMode.classic,
                  themeMode == AppThemeMode.glassy,
                ),
              ),
              Expanded(
                child: _buildThemeOption(
                  context,
                  ref,
                  l10n.modernDarkTheme,
                  AppThemeMode.modernDark,
                  AppColors.darkPrimary,
                  themeMode == AppThemeMode.modernDark,
                  themeMode == AppThemeMode.glassy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: _buildThemeOption(
                  context,
                  ref,
                  l10n.oceanBlueTheme,
                  AppThemeMode.oceanBlue,
                  AppColors.oceanPrimary,
                  themeMode == AppThemeMode.oceanBlue,
                  themeMode == AppThemeMode.glassy,
                ),
              ),
              Expanded(
                child: _buildThemeOption(
                  context,
                  ref,
                  l10n.glassyTheme,
                  AppThemeMode.glassy,
                  AppColors.glassyPrimary,
                  themeMode == AppThemeMode.glassy,
                  themeMode == AppThemeMode.glassy,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    WidgetRef ref,
    String label,
    AppThemeMode mode,
    Color color,
    bool isSelected,
    bool isGlassy,
  ) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => ref.read(themeProvider.notifier).setTheme(mode),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 28)
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isGlassy
                  ? Colors.white.withValues(alpha: isSelected ? 1 : 0.7)
                  : (isSelected
                        ? theme.primaryColor
                        : theme.colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
