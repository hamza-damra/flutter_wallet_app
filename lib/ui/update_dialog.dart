import 'package:flutter/material.dart';
import '../services/update_service.dart';

/// A clean, polished update dialog widget
/// Can be used standalone outside of UpdateService if needed
class UpdateDialog extends StatefulWidget {
  final UpdateInfo updateInfo;
  final String installedVersion;
  final bool isForced;
  final Future<bool> Function(String apkUrl)? onDownload;
  final VoidCallback? onLater;
  final Future<void> Function(int versionCode)? onSkipVersion;

  const UpdateDialog({
    super.key,
    required this.updateInfo,
    required this.installedVersion,
    required this.isForced,
    this.onDownload,
    this.onLater,
    this.onSkipVersion,
  });

  /// Show the update dialog
  static Future<UpdatePromptResult?> show({
    required BuildContext context,
    required UpdateInfo updateInfo,
    required String installedVersion,
    required bool isForced,
    Future<bool> Function(String apkUrl)? onDownload,
  }) {
    return showDialog<UpdatePromptResult>(
      context: context,
      barrierDismissible: !isForced,
      builder: (context) => UpdateDialog(
        updateInfo: updateInfo,
        installedVersion: installedVersion,
        isForced: isForced,
        onDownload: onDownload,
      ),
    );
  }

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog>
    with SingleTickerProviderStateMixin {
  bool _skipVersionChecked = false;
  bool _isDownloading = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return PopScope(
      canPop: !widget.isForced,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          contentPadding: EdgeInsets.zero,
          content: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary,
                        colorScheme.primary.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.system_update_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isArabic ? 'تحديث متوفر!' : 'Update Available!',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'v${widget.installedVersion} → v${widget.updateInfo.latestVersionName}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content section
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Update message
                      Text(
                        widget.updateInfo.updateMessage.isNotEmpty
                            ? widget.updateInfo.updateMessage
                            : (isArabic
                                  ? 'إصدار جديد متاح مع إصلاحات وتحسينات جديدة.'
                                  : 'A new version is available with bug fixes and improvements.'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      // Force update warning
                      if (widget.isForced) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.orange.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isArabic
                                      ? 'هذا التحديث مطلوب للاستمرار.'
                                      : 'This update is required to continue.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.orange.shade800,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Skip version checkbox (optional updates only)
                      if (!widget.isForced) ...[
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _skipVersionChecked = !_skipVersionChecked;
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Checkbox(
                                    value: _skipVersionChecked,
                                    onChanged: (value) {
                                      setState(() {
                                        _skipVersionChecked = value ?? false;
                                      });
                                    },
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isArabic
                                      ? 'لا تذكرني بهذا الإصدار'
                                      : 'Don\'t remind me for this version',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Action buttons
                      Row(
                        children: [
                          // Later button (optional updates only)
                          if (!widget.isForced)
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  if (_skipVersionChecked) {
                                    widget.onSkipVersion?.call(
                                      widget.updateInfo.latestVersionCode,
                                    );
                                    Navigator.of(
                                      context,
                                    ).pop(UpdatePromptResult.skipVersion);
                                  } else {
                                    widget.onLater?.call();
                                    Navigator.of(
                                      context,
                                    ).pop(UpdatePromptResult.later);
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(isArabic ? 'لاحقاً' : 'Later'),
                              ),
                            ),
                          if (!widget.isForced) const SizedBox(width: 12),
                          // Update button
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isDownloading
                                  ? null
                                  : () async {
                                      setState(() => _isDownloading = true);
                                      try {
                                        if (widget.onDownload != null) {
                                          await widget.onDownload!(
                                            widget.updateInfo.apkUrl,
                                          );
                                        }
                                        if (context.mounted) {
                                          Navigator.of(
                                            context,
                                          ).pop(UpdatePromptResult.update);
                                        }
                                      } finally {
                                        if (mounted) {
                                          setState(
                                            () => _isDownloading = false,
                                          );
                                        }
                                      }
                                    },
                              icon: _isDownloading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.download_rounded,
                                      size: 20,
                                    ),
                              label: Text(
                                isArabic ? 'تحديث الآن' : 'Update Now',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
