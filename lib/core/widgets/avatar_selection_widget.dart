import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants/app_avatars.dart';

class AvatarSelectionWidget extends StatelessWidget {
  final String? selectedAvatar;
  final ValueChanged<String> onAvatarSelected;
  final double avatarSize;
  final bool showLabel;

  const AvatarSelectionWidget({
    super.key,
    this.selectedAvatar,
    required this.onAvatarSelected,
    this.avatarSize = 70,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) ...[
          Text(
            'Choose Avatar',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          height: avatarSize + 16,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: AppAvatars.avatarList.length,
            itemBuilder: (context, index) {
              final avatar = AppAvatars.avatarList[index];
              final isSelected = selectedAvatar == avatar;

              return Padding(
                padding: EdgeInsets.only(
                  right: index < AppAvatars.avatarList.length - 1 ? 12 : 0,
                ),
                child: GestureDetector(
                  onTap: () => onAvatarSelected(avatar),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: avatarSize,
                    height: avatarSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? theme.primaryColor
                            : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: theme.primaryColor.withValues(alpha: 0.3),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: ClipOval(
                      child: SvgPicture.asset(
                        avatar,
                        width: avatarSize - 6,
                        height: avatarSize - 6,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class AvatarSelectionDialog extends StatefulWidget {
  final String? initialAvatar;

  const AvatarSelectionDialog({super.key, this.initialAvatar});

  @override
  State<AvatarSelectionDialog> createState() => _AvatarSelectionDialogState();
}

class _AvatarSelectionDialogState extends State<AvatarSelectionDialog> {
  late String? _selectedAvatar;

  @override
  void initState() {
    super.initState();
    _selectedAvatar = widget.initialAvatar;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choose Your Avatar',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: AppAvatars.avatarList.length,
              itemBuilder: (context, index) {
                final avatar = AppAvatars.avatarList[index];
                final isSelected = _selectedAvatar == avatar;

                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedAvatar = avatar);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? theme.primaryColor
                            : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: theme.primaryColor.withValues(alpha: 0.3),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: ClipOval(
                      child: SvgPicture.asset(
                        avatar,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _selectedAvatar != null
                      ? () => Navigator.pop(context, _selectedAvatar)
                      : null,
                  child: const Text('Select'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<String?> showAvatarSelectionDialog(
  BuildContext context, {
  String? initialAvatar,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => AvatarSelectionDialog(initialAvatar: initialAvatar),
  );
}
