import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/illustration_widget.dart';
import '../../core/models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isLoading = true);
    try {
      final credential = await ref
          .read(authServiceProvider)
          .signUp(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );

      if (credential.user != null) {
        // Create User in Firestore
        final newUser = UserModel(
          uid: credential.user!.uid,
          email: credential.user!.email!,
          createdAt: DateTime.now(),
        );
        await ref.read(firestoreServiceProvider).createUser(newUser);
      }
      // Navigation handled by router auth listener
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const IllustrationWidget(
                path: 'assets/illustrations/register.svg',
              ),
              const SizedBox(height: 40),

              Text(l10n.registerTitle, style: theme.textTheme.headlineLarge),
              const SizedBox(height: 40),

              CustomTextField(
                hintText: l10n.emailHint,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                hintText: l10n.passwordHint,
                controller: _passwordController,
                obscureText: true,
              ),
              const SizedBox(height: 32),

              PrimaryButton(
                text: l10n.registerButton,
                onPressed: _handleRegister,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 24),

              GestureDetector(
                onTap: () => context.pop(), // Go back to login
                child: Text(
                  l10n.haveAccount,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
