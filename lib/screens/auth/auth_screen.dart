import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import '../../services/firebase_service.dart';
import '../../core/phobes_theme.dart';
import '../../widgets/phobes_widgets.dart';
import '../../l10n/app_localizations.dart';
import '../settings/about_phobes_screen.dart';

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
            onSurface: Colors.white,
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
        title: Text(l10n.forgotPassword,
            style: GoogleFonts.outfit(
                color: cs.onSurface, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.resetPasswordPrompt,
                style: GoogleFonts.outfit(
                    color: cs.onSurface.withValues(alpha: 0.6), fontSize: 13)),
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
              child: Text(l10n.cancel,
                  style: GoogleFonts.outfit(
                      color: cs.onSurface.withValues(alpha: 0.4)))),
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
      // Auth succeeded — pop back to root so StreamBuilder shows home
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? l10n.error);
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
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      _showError(l10n.googleSignInFailed(e.toString()));
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
                  painter: _GradientBgPainter(_bgAnimController.value, cs),
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
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20),
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
                      FadeInDown(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: PhobesTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: cs.primary.withValues(alpha: 0.4),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text('P',
                                style: GoogleFonts.outfit(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w900,
                                  color: cs.onPrimary,
                                )),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      FadeInDown(
                        delay: const Duration(milliseconds: 100),
                        child: Text(
                          l10n.appTitle,
                          style: GoogleFonts.outfit(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: cs.onSurface,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      FadeInDown(
                        delay: const Duration(milliseconds: 150),
                        child: Text(
                          _isLogin ? l10n.welcomeBack : l10n.createAccount,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            color: cs.onSurface.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                      const SizedBox(height: 36),
                      FadeInUp(
                        delay: const Duration(milliseconds: 250),
                        child: PhobesGlassCard(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              if (!_isLogin) ...[
                                Row(children: [
                                  Expanded(
                                    child: PhobesTextField(
                                      controller: _nameController,
                                      hintText: l10n.name,
                                      prefixIcon: Icons.person_outline_rounded,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: PhobesTextField(
                                      controller: _surnameController,
                                      hintText: l10n.surname,
                                      prefixIcon: Icons.person_outline_rounded,
                                    ),
                                  ),
                                ]),
                                const SizedBox(height: 14),
                                GestureDetector(
                                  onTap: _pickDate,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: cs.surfaceContainerHigh
                                          .withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                          color: cs.outline
                                              .withValues(alpha: 0.1)),
                                    ),
                                    child: Row(children: [
                                      Icon(Icons.cake_outlined,
                                          color:
                                              cs.primary.withValues(alpha: 0.7),
                                          size: 20),
                                      const SizedBox(width: 12),
                                      Text(
                                        _selectedDate == null
                                            ? l10n.birthDateSelect
                                            : DateFormat('d MMMM yyyy', 'tr')
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
                                    ]),
                                  ),
                                ),
                                const SizedBox(height: 14),
                              ],
                              PhobesTextField(
                                controller: _emailController,
                                hintText: l10n.email,
                                prefixIcon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 14),
                              PhobesTextField(
                                controller: _passwordController,
                                hintText: l10n.password,
                                prefixIcon: Icons.lock_outline_rounded,
                                obscureText: _obscurePassword,
                                onSuffixTap: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                                suffixIcon: _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              if (_isLogin)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _showForgotPasswordDialog,
                                    style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: const Size(0, 36)),
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
                        child: Row(children: [
                          Expanded(
                              child: Container(
                                  height: 1,
                                  color: cs.outline.withValues(alpha: 0.1))),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(l10n.or,
                                style: GoogleFonts.outfit(
                                    color: cs.onSurface.withValues(alpha: 0.3),
                                    fontSize: 12)),
                          ),
                          Expanded(
                              child: Container(
                                  height: 1,
                                  color: cs.outline.withValues(alpha: 0.1))),
                        ]),
                      ),
                      const SizedBox(height: 24),
                      FadeInUp(
                        delay: const Duration(milliseconds: 400),
                        child: PhobesButton(
                          width: double.infinity,
                          text: l10n.continueWithGoogle,
                          isOutlined: true,
                          icon: Icons.g_mobiledata_rounded,
                          isLoading: _isLoading,
                          onPressed: _googleSignIn,
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
                                  fontSize: 14),
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
                      _buildAuthFooter(context, cs),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Powered by ',
                              style: GoogleFonts.outfit(
                                  color: cs.onSurface.withValues(alpha: 0.2),
                                  fontSize: 11)),
                          Text('Techluna Software',
                              style: GoogleFonts.outfit(
                                  color: cs.onSurface.withValues(alpha: 0.4),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
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

  Widget _buildAuthFooter(BuildContext context, ColorScheme cs) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _FooterTextLink(
          text: l10n.about,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AboutPhobesScreen()),
          ),
        ),
        _FooterSeparator(cs: cs),
        _FooterTextLink(
          text: l10n.features,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PhobesFeatureTreeScreen()),
          ),
        ),
        _FooterSeparator(cs: cs),
        _FooterTextLink(
          text: l10n.support,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PhobesContactScreen()),
          ),
        ),
      ],
    );
  }
}

class _FooterTextLink extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _FooterTextLink({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

class _FooterSeparator extends StatelessWidget {
  final ColorScheme cs;
  const _FooterSeparator({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text('|',
          style: GoogleFonts.outfit(
              color: cs.onSurface.withValues(alpha: 0.1), fontSize: 10)),
    );
  }
}

class _GradientBgPainter extends CustomPainter {
  final double progress;
  final ColorScheme cs;
  _GradientBgPainter(this.progress, this.cs);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    final c1x = size.width * (0.2 + 0.15 * math.sin(progress * 2 * math.pi));
    final c1y = size.height * (0.15 + 0.1 * math.cos(progress * 2 * math.pi));
    paint.shader = RadialGradient(
      colors: [
        cs.primary.withValues(alpha: 0.3),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(center: Offset(c1x, c1y), radius: 300));
    canvas.drawCircle(Offset(c1x, c1y), 300, paint);

    final c2x = size.width * (0.8 + 0.1 * math.cos(progress * 2 * math.pi + 1));
    final c2y =
        size.height * (0.6 + 0.12 * math.sin(progress * 2 * math.pi + 1));
    paint.shader = RadialGradient(
      colors: [
        cs.secondary.withValues(alpha: 0.25),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(center: Offset(c2x, c2y), radius: 250));
    canvas.drawCircle(Offset(c2x, c2y), 250, paint);

    final c3x = size.width * (0.5 + 0.2 * math.sin(progress * 2 * math.pi + 2));
    final c3y =
        size.height * (0.85 + 0.08 * math.cos(progress * 2 * math.pi + 2));
    paint.shader = RadialGradient(
      colors: [
        cs.tertiary.withValues(alpha: 0.2),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(center: Offset(c3x, c3y), radius: 200));
    canvas.drawCircle(Offset(c3x, c3y), 200, paint);
  }

  @override
  bool shouldRepaint(covariant _GradientBgPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.cs != cs;
}

