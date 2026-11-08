import '../../../shared/widgets/app_page.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../../shared/widgets/app_password_field.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/primary_button.dart';
import 'auth_controller.dart';

/// Register Screen rebuilt to strictly match Figma `_02_register.dart` and `02_register.png`.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _termsAccepted = true;
  String? _generalError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    setState(() => _generalError = null);

    if (!_formKey.currentState!.validate()) return;

    if (!_termsAccepted) {
      setState(() {
        _generalError = 'Please agree to the Terms of use and Privacy policy.';
      });
      return;
    }

    final success = await ref
        .read(authControllerProvider.notifier)
        .register(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: _nameController.text.trim(),
        );

    if (!mounted) return;

    if (success) {
      context.go('/onboarding/schedule');
    } else {
      final error =
          ref.read(authControllerProvider).errorMessage ??
          'Registration failed';
      setState(() {
        if (error.contains('already registered') || error.contains('409')) {
          _generalError = 'This email is already in use. Please log in or use another email.';
        } else if (error.contains('network') ||
            error.contains('connect') ||
            error.contains('SocketException')) {
          _generalError = 'No internet connection. Please check your network and try again.';
        } else {
          _generalError = error;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return AppPage(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top App Bar area (56dp height matching Figma export, aligned with 24dp screen padding)
                        SizedBox(
                          height: 56,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: AppBackButton(
                              onPressed: () {
                                if (context.canPop()) {
                                  context.pop();
                                } else {
                                  context.go('/welcome');
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        const Text(
                          'A LITTLE MORE BALANCE',
                          style: AppTextStyles.eyebrow,
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Start with you.',
                          style: AppTextStyles.heading,
                        ),
                        const SizedBox(height: 8),

                        // Subtitle: "Create your Day-Balance account." (14sp Roboto Regular #62675D)
                        Text(
                          'Create your Day-Balance account.',
                          style: AppTextStyles.body14.copyWith(
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // General error banner if present
                        if (_generalError != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: AppColors.errorContainer,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: AppColors.error.withAlpha(80),
                              ),
                            ),
                            child: Text(
                              _generalError!,
                              style: AppTextStyles.error,
                            ),
                          ),
                        ],

                        // Name Field (Required, max 60 chars)
                        AppTextField(
                          label: 'Name',
                          hintText: 'Maya Chen',
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Enter your name';
                            }
                            if (val.trim().length > 60) {
                              return 'Name cannot exceed 60 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Email Field
                        AppTextField(
                          label: 'Email',
                          hintText: 'maya.chen@university.edu',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Email is required';
                            }
                            final emailRegex = RegExp(
                              r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                            );
                            if (!emailRegex.hasMatch(val.trim())) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password Field
                        AppPasswordField(
                          label: 'Password',
                          controller: _passwordController,
                          textInputAction: TextInputAction.next,
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Password is required';
                            }
                            if (val.length < 8) {
                              return 'Use at least 8 characters.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Confirm Password Field
                        AppPasswordField(
                          label: 'Confirm password',
                          controller: _confirmPasswordController,
                          textInputAction: TextInputAction.done,
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (val != _passwordController.text) {
                              return 'Passwords don’t match. Try again.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Terms and Privacy Checkbox row
                        Row(
                          children: [
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: Checkbox(
                                value: _termsAccepted,
                                activeColor: AppColors.primarySage,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                onChanged: (val) {
                                  setState(() => _termsAccepted = val ?? false);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(
                                    () => _termsAccepted = !_termsAccepted,
                                  );
                                },
                                child: Text(
                                  'I agree to the Terms of use and Privacy policy.',
                                  style: AppTextStyles.caption12.copyWith(
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Primary Button: "Create account"
                        AppPrimaryButton(
                          label: 'Create account',
                          isLoading: authState.isLoading,
                          onPressed: _handleRegister,
                        ),
                        const SizedBox(height: 16),

                        // "Already have an account? Log in"
                        Center(
                          child: TextButton(
                            onPressed: () => context.go('/login'),
                            child: RichText(
                              text: TextSpan(
                                text: 'Already have an account? ',
                                style: AppTextStyles.body14.copyWith(
                                  color: AppColors.secondary,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Log in',
                                    style: AppTextStyles.body14.copyWith(
                                      color: AppColors.primarySage,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
