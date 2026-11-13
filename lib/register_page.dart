import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_background.dart';
import 'app_theme.dart';
import 'auth_shared.dart';
import 'form_utils.dart';
import 'home_page.dart';

/// The account creation screen of the Credit Bill System app.
///
/// Successful registration opens [HomePage] and clears the navigation stack,
/// so the user starts signed in with no auth screens behind them.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  late final AnimationController _entranceController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _entranceController,
    curve: Curves.easeOut,
  );

  late final Animation<Offset> _slide =
      Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _entranceController,
          curve: Curves.easeOutCubic,
        ),
      );

  @override
  void initState() {
    super.initState();
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    Navigator.of(context)
        .pushAndRemoveUntil(authFadeRoute(const HomePage()), (route) => false);
  }

  void _handleSignIn() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Widget _passwordToggle({
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return IconButton(
      onPressed: onToggle,
      tooltip: obscure ? 'Show password' : 'Hide password',
      icon: Icon(
        obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
        size: 20,
        color: AppColors.muted,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.surface,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: Stack(
          children: [
            const Positioned.fill(child: AppBackground()),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 900;
                  final compact = constraints.maxHeight < 760;
                  final horizontalPadding = constraints.maxWidth < 400
                      ? 18.0
                      : 24.0;
                  final verticalPadding = compact ? 20.0 : 32.0;

                  final card = _buildRegisterCard(
                    compact: compact,
                    showBrandHeader: !isWide,
                  );

                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: verticalPadding,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: math.max(
                          0,
                          constraints.maxHeight - verticalPadding * 2,
                        ),
                      ),
                      child: Center(
                        child: FadeTransition(
                          opacity: _fade,
                          child: SlideTransition(
                            position: _slide,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: isWide ? 1120 : 480,
                              ),
                              child: isWide
                                  ? Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        const Expanded(child: AuthBrandPanel()),
                                        const SizedBox(width: 48),
                                        SizedBox(width: 400, child: card),
                                      ],
                                    )
                                  : card,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterCard({
    required bool compact,
    required bool showBrandHeader,
  }) {
    final fieldGap = compact ? 12.0 : 14.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        compact ? 24 : 32,
        compact ? 26 : 36,
        compact ? 24 : 32,
        compact ? 24 : 30,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(compact ? 28 : 32),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.10),
            blurRadius: 48,
            offset: const Offset(0, 22),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showBrandHeader) ...[
                AuthBrandHeader(compact: compact),
                SizedBox(height: compact ? 22 : 28),
              ],
              const Align(
                alignment: Alignment.centerLeft,
                child: AuthPill(
                  label: 'CREATE ACCOUNT',
                  icon: Icons.person_add_alt_1_rounded,
                ),
              ),
              SizedBox(height: compact ? 12 : 16),
              Text(
                'Create your account',
                style: TextStyle(
                  fontSize: compact ? 26 : 30,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Set up your shop profile to start managing credit bills and "
                'payments.',
                style: TextStyle(
                  fontSize: compact ? 13.5 : 14,
                  height: 1.55,
                  color: AppColors.muted,
                ),
              ),
              SizedBox(height: compact ? 20 : 26),
              TextFormField(
                key: const Key('registerNameField'),
                controller: _nameController,
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink,
                ),
                decoration: appFieldDecoration(
                  label: 'Full name',
                  hint: 'e.g. Ravi Kumar',
                  icon: Icons.person_outline_rounded,
                ),
                validator: (value) {
                  final name = value?.trim() ?? '';
                  if (name.isEmpty) {
                    return 'Enter your full name';
                  }
                  if (name.length < 2) {
                    return 'Name is too short';
                  }
                  return null;
                },
              ),
              SizedBox(height: fieldGap),
              TextFormField(
                key: const Key('registerEmailField'),
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink,
                ),
                decoration: appFieldDecoration(
                  label: 'Email',
                  hint: 'you@example.com',
                  icon: Icons.mail_outline_rounded,
                ),
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty) {
                    return 'Enter your email address';
                  }
                  if (!isValidEmail(email)) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              SizedBox(height: fieldGap),
              TextFormField(
                key: const Key('registerPhoneField'),
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.telephoneNumber],
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink,
                ),
                decoration: appFieldDecoration(
                  label: 'Phone number',
                  hint: 'e.g. 98765 43210',
                  icon: Icons.phone_outlined,
                ),
                validator: (value) {
                  final phone = value?.trim() ?? '';
                  if (phone.isEmpty) {
                    return 'Enter your phone number';
                  }
                  if (!isValidPhoneNumber(phone)) {
                    return 'Enter a valid phone number';
                  }
                  return null;
                },
              ),
              SizedBox(height: fieldGap),
              TextFormField(
                key: const Key('registerPasswordField'),
                controller: _passwordController,
                obscureText: _obscurePassword,
                enableSuggestions: false,
                autocorrect: false,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink,
                ),
                decoration: appFieldDecoration(
                  label: 'Password',
                  hint: 'At least 6 characters',
                  icon: Icons.lock_outline_rounded,
                  suffixIcon: _passwordToggle(
                    obscure: _obscurePassword,
                    onToggle: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter your password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              SizedBox(height: fieldGap),
              TextFormField(
                key: const Key('registerConfirmPasswordField'),
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                enableSuggestions: false,
                autocorrect: false,
                textInputAction: TextInputAction.done,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink,
                ),
                decoration: appFieldDecoration(
                  label: 'Confirm password',
                  hint: 'Re-enter your password',
                  icon: Icons.lock_outline_rounded,
                  suffixIcon: _passwordToggle(
                    obscure: _obscureConfirmPassword,
                    onToggle: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Confirm your password';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _handleRegister(),
              ),
              SizedBox(height: compact ? 16 : 20),
              AuthSubmitButton(
                label: 'Register',
                buttonKey: const Key('registerButton'),
                onPressed: _handleRegister,
              ),
              SizedBox(height: compact ? 14 : 18),
              _SignInRow(onSignIn: _handleSignIn),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignInRow extends StatelessWidget {
  const _SignInRow({required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text(
          'Already have an account?',
          style: TextStyle(fontSize: 13, color: AppColors.muted),
        ),
        TextButton(
          key: const Key('signInLink'),
          onPressed: onSignIn,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Sign in',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
