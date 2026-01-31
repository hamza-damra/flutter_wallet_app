import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/models/user_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_avatars.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import 'profile_controller.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameArController;
  late TextEditingController _nameEnController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameArController = TextEditingController();
    _nameEnController = TextEditingController();
    _phoneController = TextEditingController();

    // Initialize controllers with current values
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(userProfileProvider).value;
      if (user != null) {
        _nameArController.text = user.displayNameAr ?? '';
        _nameEnController.text = user.displayNameEn ?? '';
        _phoneController.text = user.phoneNumber ?? '';
      }
    });
  }

  @override
  void dispose() {
    _nameArController.dispose();
    _nameEnController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final userAsync = ref.watch(userProfileProvider);
    final profileState = ref.watch(profileControllerProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    ref.listen(profileControllerProvider, (previous, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.error.toString())));
      } else if (next is AsyncData && previous is AsyncLoading) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.profileUpdated)));
      }
    });

    ref.listen<AsyncValue<UserModel?>>(userProfileProvider, (previous, next) {
      if (next is AsyncData) {
        final user = next.value;
        if (user != null) {
          if (_nameArController.text.isEmpty) {
            _nameArController.text = user.displayNameAr ?? '';
          }
          if (_nameEnController.text.isEmpty) {
            _nameEnController.text = user.displayNameEn ?? '';
          }
          if (_phoneController.text.isEmpty) {
            _phoneController.text = user.phoneNumber ?? '';
          }
        }
      }
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context, l10n, theme),
      body: Stack(
        children: [
          // Background blobs for premium look
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.15),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 100,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.income.withValues(alpha: 0.1),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.income.withValues(alpha: 0.15),
                    blurRadius: 80,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),

          // Additional decorative gradient overlay
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                color: theme.scaffoldBackgroundColor.withValues(alpha: 0.5),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: userAsync.when(
                    data: (user) {
                      final authUser = ref
                          .watch(authServiceProvider)
                          .currentUser;

                      // If no firestore user, create a temporary one from auth data
                      final displayUser =
                          user ??
                          (authUser != null
                              ? UserModel(
                                  uid: authUser.uid,
                                  email: authUser.email ?? '',
                                  createdAt: DateTime.now(),
                                  updatedAt: DateTime.now(),
                                )
                              : null);

                      if (displayUser == null) {
                        return Center(child: Text(l10n.noData));
                      }

                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _buildAvatarSection(displayUser, theme),
                              const SizedBox(height: 32),
                              _buildGlassyInfoCard(
                                l10n,
                                displayUser,
                                theme,
                                isDark,
                              ),
                              const SizedBox(height: 24),
                              _buildEditForm(l10n, theme, isDark),
                              const SizedBox(height: 40),
                              _buildUpdateButton(l10n, profileState, theme),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(child: Text(err.toString())),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: theme.colorScheme.onSurface,
          ),
          style: IconButton.styleFrom(
            backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.5),
            padding: const EdgeInsets.all(8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      centerTitle: true,
      title: Text(
        l10n.profile,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildAvatarSection(UserModel user, ThemeData theme) {
    final isAppAvatar = AppAvatars.isAppAvatar(user.photoUrl);

    return Center(
      child: GestureDetector(
        onTap: () => _showAvatarPicker(theme, user),
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [theme.primaryColor, theme.colorScheme.secondary],
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 64,
                backgroundColor: theme.colorScheme.surface,
                child: isAppAvatar
                    ? ClipOval(
                        child: SvgPicture.asset(
                          user.photoUrl!,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      )
                    : CircleAvatar(
                        radius: 60,
                        backgroundColor: theme.colorScheme.surface,
                        backgroundImage: user.photoUrl != null && !isAppAvatar
                            ? NetworkImage(user.photoUrl!)
                            : null,
                        child: user.photoUrl == null
                            ? Icon(Icons.person, size: 60, color: theme.primaryColor)
                            : null,
                      ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.colorScheme.surface, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.edit,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAvatarPicker(ThemeData theme, UserModel user) {
    String selectedAvatar = user.photoUrl ?? AppAvatars.getDefaultAvatar();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.5,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Choose Your Avatar',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: AppAvatars.avatarList.length,
                  itemBuilder: (context, index) {
                    final avatar = AppAvatars.avatarList[index];
                    final isSelected = selectedAvatar == avatar;

                    return GestureDetector(
                      onTap: () {
                        setModalState(() => selectedAvatar = avatar);
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
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ref
                          .read(profileControllerProvider.notifier)
                          .updateProfile(photoUrl: selectedAvatar);
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Save Avatar',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
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

  Widget _buildGlassyInfoCard(
    AppLocalizations l10n,
    UserModel user,
    ThemeData theme,
    bool isDark,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.6),
            ),
          ),
          child: Column(
            children: [
              _buildInfoRow(
                Icons.email_outlined,
                l10n.emailHint,
                user.email,
                theme,
                isDark,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Divider(
                  color: theme.dividerColor.withValues(alpha: 0.2),
                ),
              ),
              _buildInfoRow(
                Icons.calendar_today_outlined,
                l10n.date,
                user.createdAt.toString().split(' ')[0],
                theme,
                isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    ThemeData theme,
    bool isDark,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: theme.primaryColor, size: 24),
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
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                  fontSize: 15,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditForm(AppLocalizations l10n, ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Text(
            l10n.editProfile,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        _buildGlassyTextField(
          controller: _nameArController,
          hintText: l10n.nameArHint,
          prefixIcon: Icons.person_outline,
          theme: theme,
          isDark: isDark,
        ),
        const SizedBox(height: 16),
        _buildGlassyTextField(
          controller: _nameEnController,
          hintText: l10n.nameEnHint,
          prefixIcon: Icons.person_outline,
          theme: theme,
          isDark: isDark,
        ),
        const SizedBox(height: 16),
        _buildGlassyTextField(
          controller: _phoneController,
          hintText: l10n.phoneHint,
          keyboardType: TextInputType.phone,
          prefixIcon: Icons.phone_outlined,
          theme: theme,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildGlassyTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    required ThemeData theme,
    required bool isDark,
    TextAlign textAlign = TextAlign.start,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: TextFormField(
          controller: controller,
          textAlign: textAlign,
          keyboardType: keyboardType,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(
              prefixIcon,
              color: theme.primaryColor.withValues(alpha: 0.7),
            ),
            hintStyle: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            filled: true,
            fillColor: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.5),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: theme.primaryColor, width: 1.5),
            ),
            contentPadding: const EdgeInsets.all(20),
          ),
        ),
      ),
    );
  }

  Widget _buildUpdateButton(
    AppLocalizations l10n,
    AsyncValue profileState,
    ThemeData theme,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [theme.primaryColor, theme.colorScheme.secondary],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: profileState.isLoading
            ? null
            : () {
                ref
                    .read(profileControllerProvider.notifier)
                    .updateProfile(
                      displayNameAr: _nameArController.text,
                      displayNameEn: _nameEnController.text,
                      phoneNumber: _phoneController.text,
                    );
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: profileState.isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                l10n.updateProfile,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }
}
