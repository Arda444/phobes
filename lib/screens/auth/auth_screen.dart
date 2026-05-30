import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animate_do/animate_do.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../services/firebase_service.dart';
import '../../services/auth_service.dart';
import '../../core/phobes_theme.dart';
import '../../widgets/phobes_widgets.dart';
import '../../l10n/app_localizations.dart';
import 'widgets/auth_footer.dart';
import 'widgets/auth_header.dart';
import 'widgets/auth_background_painter.dart';
import 'widgets/social_auth_buttons.dart';

class AuthScreen extends StatefulWidget {
  final bool initialIsLogin;
  final bool showLandingHeader;
  const AuthScreen({
    super.key,
    this.initialIsLogin = true,
    this.showLandingHeader = false,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  DateTime? _selectedDate;

  final _passwordFocus = FocusNode();

  final _firebaseService = FirebaseService();
  late bool _isLogin;
  bool _isLoading = false;
  bool _obscurePassword = true;

  late AnimationController _bgAnimController;

  @override
  void initState() {
    super.initState();
    _isLogin = widget.initialIsLogin;
    _bgAnimController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _surnameController.dispose();
    _passwordFocus.dispose();
    _bgAnimController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    HapticFeedback.selectionClick();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF8B5CF6),
            onPrimary: Colors.white,
            surface: Color(0xFF1A1A2E),
          ),
          dialogTheme:
              const DialogThemeData(backgroundColor: Color(0xFF1A1A2E)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final resetEmailController = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          l10n.forgotPassword,
          style: GoogleFonts.outfit(
            color: cs.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.resetPasswordPrompt,
              style: GoogleFonts.outfit(
                color: cs.onSurface.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            PhobesTextField(
              controller: resetEmailController,
              hintText: l10n.email,
              prefixIcon: Icons.email_outlined,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l10n.cancel,
              style: GoogleFonts.outfit(
                color: cs.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ),
          PhobesButton(
            text: l10n.send,
            onPressed: () async {
              if (resetEmailController.text.trim().isEmpty) return;
              try {
                await _firebaseService
                    .sendPasswordResetEmail(resetEmailController.text.trim());
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  PhobesSnackbar.show(
                    context,
                    message: l10n.resetPasswordEmailSent,
                    type: PhobesSnackbarType.success,
                  );
                }
              } catch (e) {
                if (mounted) _showError('${l10n.error}: $e');
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _authenticate() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.length < 6) {
      _showError(l10n.invalidEmailPasswordPrompt);
      return;
    }

    if (!_isLogin &&
        (_nameController.text.isEmpty ||
            _surnameController.text.isEmpty ||
            _selectedDate == null)) {
      _showError(l10n.fillAllFieldsPrompt);
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      if (_isLogin) {
        await _firebaseService.signIn(email, password);
      } else {
        await _firebaseService.signUp(
          email: email,
          password: password,
          name: _nameController.text.trim(),
          surname: _surnameController.text.trim(),
          birthDate: _selectedDate!,
        );
      }
      if (!mounted) return;
      final accessAllowed = await AuthService().recordSessionStart();
      if (!accessAllowed) {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        _showError(l10n.accountAccessDenied);
        return;
      }
      if (mounted) {
        PhobesSnackbar.show(
          context,
          message: _isLogin
              ? l10n.loginSuccess
              : l10n.accountCreatedSuccess,
          type: PhobesSnackbarType.success,
        );
        context.go('/');
      }
    } on FirebaseAuthException catch (e) {
      final code = e.code;
      if (code == 'wrong-password' ||
          code == 'invalid-credential' ||
          code == 'user-not-found' ||
          code == 'invalid-email') {
        _showError(l10n.invalidEmailOrPassword);
      } else {
        _showError(e.message ?? l10n.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _googleSignIn() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();
    try {
      await _firebaseService.signInWithGoogle();
      if (mounted) {
        PhobesSnackbar.show(
          context,
          message: l10n.loginSuccess,
          type: PhobesSnackbarType.success,
        );
        context.go('/');
      }
    } catch (e) {
      _showError(l10n.googleSignInFailed(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _appleSignIn() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();
    try {
      await _firebaseService.signInWithApple();
      if (mounted) {
        PhobesSnackbar.show(
          context,
          message: l10n.loginSuccess,
          type: PhobesSnackbarType.success,
        );
        context.go('/');
      }
    } catch (e) {
      _showError(l10n.appleSignInFailed(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      PhobesSnackbar.show(
        context,
        message: message,
        type: PhobesSnackbarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = l10n.localeName;
    final screenH = MediaQuery.of(context).size.height;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAmoled = PhobesTheme.amoledMode.value;

    return Scaffold(
      backgroundColor: isAmoled && isDark ? Colors.black : cs.surface,
      body: Stack(
        children: [
          if (!isAmoled || !isDark)
            AnimatedBuilder(
              animation: _bgAnimController,
              builder: (context, _) {
                return CustomPaint(
                  size: MediaQuery.of(context).size,
                  painter: AuthBackgroundPainter(_bgAnimController.value, cs),
                );
              },
            ),
          if (!isAmoled || !isDark)
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(color: Colors.black.withValues(alpha: 0.2)),
            ),
          if (widget.showLandingHeader)
            Positioned(
              top: 16,
              left: 16,
              child: SafeArea(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                  child: Column(
                    children: [
                      SizedBox(height: screenH * 0.05),
                      AuthHeader(isLogin: _isLogin),
                      const SizedBox(height: 36),
                      FadeInUp(
                        delay: const Duration(milliseconds: 250),
                        child: PhobesGlassCard(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              if (!_isLogin) ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: PhobesTextField(
                                        controller: _nameController,
                                        hintText: l10n.name,
                                        prefixIcon:
                                            Icons.person_outline_rounded,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: PhobesTextField(
                                        controller: _surnameController,
                                        hintText: l10n.surname,
                                        prefixIcon:
                                            Icons.person_outline_rounded,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                GestureDetector(
                                  onTap: _pickDate,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: cs.surfaceContainerHigh
                                          .withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color:
                                            cs.outline.withValues(alpha: 0.1),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.cake_outlined,
                                          color:
                                              cs.primary.withValues(alpha: 0.7),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          _selectedDate == null
                                              ? l10n.birthDateSelect
                                              : DateFormat('d MMMM yyyy', locale)
                                                  .format(_selectedDate!),
                                          style: GoogleFonts.outfit(
                                            color: _selectedDate == null
                                                ? cs.onSurface
                                                    .withValues(alpha: 0.3)
                                                : cs.onSurface
                                                    .withValues(alpha: 0.7),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                              ],
                              AutofillGroup(
                                child: Column(
                                  children: [
                                    PhobesTextField(
                                      controller: _emailController,
                                      hintText: l10n.email,
                                      prefixIcon: Icons.email_outlined,
                                      keyboardType: TextInputType.emailAddress,
                                      autofillHints: const [
                                        AutofillHints.email
                                      ],
                                      textInputAction: TextInputAction.next,
                                      onSubmitted: (_) =>
                                          _passwordFocus.requestFocus(),
                                    ),
                                    const SizedBox(height: 14),
                                    PhobesTextField(
                                      controller: _passwordController,
                                      hintText: l10n.password,
                                      prefixIcon: Icons.lock_outline_rounded,
                                      obscureText: _obscurePassword,
                                      autofillHints: _isLogin
                                          ? const [AutofillHints.password]
                                          : const [AutofillHints.newPassword],
                                      focusNode: _passwordFocus,
                                      textInputAction: TextInputAction.done,
                                      onSubmitted: (_) => _authenticate(),
                                      onSuffixTap: () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      ),
                                      suffixIcon: _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                  ],
                                ),
                              ),
                              if (_isLogin)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _showForgotPasswordDialog,
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(0, 36),
                                    ),
                                    child: Text(
                                      l10n.forgotPassword,
                                      style: GoogleFonts.outfit(
                                        color: cs.primary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 20),
                              PhobesButton(
                                width: double.infinity,
                                text: _isLogin ? l10n.login : l10n.register,
                                isLoading: _isLoading,
                                onPressed: _authenticate,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      FadeInUp(
                        delay: const Duration(milliseconds: 350),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 1,
                                color: cs.outline.withValues(alpha: 0.1),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                l10n.or,
                                style: GoogleFonts.outfit(
                                  color: cs.onSurface.withValues(alpha: 0.3),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1,
                                color: cs.outline.withValues(alpha: 0.1),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      FadeInUp(
                        delay: const Duration(milliseconds: 400),
                        child: SocialAuthButtons(
                          isLoading: _isLoading,
                          onGoogleTap: _googleSignIn,
                          onAppleTap: _appleSignIn,
                        ),
                      ),
                      const SizedBox(height: 28),
                      FadeInUp(
                        delay: const Duration(milliseconds: 450),
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _isLogin = !_isLogin);
                          },
                          child: RichText(
                            text: TextSpan(
                              text: _isLogin
                                  ? l10n.dontHaveAccount
                                  : l10n.alreadyHaveAccount,
                              style: GoogleFonts.outfit(
                                color: cs.onSurface.withValues(alpha: 0.4),
                                fontSize: 14,
                              ),
                              children: [
                                TextSpan(
                                  text: _isLogin ? l10n.register : l10n.login,
                                  style: GoogleFonts.outfit(
                                    color: cs.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const SizedBox(height: 16),
                      const AuthFooter(),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            l10n.poweredBy,
                            style: GoogleFonts.outfit(
                              color: cs.onSurface.withValues(alpha: 0.2),
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            l10n.techlunaSoftware,
                            style: GoogleFonts.outfit(
                              color: cs.onSurface.withValues(alpha: 0.4),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
