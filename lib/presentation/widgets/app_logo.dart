import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool withGlow;
  final BorderRadius? borderRadius;

  const AppLogo({
    super.key,
    this.size = 48.0,
    this.withGlow = false,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(size * 0.24);

    Widget image = ClipRRect(
      borderRadius: radius,
      child: Image.asset(
        'assets/icons/app_logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Fallback procedural container
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
              ),
            ),
            child: Icon(
              Icons.notifications_active_rounded,
              color: const Color(0xFF38BDF8),
              size: size * 0.55,
            ),
          );
        },
      ),
    );

    if (withGlow) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4F46E5).withValues(alpha: 0.35),
              blurRadius: size * 0.35,
              spreadRadius: 2,
            ),
          ],
        ),
        child: image,
      );
    }

    return image;
  }
}
