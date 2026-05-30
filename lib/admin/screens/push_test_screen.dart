import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../admin_service.dart';
import '../utils/admin_ui_system.dart';

class PushTestScreen extends StatefulWidget {
  final bool embedded;
  const PushTestScreen({super.key, this.embedded = false});

  @override
  State<PushTestScreen> createState() => _PushTestScreenState();
}

class _PushTestScreenState extends State<PushTestScreen> {
  final _emailController = TextEditingController();
  final _titleController = TextEditingController(text: 'Phobes Bildirimi');
  final _bodyController = TextEditingController(text: 'Bu bir test bildirimidir.');
  final _topicController = TextEditingController(text: 'all_users');
  
  bool _sending = false;
  bool _searching = false;
  String? _searchResult;
  String? _foundToken;

  @override
  void dispose() {
    _emailController.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  bool get hasToken => _foundToken != null && _foundToken!.isNotEmpty;

  Future<void> _lookupToken() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    setState(() {
      _searching = true;
      _foundToken = null;
      _searchResult = null;
    });
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (!mounted) return;
      if (snap.docs.isEmpty) {
        setState(() {
          _searchResult = 'Kullanıcı bulunamadı.';
          _searching = false;
        });
        return;
      }
      final token = snap.docs.first.data()['fcmToken'] as String?;
      setState(() {
        _foundToken = token;
        _searchResult = token != null && token.isNotEmpty
            ? 'Cihaz Kimliği (FCM) Doğrulandı'
            : 'FCM Token bulunamadı. Kullanıcı bildirim izni vermemiş olabilir.';
        _searching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searchResult = 'Sorgu Hatası: $e';
        _searching = false;
      });
    }
  }

  Future<void> _sendTest() async {
    setState(() => _sending = true);
    try {
      final count = await AdminService.sendPushNotification(
        topic: hasToken ? null : _topicController.text.trim(),
        token: hasToken ? _foundToken : null,
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
      );
      if (!mounted) return;
      final msg = hasToken
          ? 'FCM push gönderildi.'
          : 'Uygulama içi bildirim: $count kullanıcı.';
      AdminUISystem.showSuccessSnackBar(context, msg);
    } catch (e) {
      if (!mounted) return;
      AdminUISystem.showErrorSnackBar(context, 'İşlem başarısız: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Push İletişim Merkezi', style: AdminUISystem.titleStyle.copyWith(color: cs.onSurface)),
                  const SizedBox(height: 4),
                  Text('Cihaz bazlı bildirim testleri ve toplu gönderimler', style: AdminUISystem.subtitleStyle(context)),
                ],
              ),
              _buildConnectionBadge(cs),
            ],
          ),
          const SizedBox(height: 32),
          _buildTokenLookupCard(cs),
          const SizedBox(height: 32),
          _buildBroadcastCard(cs),
          if (!widget.embedded) const SizedBox(height: 80),
        ],
    );
    if (widget.embedded) {
      return Padding(padding: const EdgeInsets.only(top: 8), child: content);
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: content,
    );
  }

  Widget _buildConnectionBadge(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AdminUISystem.kElectricBlue(context).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminUISystem.kElectricBlue(context).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.hub_rounded, size: 14, color: AdminUISystem.kElectricBlue(context)),
          const SizedBox(width: 8),
          Text('FCM CLOUD AKTİF', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: AdminUISystem.kElectricBlue(context), letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildTokenLookupCard(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: AdminUISystem.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconBox(Icons.person_search_rounded, AdminUISystem.kAccentBlue(context)),
              const SizedBox(width: 20),
              Text('Kullanıcı Cihaz Sorgula', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _emailController,
                  style: GoogleFonts.outfit(),
                  decoration: _inputDecoration('Hedef E-posta Adresi', Icons.alternate_email_rounded, cs, context),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _searching ? null : _lookupToken,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AdminUISystem.primaryGradient(context),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: AdminUISystem.kNeonPurple(context).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: _searching 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.search_rounded, color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
          if (_searchResult != null) _buildSearchResultBanner(cs),
        ],
      ),
    );
  }

  Widget _buildSearchResultBanner(ColorScheme cs) {
    final accent = hasToken ? Colors.green : Colors.orange;
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(hasToken ? Icons.verified_rounded : Icons.info_outline_rounded, color: accent, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(_searchResult!, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: accent))),
            ],
          ),
          if (hasToken) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: cs.onSurface.withOpacity(0.03), borderRadius: BorderRadius.circular(10)),
              child: SelectableText(_foundToken!, style: GoogleFonts.jetBrainsMono(fontSize: 10, color: cs.onSurface.withOpacity(0.5))),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBroadcastCard(ColorScheme cs) {
    return Container(
      decoration: AdminUISystem.cardDecoration(context),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AdminUISystem.kElectricBlue(context).withOpacity(0.05),
              border: Border(bottom: BorderSide(color: cs.onSurface.withOpacity(0.05))),
            ),
            child: Row(
              children: [
                _iconBox(Icons.broadcast_on_personal_rounded, AdminUISystem.kElectricBlue(context)),
                const SizedBox(width: 20),
                Text('Toplu Mesaj Yayınla', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildField('Yayın Kanalı (Topic)', _topicController, Icons.hub_rounded, cs, context),
                const SizedBox(height: 16),
                _buildField('Başlık', _titleController, Icons.title_rounded, cs, context),
                const SizedBox(height: 16),
                _buildField('Mesaj İçeriği', _bodyController, Icons.subject_rounded, cs, context, maxLines: 3),
                const SizedBox(height: 32),
                _buildPublishButton(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPublishButton(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AdminUISystem.primaryGradient(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AdminUISystem.kNeonPurple(context).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: ElevatedButton.icon(
        onPressed: _sending ? null : _sendTest,
        icon: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 20),
        label: Text('BİLDİRİMİ YAYINLA', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 15, letterSpacing: 1)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, IconData icon, ColorScheme cs, BuildContext context, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurface.withOpacity(0.4))),
        const SizedBox(height: 10),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          style: GoogleFonts.outfit(),
          decoration: _inputDecoration(null, icon, cs, context),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String? hint, IconData icon, ColorScheme cs, BuildContext context) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: cs.onSurface.withOpacity(0.2), size: 20),
      filled: true,
      fillColor: cs.onSurface.withOpacity(0.03),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: const BorderRadius.all(Radius.circular(16)), borderSide: BorderSide(color: AdminUISystem.kElectricBlue(context))),
    );
  }

  Widget _iconBox(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
      child: Icon(icon, color: color, size: 24),
    );
  }
}
