import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:google_fonts/google_fonts.dart';

class PageBreakBlockEmbed extends CustomBlockEmbed {
  const PageBreakBlockEmbed() : super(pageBreakType, 'pageBreak');
  static const String pageBreakType = 'pageBreak';
}

class PageBreakEmbedBuilder extends EmbedBuilder {
  PageBreakEmbedBuilder();

  @override
  String get key => 'pageBreak';

  @override
  bool get expanded => true;

  @override
  Widget build(
    BuildContext context,
    QuillController controller,
    Embed node,
    bool readOnly,
    bool inline,
    TextStyle textStyle,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            // Sol çizgi
            Expanded(
              child: Container(
                height: 1,
                margin: const EdgeInsets.only(left: 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Color(0xFFCDD2DA)],
                  ),
                ),
              ),
            ),

            // Orta etiket
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEDF0F3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.insert_page_break_outlined,
                    size: 11,
                    color: const Color(0xFF1A1A1A).withOpacity(0.3),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'SAYFA SONU',
                    style: GoogleFonts.outfit(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.8,
                      color: const Color(0xFF1A1A1A).withOpacity(0.35),
                    ),
                  ),
                ],
              ),
            ),

            // Sağ çizgi
            Expanded(
              child: Container(
                height: 1,
                margin: const EdgeInsets.only(right: 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFCDD2DA), Colors.transparent],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
