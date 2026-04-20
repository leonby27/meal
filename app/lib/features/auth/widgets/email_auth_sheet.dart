import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:meal_tracker/core/services/auth_service.dart';
import 'package:meal_tracker/core/utils/l10n_extension.dart';

enum _SheetMode { auth, forgotEmail, forgotCode, forgotNewPassword }

class EmailAuthSheet extends StatefulWidget {
  const EmailAuthSheet({super.key});

  @override
  State<EmailAuthSheet> createState() => _EmailAuthSheetState();
}

class _EmailAuthSheetState extends State<EmailAuthSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLogin = true;
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  String? _error;
  String? _successMessage;

  _SheetMode _mode = _SheetMode.auth;
  String _resetEmail = '';
  String? _resetToken;

  Timer? _resendTimer;
  int _resendCooldown = 0;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendCooldown = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _resendCooldown--;
        if (_resendCooldown <= 0) timer.cancel();
      });
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final auth = AuthService();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final result = _isLogin
        ? await auth.signInWithEmail(email, password)
        : await auth.registerWithEmail(
            email,
            password,
            name: _nameController.text.trim(),
          );

    if (!mounted) return;

    if (result.ok) {
      Navigator.pop(context);
    } else {
      setState(() {
        _loading = false;
        _error = result.error;
      });
    }
  }

  Future<void> _sendResetCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    _resetEmail = _emailController.text.trim();
    final result = await AuthService().forgotPassword(_resetEmail);

    if (!mounted) return;

    if (result.ok) {
      _startResendTimer();
      setState(() {
        _loading = false;
        _mode = _SheetMode.forgotCode;
        _codeController.clear();
      });
    } else {
      setState(() {
        _loading = false;
        _error = result.error;
      });
    }
  }

  Future<void> _resendCode() async {
    if (_resendCooldown > 0) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await AuthService().forgotPassword(_resetEmail);

    if (!mounted) return;

    if (result.ok) {
      _startResendTimer();
      setState(() {
        _loading = false;
        _successMessage = context.l10n.resetCodeResent;
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _successMessage = null);
      });
    } else {
      setState(() {
        _loading = false;
        _error = result.error;
      });
    }
  }

  Future<void> _verifyCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await AuthService().verifyResetCode(
      _resetEmail,
      _codeController.text.trim(),
    );

    if (!mounted) return;

    if (result.ok) {
      _resetToken = result.resetToken;
      setState(() {
        _loading = false;
        _mode = _SheetMode.forgotNewPassword;
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      });
    } else {
      setState(() {
        _loading = false;
        _error = result.error;
      });
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await AuthService().resetPassword(
      _resetToken!,
      _newPasswordController.text,
    );

    if (!mounted) return;

    if (result.ok) {
      setState(() {
        _loading = false;
        _mode = _SheetMode.auth;
        _isLogin = true;
        _passwordController.clear();
        _successMessage = context.l10n.passwordResetSuccess;
      });
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) setState(() => _successMessage = null);
      });
    } else {
      setState(() {
        _loading = false;
        _error = result.error;
      });
    }
  }

  void _goBack() {
    setState(() {
      _error = null;
      _successMessage = null;
      switch (_mode) {
        case _SheetMode.forgotEmail:
          _mode = _SheetMode.auth;
        case _SheetMode.forgotCode:
          _mode = _SheetMode.forgotEmail;
        case _SheetMode.forgotNewPassword:
          _mode = _SheetMode.forgotCode;
        case _SheetMode.auth:
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: switch (_mode) {
                _SheetMode.auth => _buildAuthForm(theme),
                _SheetMode.forgotEmail => _buildForgotEmailStep(theme),
                _SheetMode.forgotCode => _buildCodeStep(theme),
                _SheetMode.forgotNewPassword => _buildNewPasswordStep(theme),
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthForm(ThemeData theme) {
    return Column(
      key: const ValueKey('auth'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _isLogin ? context.l10n.loginTitle : context.l10n.registerTitle,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        if (!_isLogin) ...[
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: context.l10n.nameOptional,
              prefixIcon: const Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 16),
        ],
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return context.l10n.enterEmail;
            if (!v.contains('@') || !v.contains('.')) return context.l10n.invalidEmail;
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          autofillHints: _isLogin
              ? const [AutofillHints.password]
              : const [AutofillHints.newPassword],
          decoration: InputDecoration(
            labelText: context.l10n.passwordLabel,
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return context.l10n.enterPassword;
            if (!_isLogin && v.length < 6) return context.l10n.minPasswordLength;
            return null;
          },
          onFieldSubmitted: (_) => _submit(),
        ),
        if (_isLogin) ...[
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _loading
                  ? null
                  : () => setState(() {
                        _mode = _SheetMode.forgotEmail;
                        _error = null;
                        _successMessage = null;
                      }),
              child: Text(context.l10n.forgotPassword),
            ),
          ),
        ],
        if (_successMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            _successMessage!,
            style: TextStyle(color: theme.colorScheme.primary),
          ),
        ],
        _buildError(theme),
        const SizedBox(height: 16),
        _buildPrimaryButton(
          label: _isLogin ? context.l10n.signInButton : context.l10n.registerButton,
          onPressed: _submit,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 48,
          child: OutlinedButton(
            onPressed: _loading
                ? null
                : () => setState(() {
                      _isLogin = !_isLogin;
                      _error = null;
                      _successMessage = null;
                    }),
            child: Text(
              _isLogin ? context.l10n.registerButton : context.l10n.switchToLogin,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForgotEmailStep(ThemeData theme) {
    return Column(
      key: const ValueKey('forgot_email'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildBackHeader(theme, context.l10n.resetPasswordTitle),
        const SizedBox(height: 8),
        Text(
          context.l10n.resetPasswordHint,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return context.l10n.enterEmail;
            if (!v.contains('@') || !v.contains('.')) return context.l10n.invalidEmail;
            return null;
          },
          onFieldSubmitted: (_) => _sendResetCode(),
        ),
        _buildError(theme),
        const SizedBox(height: 24),
        _buildPrimaryButton(
          label: context.l10n.sendResetCode,
          onPressed: _sendResetCode,
        ),
      ],
    );
  }

  Widget _buildCodeStep(ThemeData theme) {
    return Column(
      key: const ValueKey('forgot_code'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildBackHeader(theme, context.l10n.enterCodeTitle),
        const SizedBox(height: 8),
        Text(
          context.l10n.resetCodeSentTo(_resetEmail),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          style: theme.textTheme.headlineSmall?.copyWith(
            letterSpacing: 8,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: '000000',
            hintStyle: theme.textTheme.headlineSmall?.copyWith(
              letterSpacing: 8,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            prefixIcon: const Icon(Icons.pin_outlined),
          ),
          validator: (v) {
            if (v == null || v.trim().length != 6) return context.l10n.enterSixDigitCode;
            return null;
          },
          onFieldSubmitted: (_) => _verifyCode(),
        ),
        if (_successMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            _successMessage!,
            style: TextStyle(color: theme.colorScheme.primary),
          ),
        ],
        _buildError(theme),
        const SizedBox(height: 24),
        _buildPrimaryButton(
          label: context.l10n.verifyCode,
          onPressed: _verifyCode,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 48,
          child: TextButton(
            onPressed: _loading || _resendCooldown > 0 ? null : _resendCode,
            child: Text(
              _resendCooldown > 0
                  ? context.l10n.resendCodeIn(_resendCooldown)
                  : context.l10n.resendCode,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewPasswordStep(ThemeData theme) {
    return Column(
      key: const ValueKey('forgot_new_password'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildBackHeader(theme, context.l10n.newPasswordTitle),
        const SizedBox(height: 8),
        Text(
          context.l10n.newPasswordHint,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _newPasswordController,
          obscureText: _obscureNewPassword,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.newPassword],
          decoration: InputDecoration(
            labelText: context.l10n.newPasswordLabel,
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscureNewPassword ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
            ),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return context.l10n.enterPassword;
            if (v.length < 6) return context.l10n.minPasswordLength;
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: context.l10n.confirmPasswordLabel,
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return context.l10n.enterPassword;
            if (v != _newPasswordController.text) return context.l10n.passwordsDoNotMatch;
            return null;
          },
          onFieldSubmitted: (_) => _resetPassword(),
        ),
        _buildError(theme),
        const SizedBox(height: 24),
        _buildPrimaryButton(
          label: context.l10n.resetPasswordButton,
          onPressed: _resetPassword,
        ),
      ],
    );
  }

  Widget _buildBackHeader(ThemeData theme, String title) {
    return Row(
      children: [
        IconButton(
          onPressed: _loading ? null : _goBack,
          icon: const Icon(Icons.arrow_back),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError(ThemeData theme) {
    if (_error == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        _error!,
        style: TextStyle(color: theme.colorScheme.error),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 52,
      child: FilledButton(
        onPressed: _loading ? null : onPressed,
        child: _loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : Text(label, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}
