import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';

/// Shows the newest active broadcast the user has not dismissed (once per broadcast).
Future<void> maybeShowBroadcastPopup(BuildContext context) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null || !context.mounted) return;

  try {
    final broadcasts = await FirebaseFirestore.instance
        .collection('broadcasts')
        .where('active', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (broadcasts.docs.isEmpty || !context.mounted) return;

    final doc = broadcasts.docs.first;
    final data = doc.data();
    final dismissed = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('dismissedBroadcasts')
        .doc(doc.id)
        .get();
    if (dismissed.exists || !context.mounted) return;

    final type = data['type'] as String? ?? 'info';
    final color = switch (type) {
      'warning' => Colors.orange,
      'critical' => Colors.red,
      _ => Colors.blue,
    };

    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final dlgL10n = AppLocalizations.of(ctx)!;
        return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.campaign_rounded, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                data['title'] as String? ?? l10n.broadcastDefaultTitle,
                style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            data['message'] as String? ?? '',
            style: GoogleFonts.outfit(height: 1.4),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('dismissedBroadcasts')
                  .doc(doc.id)
                  .set({'dismissedAt': FieldValue.serverTimestamp()});
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(dlgL10n.ok,
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
          ),
        ],
      );
      },
    );
  } catch (e) {
    debugPrint('[maybeShowBroadcastPopup] $e');
  }
}
