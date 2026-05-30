import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';

class BannedScreen extends StatelessWidget {
  final String? reason;
  const BannedScreen({super.key, this.reason});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

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
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.block_rounded,
                      size: 52, color: Colors.red,),
                ),
                const SizedBox(height: 28),
                Text(l10n.accountBannedTitle,
                    style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,),
                    textAlign: TextAlign.center,),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.red.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      Text(l10n.accountBannedReasonLabel,
                          style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.red.withOpacity(0.7),),),
                      const SizedBox(height: 4),
                      Text(
                        reason?.isNotEmpty == true
                            ? reason!
                            : l10n.accountBannedDefaultReason,
                        style: GoogleFonts.outfit(
                            fontSize: 15,
                            color: cs.onSurface,
                            height: 1.5,),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.accountBannedSupportMessage,
                  style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: cs.onSurface.withOpacity(0.5),
                      height: 1.5,),
                  textAlign: TextAlign.center,
                ),
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
}
