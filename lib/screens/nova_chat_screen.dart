import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../services/nova_service.dart';
import '../services/firebase_service.dart';

class NovaChatScreen extends StatefulWidget {
  const NovaChatScreen({super.key});

  @override
  State<NovaChatScreen> createState() => _NovaChatScreenState();
}

class _NovaChatScreenState extends State<NovaChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final NovaService _novaService = NovaService();
  final FirebaseService _firebaseService = FirebaseService();

  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDailyBriefing();
  }

  Future<void> _loadDailyBriefing() async {
    setState(() => _isLoading = true);

    try {
      final allTasks = await _firebaseService.getAllUserTasksStream().first;
      final today = DateTime.now();

      final todayTasks = allTasks.where((t) {
        return t.startTime.year == today.year &&
            t.startTime.month == today.month &&
            t.startTime.day == today.day;
      }).toList();

      final user = _firebaseService.currentUser;
      final name = user?.displayName?.split(' ')[0] ?? "Dostum";

      final briefing = await _novaService.getDailyBriefing(todayTasks, name);

      if (mounted) {
        if (briefing != null) {
          _addMessage('model', briefing);
        } else {
          _addMessage('model',
              "Merhaba $name! Ben Nova. Bugün sana nasıl yardımcı olabilirim?");
        }
      }
    } catch (e) {
      if (mounted) {
        _addMessage('model',
            "Selam! Bağlantıları kontrol ediyorum... Bugün neler yapalım?");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addMessage(String role, String text) {
    setState(() {
      _messages.add({'role': role, 'text': text});
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    _addMessage('user', text);

    setState(() => _isLoading = true);

    final history = _messages.length > 10
        ? _messages.sublist(_messages.length - 10)
        : _messages;

    final response = await _novaService.chatWithNova(history);

    if (mounted) {
      setState(() => _isLoading = false);
      if (response != null) {
        _addMessage('model', response);
      } else {
        _addMessage(
            'model', "Bağlantıda bir sorun oldu, tekrar dener misin? 😔");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, color: Colors.tealAccent),
            const SizedBox(width: 8),
            Text("Nova AI",
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                return FadeInUp(
                  duration: const Duration(milliseconds: 300),
                  child: Align(
                    alignment:
                        isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75),
                      decoration: BoxDecoration(
                        color: isUser
                            ? Colors.teal.shade700
                            : Colors.grey.shade900,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft:
                              isUser ? const Radius.circular(16) : Radius.zero,
                          bottomRight:
                              isUser ? Radius.zero : const Radius.circular(16),
                        ),
                      ),
                      child: Text(
                        msg['text']!,
                        style: GoogleFonts.poppins(
                            color: Colors.white, fontSize: 14),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Nova yazıyor...",
                    style: GoogleFonts.poppins(
                        color: Colors.white54, fontSize: 12)),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: GoogleFonts.poppins(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Bir şeyler söyle...",
                      hintStyle: GoogleFonts.poppins(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.black38,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  heroTag: 'nova_send_btn',
                  onPressed: _isLoading ? null : _sendMessage,
                  backgroundColor: Colors.teal,
                  mini: true,
                  elevation: 0,
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
