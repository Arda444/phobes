import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/admin_ui_system.dart';

class NotAuthorizedScreen extends StatelessWidget {
  const NotAuthorizedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: Center(
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(50),
          decoration: AdminUISystem.cardDecoration(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AdminUISystem.kCyberPink(context).withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: AdminUISystem.kCyberPink(context).withOpacity(0.2)),
                  boxShadow: [BoxShadow(color: AdminUISystem.kCyberPink(context).withOpacity(0.2), blurRadius: 30, spreadRadius: 5)],
                ),
                child: Icon(Icons.security_rounded, color: AdminUISystem.kCyberPink(context), size: 48),
              ),
              const SizedBox(height: 40),
              Text(
                'GÜVENLİK PROTOKOLÜ',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AdminUISystem.kCyberPink(context),
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Erişim Reddedildi',
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Bu modüle erişim için Firestore\'da kullanıcı kaydınızda role: Admin olmalıdır. İlk kurulumda Firebase Console → Firestore → users → kendi UID → role alanına Admin yazın.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  color: cs.onSurface.withOpacity(0.4),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 48),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: AdminUISystem.primaryGradient(context),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: AdminUISystem.kNeonPurple(context).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
                ),
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                  label: Text('GÜVENLİ BÖLGEYE DÖN', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 14, letterSpacing: 1)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
