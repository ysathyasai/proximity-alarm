import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';

class RadiusSelector extends StatelessWidget {
  final double currentRadiusMeters;
  final ValueChanged<double> onRadiusChanged;

  const RadiusSelector({
    super.key,
    required this.currentRadiusMeters,
    required this.onRadiusChanged,
  });

  String _getTransitContextText(double meters) {
    if (meters <= 500) {
      return 'Walking distance • Immediate stop warning (~1-2 min away)';
    } else if (meters <= 1000) {
      return 'Next stop alert • Good for metro & suburban trains';
    } else if (meters <= 2000) {
      return 'Recommended standard • ~1-2 bus/metro stops buffer';
    } else if (meters <= 3000) {
      return 'Extended buffer • Ample time to collect belongings';
    } else {
      return 'Highway / Express transit buffer (~10-15 min advance)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Alert Radius',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                Formatters.formatDistance(currentRadiusMeters),
                style: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          _getTransitContextText(currentRadiusMeters),
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 12),

        // Quick Preset Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: AppConstants.radiusPresets.map((preset) {
              final isSelected = (currentRadiusMeters - preset).abs() < 50;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(Formatters.formatDistance(preset)),
                  selected: isSelected,
                  onSelected: (_) => onRadiusChanged(preset),
                  selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                  checkmarkColor: theme.colorScheme.primary,
                  labelStyle: TextStyle(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.textTheme.bodyMedium?.color,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFCBD5E1),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 8),

        // Fine Slider
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: theme.colorScheme.primary,
            inactiveTrackColor: theme.colorScheme.primary.withValues(alpha: 0.2),
            thumbColor: theme.colorScheme.primary,
            overlayColor: theme.colorScheme.primary.withValues(alpha: 0.12),
            trackHeight: 4,
          ),
          child: Slider(
            value: currentRadiusMeters.clamp(
              AppConstants.minRadiusMeters,
              AppConstants.maxRadiusMeters,
            ),
            min: AppConstants.minRadiusMeters,
            max: AppConstants.maxRadiusMeters,
            divisions: 49, // 200m steps up to 10km
            onChanged: onRadiusChanged,
          ),
        ),
      ],
    );
  }
}

