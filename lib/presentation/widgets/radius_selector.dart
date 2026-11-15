import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';

class RadiusSelector extends StatelessWidget {
  final double currentRadiusMeters;
  final ValueChanged<double> onRadiusChanged;
  final DistanceUnit distanceUnit;

  const RadiusSelector({
    super.key,
    required this.currentRadiusMeters,
    required this.onRadiusChanged,
    this.distanceUnit = DistanceUnit.metric,
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

  void _showCustomRadiusDialog(BuildContext context) {
    final controller = TextEditingController(
      text: distanceUnit == DistanceUnit.imperial
          ? (currentRadiusMeters * 0.000621371).toStringAsFixed(1)
          : (currentRadiusMeters / 1000.0).toStringAsFixed(1),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Custom Alert Radius'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter exact alert boundary distance in ${distanceUnit == DistanceUnit.imperial ? "miles" : "kilometers"}:',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: InputDecoration(
                suffixText: distanceUnit == DistanceUnit.imperial ? 'mi' : 'km',
                hintText: 'e.g. 1.8',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () {
              final val = double.tryParse(controller.text.trim());
              if (val != null && val > 0) {
                final double meters = distanceUnit == DistanceUnit.imperial
                    ? val / 0.000621371
                    : val * 1000.0;
                final clamped = meters.clamp(
                  AppConstants.minRadiusMeters,
                  AppConstants.maxRadiusMeters,
                );
                onRadiusChanged(clamped);
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('SET RADIUS'),
          ),
        ],
      ),
    );
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
            InkWell(
              onTap: () => _showCustomRadiusDialog(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      Formatters.formatDistance(currentRadiusMeters, distanceUnit),
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.edit_rounded,
                      size: 13,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ],
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
                  label: Text(Formatters.formatDistance(preset, distanceUnit)),
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
