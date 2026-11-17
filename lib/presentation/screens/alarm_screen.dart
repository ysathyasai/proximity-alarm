import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/utils/formatters.dart';
import '../../providers/journey_provider.dart';
import '../../providers/settings_provider.dart';
import 'home_screen.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen>
    with TickerProviderStateMixin {
  late final AnimationController _rippleController;
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _glowAnimation;
  late Timer _clockTimer;
  DateTime _currentTime = DateTime.now();
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();

    // Pulse animation for core alarm bell
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.85).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Ripple wave animation radiating outward (Samsung Clock radar effect)
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    // Live real-time clock timer
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _currentTime = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _pulseController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  Future<void> _handleDismiss(JourneyProvider journey) async {
    if (_isDismissed) return;
    _isDismissed = true;
    HapticFeedback.heavyImpact();
    await journey.dismissAlarm();
    if (mounted) {
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    }
  }

  Future<void> _handleSnooze(JourneyProvider journey, int snoozeMinutes) async {
    if (_isDismissed) return;
    _isDismissed = true;
    HapticFeedback.mediumImpact();
    await journey.snoozeAlarm(snoozeMinutes);
    if (mounted) {
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final journey = context.watch<JourneyProvider>();
    final settings = context.watch<SettingsProvider>();
    final dest = journey.destination;
    final remainingDist = journey.remainingDistanceMeters;
    final distanceUnit = settings.distanceUnit;
    final snoozeMinutes = settings.snoozeDurationMinutes;
    final isPitchBlack = settings.isPitchBlack;

    final timeString = DateFormat('hh:mm').format(_currentTime);
    final periodString = DateFormat('a').format(_currentTime);
    final dateString = DateFormat('EEEE, MMMM d').format(_currentTime);

    final backgroundColor = isPitchBlack ? const Color(0xFF000000) : const Color(0xFF090D16);

    return PopScope(
      canPop: false, // Force explicit action
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          // Stay on alarm screen until user dismisses or snoozes
        }
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: Stack(
            children: [
              // 1. Concentric Radial Wave Ripples (Samsung Clock Sonar Effect)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _rippleController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _AlarmRipplePainter(
                        progress: _rippleController.value,
                        rippleColor: const Color(0xFFEF4444),
                      ),
                    );
                  },
                ),
              ),

              // 2. Foreground Alarm Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 12),

                    // Ambient Date & Time Header (Samsung Clock Style)
                    Text(
                      dateString.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          timeString,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 68,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -2.0,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          periodString,
                          style: const TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(flex: 1),

                    // Pulsing Alarm Icon
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const RadialGradient(
                                colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFEF4444)
                                      .withValues(alpha: _glowAnimation.value),
                                  blurRadius: 45,
                                  spreadRadius: 18,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.notifications_active_rounded,
                              color: Colors.white,
                              size: 68,
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 28),

                    // Arrival Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.near_me_rounded, color: Color(0xFFEF4444), size: 16),
                          SizedBox(width: 8),
                          Text(
                            'ARRIVING AT YOUR STOP',
                            style: TextStyle(
                              color: Color(0xFFEF4444),
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Destination Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isPitchBlack ? const Color(0xFF0E0E0E) : const Color(0xFF131B2E),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            dest?.name ?? 'Selected Destination',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (dest?.address.isNotEmpty ?? false) ...[
                            const SizedBox(height: 6),
                            Text(
                              dest!.address,
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Column(
                                children: [
                                  const Text(
                                    'DISTANCE LEFT',
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    Formatters.formatDistance(remainingDist, distanceUnit),
                                    style: const TextStyle(
                                      color: Color(0xFFF59E0B),
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                width: 1,
                                height: 36,
                                color: Colors.white12,
                              ),
                              Column(
                                children: [
                                  const Text(
                                    'ALERT RADIUS',
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    Formatters.formatDistance(
                                      journey.radiusMeters,
                                      distanceUnit,
                                    ),
                                    style: const TextStyle(
                                      color: Color(0xFF38BDF8),
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const Spacer(flex: 2),

                    // Samsung Clock Style Action Buttons: Snooze & Large Glowing Dismiss
                    Row(
                      children: [
                        // Snooze Button
                        Expanded(
                          flex: 2,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF334155), width: 1.5),
                              foregroundColor: Colors.white,
                              backgroundColor: isPitchBlack ? const Color(0xFF141414) : const Color(0xFF1E293B),
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            icon: const Icon(Icons.snooze_rounded, size: 22, color: Color(0xFF38BDF8)),
                            label: Text(
                              'Snooze ($snoozeMinutes m)',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            onPressed: () => _handleSnooze(journey, snoozeMinutes),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Dismiss Button (Large, Unmistakable)
                        Expanded(
                          flex: 3,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              elevation: 8,
                              shadowColor: const Color(0xFFEF4444).withValues(alpha: 0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            icon: const Icon(Icons.check_circle_rounded, size: 24),
                            label: const Text(
                              'DISMISS ALARM',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                            onPressed: () => _handleDismiss(journey),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter for radiating concentric sonar ripples
class _AlarmRipplePainter extends CustomPainter {
  final double progress;
  final Color rippleColor;

  _AlarmRipplePainter({
    required this.progress,
    required this.rippleColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.44);
    final maxRadius = size.width * 0.75;

    for (int i = 0; i < 3; i++) {
      final ringProgress = (progress + (i * 0.33)) % 1.0;
      final radius = 65.0 + (maxRadius - 65.0) * ringProgress;
      final opacity = (1.0 - ringProgress).clamp(0.0, 1.0) * 0.25;

      final paint = Paint()
        ..color = rippleColor.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AlarmRipplePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
