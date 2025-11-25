import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'dart:async';
import '../services/nova_service.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  Timer? _timer;
  final int _totalSeconds = 25 * 60; // 25 Dakika
  int _remainingSeconds = 25 * 60;
  bool _isRunning = false;
  final NovaService _novaService = NovaService();
  final FirebaseService _firebaseService = FirebaseService();

  void _startTimer() {
    if (_isRunning) return;
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _finishTimer();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  Future<void> _finishTimer() async {
    _timer?.cancel();
    setState(() => _isRunning = false);

    NotificationService().showInstantNotification(
        "Odak Süresi Bitti!", "Harika iş çıkardın! Mola zamanı. ☕");
    await _firebaseService.addXP(100); // 100 XP Ödül

    // Nova'dan Mola Tavsiyesi
    final advice = await _novaService.getTaskMotivation("Mola");

    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.grey.shade900,
          title: const Text("Tebrikler! 🎉",
              style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("25 Dakika odaklandın ve 100 XP kazandın!",
                  style: GoogleFonts.poppins(color: Colors.white70)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10)),
                child: Text(
                    advice ?? "Şimdi 5 dakika gözlerini dinlendir ve su iç.",
                    style: const TextStyle(color: Colors.tealAccent)),
              )
            ],
          ),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() => _remainingSeconds = _totalSeconds); // Reset
                },
                child: const Text("Tamam"))
          ],
        ),
      );
    }
  }

  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    double percent = 1.0 - (_remainingSeconds / _totalSeconds);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title:
            Text("Odak Modu", style: GoogleFonts.poppins(color: Colors.white)),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularPercentIndicator(
              radius: 140.0,
              lineWidth: 15.0,
              percent: percent,
              center: Text(_formatTime(_remainingSeconds),
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 48,
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
              progressColor: Colors.redAccent,
              backgroundColor: Colors.grey.shade800,
              circularStrokeCap: CircularStrokeCap.round,
              animation: true,
              animateFromLastPercent: true,
            ),
            const SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton.large(
                  heroTag: 'focus_control_btn',
                  onPressed: _isRunning ? _pauseTimer : _startTimer,
                  backgroundColor: _isRunning ? Colors.orange : Colors.green,
                  child: Icon(_isRunning ? Icons.pause : Icons.play_arrow,
                      size: 40, color: Colors.white),
                ),
                const SizedBox(width: 20),
                FloatingActionButton(
                  heroTag: 'focus_reset_btn',
                  mini: true,
                  onPressed: () {
                    _pauseTimer();
                    setState(() => _remainingSeconds = _totalSeconds);
                  },
                  backgroundColor: Colors.grey.shade800,
                  child: const Icon(Icons.refresh, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Text(_isRunning ? "Odaklan..." : "Hazır olduğunda başla",
                style: GoogleFonts.poppins(color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}
