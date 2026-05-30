import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../l10n/app_localizations.dart';

enum PasswordStrength { weak, fair, strong }

class PasswordStrengthBar extends StatefulWidget {
  final TextEditingController passwordController;
  final Function(PasswordStrength) onStrengthChanged;

  const PasswordStrengthBar({
    super.key,
    required this.passwordController,
    required this.onStrengthChanged,
  });

  @override
  State<PasswordStrengthBar> createState() => _PasswordStrengthBarState();
}

class _PasswordStrengthBarState extends State<PasswordStrengthBar> {
  PasswordStrength _passwordStrength = PasswordStrength.weak;

  @override
  void initState() {
    super.initState();
    widget.passwordController.addListener(_checkPassword);
  }

  @override
  void dispose() {
    widget.passwordController.removeListener(_checkPassword);
    super.dispose();
  }

  void _checkPassword() {
    final pass = widget.passwordController.text;
    if (pass.isEmpty) {
      if (_passwordStrength != PasswordStrength.weak) {
        setState(() => _passwordStrength = PasswordStrength.weak);
        widget.onStrengthChanged(PasswordStrength.weak);
      }
      return;
    }
    final bool hasMinLength = pass.length >= 8;
    final bool hasUpper = pass.contains(RegExp(r'[A-Z]'));
    final bool hasLower = pass.contains(RegExp(r'[a-z]'));
    final bool hasDigit = pass.contains(RegExp(r'\d'));
    final bool hasSpecial = pass.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    
    int score = 0;
    if (hasMinLength) score++;
    if (hasUpper || hasLower) score++;
    if (hasDigit) score++;
    if (hasSpecial) score++;

    PasswordStrength newStr = PasswordStrength.weak;
    if (score == 4) {
      newStr = PasswordStrength.strong;
    } else if (score >= 2) {
      newStr = PasswordStrength.fair;
    }

    if (_passwordStrength != newStr) {
      setState(() => _passwordStrength = newStr);
      widget.onStrengthChanged(newStr);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Color barColor;
    String label;
    switch (_passwordStrength) {
      case PasswordStrength.weak:
        barColor = Colors.redAccent;
        label = l10n.passwordStrengthWeak;
        break;
      case PasswordStrength.fair:
        barColor = Colors.amber;
        label = l10n.passwordStrengthMedium;
        break;
      case PasswordStrength.strong:
        barColor = Colors.green;
        label = l10n.passwordStrengthStrong;
        break;
    }

    return Row(
      children: [
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 4,
            decoration: BoxDecoration(
              color: barColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _passwordStrength == PasswordStrength.weak
                  ? 60
                  : _passwordStrength == PasswordStrength.fair
                      ? 150
                      : 400,
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [BoxShadow(color: barColor.withOpacity(0.5), blurRadius: 4)],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 40,
          child: Text(label, style: GoogleFonts.outfit(color: barColor, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
