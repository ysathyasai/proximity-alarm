import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/utils/formatters.dart';
import '../../providers/journey_provider.dart';
import '../../providers/settings_provider.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _glowAnimation;
  double _slideDragPosition = 0.0;
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.25, end: 0.75).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleDismiss(JourneyProvider journey) async {
    if (_isDismissed) return;
    _isDismissed = true;
    HapticFeedback.heavyImpact();
    await journey.dismissAlarm();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final journey = context.watch<JourneyProvider>();
    final settings = context.watch<SettingsProvider>();
    final dest = journey.destination;
    final remainingDist = journey.remainingDistanceMeters;
    final etaMinutes = journey.estimatedArrivalMinutes;
    final distanceUnit = settings.distanceUnit;
    final requireSlide = settings.requireSlideToDismiss;
    final snoozeMinutes = settings.snoozeDurationMinutes;

    return PopScope(
      canPop: false, // Force explicit dismissal of alarm
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          // Explicit action required
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                const Spacer(flex: 1),

                // Pulsing Alarm Icon
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        width: 136,
                        height: 136,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFEF4444),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEF4444)
                                  .withValues(alpha: _glowAnimation.value),
                              blurRadius: 40,
                              spreadRadius: 15,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.alarm_on_rounded,
                          color: Colors.white,
                          size: 74,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),

                // Urgent Typography
                const Text(
                  'WAKE UP!',
                  style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'APPROACHING YOUR STOP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 22),

                // Destination Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.4),
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
                          maxLines: 2,
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
                                'DISTANCE REMAINING',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
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
                            color: const Color(0xFF334155),
                          ),
                          Column(
                            children: [
                              const Text(
                                'ESTIMATED ARRIVAL',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                etaMinutes <= 1 ? 'Immediate' : '~$etaMinutes min',
                                style: const TextStyle(
                                  color: Color(0xFF10B981),
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

                // DISMISS Action: Slide-to-Dismiss OR Large Button
                if (requireSlide) ...[
                  // Slide to Dismiss Track
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final double maxSlide = constraints.maxWidth - 64;
                      return Container(
                        height: 64,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            const Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'SLIDE TO DISMISS',
                                    style: TextStyle(
                                      color: Color(0xFFEF4444),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: Color(0xFFEF4444),
                                    size: 14,
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              left: _slideDragPosition,
                              child: GestureDetector(
                                onHorizontalDragUpdate: (details) {
                                  setState(() {
                                    _slideDragPosition = (_slideDragPosition + details.delta.dx)
                                        .clamp(0.0, maxSlide);
                                  });
                                },
                                onHorizontalDragEnd: (details) {
                                  if (_slideDragPosition >= maxSlide * 0.8) {
                                    _handleDismiss(journey);
                                  } else {
                                    setState(() {
                                      _slideDragPosition = 0.0;
                                    });
                                  }
                                },
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEF4444),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black45,
                                        blurRadius: 8,
                                        offset: Offset(2, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ] else ...[
                  // Large Unmissable DISMISS Button
                  SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        elevation: 8,
                        shadowColor:
                            const Color(0xFFEF4444).withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () => _handleDismiss(journey),
                      child: const Text(
                        'DISMISS ALARM',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // Snooze Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFF59E0B),
                      side:
                          const BorderSide(color: Color(0xFFF59E0B), width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () async {
                      HapticFeedback.mediumImpact();
                      await journey.snoozeAlarm(snoozeMinutes);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    icon: const Icon(Icons.snooze_rounded, size: 20),
                    label: Text(
                      'SNOOZE FOR $snoozeMinutes MINUTES',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
