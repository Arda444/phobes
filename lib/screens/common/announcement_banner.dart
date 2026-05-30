import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementBanner extends StatefulWidget {
  const AnnouncementBanner({super.key});

  @override
  State<AnnouncementBanner> createState() => _AnnouncementBannerState();
}

class _AnnouncementBannerState extends State<AnnouncementBanner> {
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = FirebaseFirestore.instance
        .collection('appConfig')
        .doc('main')
        .snapshots();
  }

  Color _bgColor(String type) {
    switch (type) {
      case 'warning':
        return Colors.orange;
      case 'critical':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData _icon(String type) {
    switch (type) {
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'critical':
        return Icons.error_rounded;
      default:
        return Icons.campaign_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _stream,
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        // Firestore field shape can drift (string / bool / wrong map). A hard
        // `as Map` crashes the whole shell on web (grey screen + minified TypeError).
        final rawAnn = snap.data?.data()?['announcement'];
        Map<String, dynamic>? ann;
        if (rawAnn is Map) {
          ann = Map<String, dynamic>.from(rawAnn);
        }
        final enabled = ann?['enabled'];
        final isOn = enabled == true || enabled == 'true';
        if (ann == null || !isOn) {
          return const SizedBox.shrink();
        }
        final title = ann['title']?.toString() ?? '';
        final message = ann['message']?.toString() ?? '';
        final type = ann['type']?.toString() ?? 'info';
        final color = _bgColor(type);

        return AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          child: Material(
            color: color.withOpacity(0.92),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(_icon(type), color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (title.isNotEmpty)
                          Text(title,
                              style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,),),
                        if (message.isNotEmpty)
                          Text(message,
                              style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.9),),),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
