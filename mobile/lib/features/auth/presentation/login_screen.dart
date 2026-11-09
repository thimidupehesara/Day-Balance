import '../../../shared/widgets/app_page.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/app_password_field.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/secondary_button.dart';
import 'auth_controller.dart';

/// Login Screen strictly matching Figma 03_login.png and Day-Balance Style Guide.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  String? _emailError;
  String? _passwordError;
  String? _generalError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _clearErrors() {
    if (_emailError != null ||
        _passwordError != null ||
        _generalError != null) {
      setState(() {
        _emailError = null;
        _passwordError = null;
        _generalError = null;
      });
    }
  }

  bool _validateFields() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    bool isValid = true;
    String? emailErr;
    String? passwordErr;

    if (email.isEmpty) {
      emailErr = 'Enter your email address';
      isValid = false;
    } else {
      final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
      if (!emailRegex.hasMatch(email)) {
        emailErr = 'Enter a valid email address';
        isValid = false;
      }
    }

    if (password.isEmpty) {
      passwordErr = 'Enter your password';
      isValid = false;
    } else if (password.length < 8) {
      passwordErr = 'Password must be at least 8 characters';
      isValid = false;
    }

    setState(() {
      _emailError = emailErr;
      _passwordError = passwordErr;
      _generalError = null;
    });

    return isValid;
  }

  Future<void> _handleLogin() async {
    _clearErrors();
    if (!_validateFields()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final success = await ref
        .read(authControllerProvider.notifier)
        .login(email: email, password: password);

    if (!mounted) return;

    if (success) {
      final user = ref.read(authControllerProvider).user;
      if (user != null && user.onboardingDone) {
        context.go('/home');
      } else {
        context.go('/onboarding/schedule');
      }
    } else {
      final errorMessage = ref.read(authControllerProvider).errorMessage ?? '';
      setState(() {
        if (errorMessage.toLowerCase().contains('invalid') ||
            errorMessage.toLowerCase().contains('password') ||
            errorMessage.toLowerCase().contains('email')) {
          // Exact text shown in Figma 03_login.png
          _passwordError = 'That password doesn’t match this email. Try again or reset it below.';
        } else {
          _generalError = errorMessage;
        }
      });
    }
  }

  void _handleForgotPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Password reset will be available soon. Please contact support if you need help.',
          style: AppTextStyles.body14.copyWith(color: AppColors.white),
        ),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top App Bar area (56dp height matching Figma export, aligned with 24dp screen padding)
                      SizedBox(
                        height: 56,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Semantics(
                            label: 'Back',
                            button: true,
                            child: SizedBox(
                              width: 48,
                              height: 48,
                              child: IconButton(
                                alignment: Alignment.centerLeft,
                                padding: EdgeInsets.zero,
                                icon: const Icon(
                                  Icons.arrow_back,
                                  size: 24,
                                  color: AppColors.text,
                                ),
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
                        ),
                      ),
                      const SizedBox(height: 8),

                      const Text(
                        'YOUR TIME, WELL SPENT',
                        style: AppTextStyles.eyebrow,
                      ),
                      const SizedBox(height: 14),
                      Text('Good to see you.', style: AppTextStyles.heading),
                      const SizedBox(height: 8),

                      // Subtitle: "Log in and pick up\nwhere you left off." (Body 16/22 Roboto Regular #62675D)
                      Text(
                        'Log in and pick up\nwhere you left off.',
                        style: AppTextStyles.body16,
                      ),
                      // 40dp margin below header block matching _03_login.dart line 80
                      const SizedBox(height: 40),

                      // General server error banner if network/server issue
                      if (_generalError != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppColors.errorContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _generalError!,
                            style: AppTextStyles.error,
                          ),
                        ),
                      ],

                      // Email Field (Floating label "Email", radius 4, 16sp text)
                      AppTextField(
                        controller: _emailController,
                        focusNode: _emailFocusNode,
                        label: 'Email',
                        hintText: 'maya.chen@university.edu',
                        errorText: _emailError,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        isEnabled: !isLoading,
                        onChanged: (_) => _clearErrors(),
                        onSubmitted: (_) {
                          _passwordFocusNode.requestFocus();
                        },
                      ),
                      // 24dp margin between fields matching _03_login.dart line 134
                      const SizedBox(height: 24),

                      // Password Field (Floating label "Password", show/hide toggle, radius 4)
                      AppPasswordField(
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        label: 'Password',
                        errorText: _passwordError,
                        textInputAction: TextInputAction.done,
                        isEnabled: !isLoading,
                        onChanged: (_) => _clearErrors(),
                        onSubmitted: (_) => _handleLogin(),
                      ),
                      // 16dp spacing above "Forgot password?" matching _03_login.dart line 291
                      const SizedBox(height: 16),

                      // "Forgot password?" Link (Right-aligned, Roboto Semibold 14, #49664D, right: 3)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Semantics(
                          label: 'Forgot password',
                          button: true,
                          child: InkWell(
                            onTap: isLoading ? null : _handleForgotPassword,
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.only(
                                right: 3,
                                top: 6,
                                bottom: 6,
                                left: 8,
                              ),
                              child: Text(
                                'Forgot password?',
                                style: AppTextStyles.link,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // 26dp spacing (total 32dp from link to button) matching _03_login.dart lines 291 + 310
                      const SizedBox(height: 26),

                      // Primary Button: "Log in" (Height 48dp, Pill radius 100, #49664D)
                      AppPrimaryButton(
                        text: 'Log in',
                        isLoading: isLoading,
                        isEnabled: !isLoading,
                        onPressed: _handleLogin,
                      ),

                      // Flexible spacer pushing bottom section down on larger displays
                      const Spacer(),
                      const SizedBox(height: 40),

                      // "New to Day-Balance?" Prompt (Roboto Regular 14, #62675D)
                      Text(
                        'New to Day-Balance?',
                        style: AppTextStyles.body14.copyWith(
                          color: AppColors.secondary,
                        ),
                      ),
                      // 16dp margin between prompt and button matching _03_login.dart line 355
                      const SizedBox(height: 16),

                      // Secondary Button: "Create an account" (Height 48dp, Pill radius 100, outlined)
                      AppSecondaryButton(
                        text: 'Create an account',
                        isEnabled: !isLoading,
                        onPressed: () {
                          context.go('/register');
                        },
                      ),
                      // 24dp bottom margin matching _03_login.dart line 349
                      const SizedBox(height: 24),
                    ],
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
