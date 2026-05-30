import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';

class MaintenanceScreen extends StatelessWidget {
  final String? message;
  const MaintenanceScreen({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final displayMessage =
        (message != null && message!.isNotEmpty)
            ? message!
            : l10n.maintenanceDefaultMessage;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.construction_rounded,
                      size: 56, color: Colors.orange,),
                ),
                const SizedBox(height: 28),
                Text(l10n.maintenanceTitle,
                    style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,),
                    textAlign: TextAlign.center,),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.orange.withOpacity(0.08)
                        : Colors.orange.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: Colors.orange.withOpacity(0.2)),
                  ),
                  child: Text(
                    displayMessage,
                    style: GoogleFonts.outfit(
                        fontSize: 15,
                        color: cs.onSurface.withOpacity(0.85),
                        height: 1.6,),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _dot(Colors.orange, 0),
                  _dot(Colors.orange, 150),
                  _dot(Colors.orange, 300),
                ],),
                const SizedBox(height: 32),
                OutlinedButton.icon(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: Text(l10n.signOut,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w600),),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12,),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dot(Color color, int delayMs) {
    return _PulseDot(color: color, delay: Duration(milliseconds: delayMs));
  }
}

class _PulseDot extends StatefulWidget {
  final Color color;
  final Duration delay;
  const _PulseDot({required this.color, required this.delay});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900),);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),);
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FadeTransition(
        opacity: _anim,
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
              color: widget.color, shape: BoxShape.circle,),
        ),
      ),
    );
  }
}
