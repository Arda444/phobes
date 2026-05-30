import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../services/nova_service.dart';
import '../../services/firebase_service.dart';
import '../../services/notification_service.dart';
import '../../core/phobes_theme.dart';
import 'package:phobes/l10n/app_localizations.dart';
import '../../core/module_info_catalog.dart';
import '../../widgets/phobes_module_header.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  final int _totalSeconds = 25 * 60;
  int _remainingSeconds = 25 * 60;
  bool _isRunning = false;
  final NovaService _novaService = NovaService();
  final FirebaseService _firebaseService = FirebaseService();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

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

  Future<void> _finishTimer({bool awardXp = true}) async {
    _timer?.cancel();
    setState(() => _isRunning = false);

    final l10n = AppLocalizations.of(context)!;
    final completedNaturally = _remainingSeconds <= 0;
    if (completedNaturally) {
      NotificationService().showInstantNotification(
        l10n.focusSessionEnded,
        l10n.focusSessionDesc,
      );
    }

    if (awardXp && completedNaturally) {
      await _firebaseService.addXP(
        100,
        reason: 'focus_complete',
        localizedLevelUpTitle: l10n.levelUpTitle,
        localizedLevelUpBody: l10n.levelUpBody(0),
      );
    }

    if (!completedNaturally) {
      if (mounted) {
        setState(() => _remainingSeconds = _totalSeconds);
      }
      return;
    }

    final advice = await _novaService.getTaskMotivation(l10n.focusBreakLabel);

    if (mounted) {
      final cs = Theme.of(context).colorScheme;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: cs.surfaceVariant,
          surfaceTintColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  gradient: PhobesTheme.successGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.celebration,
                    color: Colors.white, size: 20,),
              ),
              const SizedBox(width: 12),
              Text(l10n.congratulations,
                  style: GoogleFonts.outfit(
                      color: cs.onSurface, fontWeight: FontWeight.bold,),),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      cs.primary.withOpacity(0.2),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.stars, color: Colors.amber, size: 32),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.focusXpBonus,
                            style: GoogleFonts.outfit(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,),),
                        Text(l10n.focusMinutesDesc(25),
                            style: GoogleFonts.outfit(
                                color: cs.onSurface.withOpacity(0.5),
                                fontSize: 12,),),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.teal.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome,
                        color: Colors.tealAccent, size: 18,),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        advice ??
                            l10n.focusDefaultAdvice,
                        style: GoogleFonts.outfit(
                            color: Colors.tealAccent, fontSize: 13,),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                setState(() => _remainingSeconds = _totalSeconds);
              },
              child: Text(l10n.btnSuccess,
                  style: GoogleFonts.outfit(
                      color: cs.onPrimary, fontWeight: FontWeight.bold,),),
            ),
          ],
        ),
      );
    }
  }

  String _formatTime(int seconds) {
    final int m = seconds ~/ 60;
    final int s = seconds % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final double percent = 1.0 - (_remainingSeconds / _totalSeconds);
    final cs = Theme.of(context).colorScheme;
    final progressColor = _isRunning ? Colors.redAccent : cs.primary;
    final l10n = AppLocalizations.of(context)!;

    final isWide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PhobesModuleHeaderBar(
            title: l10n.focusMode,
            icon: Icons.center_focus_strong_rounded,
            info: ModuleInfoCatalog.forFocus(l10n),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isWide ? 600 : double.infinity,
                  ),
                  child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _isRunning ? _pulseAnimation.value : 1.0,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: _isRunning
                                  ? [
                                      BoxShadow(
                                        color: progressColor.withValues(
                                            alpha: 0.3,),
                                        blurRadius: 40,
                                        spreadRadius: 10,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: CircularPercentIndicator(
                              radius: 140.0,
                              lineWidth: 12.0,
                              percent: percent,
                              center: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _formatTime(_remainingSeconds),
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 52,
                                      color: cs.onSurface,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    _isRunning ? l10n.focusing : l10n.ready,
                                    style: GoogleFonts.outfit(
                                      color:
                                          cs.onSurface.withOpacity(0.4),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              progressColor: progressColor,
                              backgroundColor:
                                  cs.onSurface.withOpacity(0.08),
                              circularStrokeCap: CircularStrokeCap.round,
                              animation: true,
                              animateFromLastPercent: true,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 60),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            _pauseTimer();
                            setState(() => _remainingSeconds = _totalSeconds);
                          },
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: cs.surfaceVariant,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: cs.outline.withOpacity(0.1),),
                            ),
                            child: Icon(Icons.refresh_rounded,
                                color: cs.onSurface.withOpacity(0.6),
                                size: 24,),
                          ),
                        ),
                        const SizedBox(width: 24),
                        GestureDetector(
                          onTap: _isRunning ? _pauseTimer : _startTimer,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: _isRunning
                                  ? const LinearGradient(colors: [
                                      Colors.orange,
                                      Colors.deepOrange,
                                    ],)
                                  : PhobesTheme.successGradient,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (_isRunning
                                          ? Colors.orange
                                          : PhobesTheme.successColor)
                                      .withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Icon(
                              _isRunning
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: _isRunning ? 1.0 : 0.3,
                          child: GestureDetector(
                            onTap: _isRunning
                                ? () => _finishTimer(awardXp: false)
                                : null,
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: cs.surfaceVariant,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: cs.outline.withOpacity(0.1),),
                              ),
                              child: Icon(Icons.skip_next_rounded,
                                  color: cs.onSurface.withOpacity(0.6),
                                  size: 24,),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10,),
                      decoration: BoxDecoration(
                        color: cs.surfaceVariant,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: cs.outline.withOpacity(0.1),),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.stars,
                              color: Colors.amber, size: 16,),
                          const SizedBox(width: 8),
                          Text(
                            l10n.focusXpReward(100),
                            style: GoogleFonts.outfit(
                                color: cs.onSurface.withOpacity(0.5),
                                fontSize: 13,),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
