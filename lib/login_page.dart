import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_background.dart';
import 'app_theme.dart';
import 'auth_shared.dart';
import 'form_utils.dart';
import 'home_page.dart';
import 'register_page.dart';

/// The sign-in screen of the Credit Bill System app.
///
/// A successful sign-in replaces this route with [HomePage], so the user
/// cannot navigate back into the login form.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = false;

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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    Navigator.of(context).pushReplacement(authFadeRoute(const HomePage()));
  }

  void _handleCreateAccount() {
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(authFadeRoute(const RegisterPage()));
  }

  Future<void> _handleForgotPassword() async {
    FocusScope.of(context).unfocus();

    final email = await showDialog<String>(
      context: context,
      builder: (context) =>
          _ForgotPasswordDialog(initialEmail: _emailController.text.trim()),
    );

    if (!mounted || email == null) {
      return;
    }

    _showMessage('A password reset link has been sent to $email.');
  }

  void _showMessage(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.ink,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
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
                  final compact = constraints.maxHeight < 700;
                  final horizontalPadding = constraints.maxWidth < 400
                      ? 18.0
                      : 24.0;
                  final verticalPadding = compact ? 20.0 : 32.0;

                  final card = _buildLoginCard(
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

  Widget _buildLoginCard({
    required bool compact,
    required bool showBrandHeader,
  }) {
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
                child: AuthPill(label: 'SECURE SIGN IN'),
              ),
              SizedBox(height: compact ? 12 : 16),
              Text(
                'Welcome back',
                style: TextStyle(
                  fontSize: compact ? 27 : 31,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Sign in to manage your shop's credit bills and payments.",
                style: TextStyle(
                  fontSize: compact ? 13.5 : 14,
                  height: 1.55,
                  color: AppColors.muted,
                ),
              ),
              SizedBox(height: compact ? 22 : 28),
              TextFormField(
                key: const Key('emailField'),
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
              const SizedBox(height: 14),
              TextFormField(
                key: const Key('passwordField'),
                controller: _passwordController,
                obscureText: _obscurePassword,
                enableSuggestions: false,
                autocorrect: false,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink,
                ),
                decoration: appFieldDecoration(
                  label: 'Password',
                  hint: 'Your password',
                  icon: Icons.lock_outline_rounded,
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                    tooltip: _obscurePassword
                        ? 'Show password'
                        : 'Hide password',
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      size: 20,
                      color: AppColors.muted,
                    ),
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
                onFieldSubmitted: (_) => _handleLogin(),
              ),
              const SizedBox(height: 4),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() => _rememberMe = value ?? false);
                        },
                        activeColor: AppColors.primary,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        side: const BorderSide(
                          color: Color(0xFFB9CCE2),
                          width: 1.4,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Remember me',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    key: const Key('forgotPasswordButton'),
                    onPressed: _handleForgotPassword,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: compact ? 16 : 22),
              AuthSubmitButton(
                label: 'Login',
                buttonKey: const Key('loginButton'),
                onPressed: _handleLogin,
              ),
              SizedBox(height: compact ? 16 : 20),
              _CreateAccountRow(onCreateAccount: _handleCreateAccount),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateAccountRow extends StatelessWidget {
  const _CreateAccountRow({required this.onCreateAccount});

  final VoidCallback onCreateAccount;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text(
          'New to Credit Bill System?',
          style: TextStyle(fontSize: 13, color: AppColors.muted),
        ),
        TextButton(
          key: const Key('createAccountButton'),
          onPressed: onCreateAccount,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Create account',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _ForgotPasswordDialog extends StatefulWidget {
  const _ForgotPasswordDialog({required this.initialEmail});

  final String initialEmail;

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialEmail,
  );

  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final email = _controller.text.trim();
    if (!isValidEmail(email)) {
      setState(() => _errorText = 'Enter a valid email address');
      return;
    }
    Navigator.of(context).pop(email);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      icon: Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(
          color: AppColors.tint,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.lock_reset_rounded,
          color: AppColors.primary,
          size: 26,
        ),
      ),
      title: const Text(
        'Reset your password',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Enter the email linked to your account and we'll send you a "
            'reset link.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            key: const Key('resetEmailField'),
            controller: _controller,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            onSubmitted: (_) => _submit(),
            onChanged: (_) {
              if (_errorText != null) {
                setState(() => _errorText = null);
              }
            },
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.ink,
            ),
            decoration: appFieldDecoration(
              label: 'Email',
              hint: 'you@example.com',
              icon: Icons.mail_outline_rounded,
              errorText: _errorText,
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: AppColors.muted),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('sendResetLinkButton'),
          onPressed: _submit,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Send link'),
        ),
      ],
    );
  }
}
