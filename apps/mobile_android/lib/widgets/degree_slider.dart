import 'package:flutter/material.dart';
import '../core/theme.dart';

class DegreeSlider extends StatelessWidget {
  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  const DegreeSlider({
    super.key,
    required this.value,
    this.max = 6,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Grado di Separazione (Hops):",
              style: TextStyle(
                color: ObsidianTheme.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: ObsidianTheme.neonCyan.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: ObsidianTheme.neonCyan),
              ),
              child: Text(
                "$value ${value == 1 ? 'Grado' : 'Gradi'}",
                style: const TextStyle(
                  color: ObsidianTheme.neonCyan,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: ObsidianTheme.neonCyan,
            inactiveTrackColor: ObsidianTheme.surfaceGlassHigh,
            thumbColor: ObsidianTheme.neonCyan,
            overlayColor: ObsidianTheme.neonCyan.withOpacity(0.2),
            valueIndicatorColor: ObsidianTheme.surfaceGlassHigh,
            valueIndicatorTextStyle: const TextStyle(color: ObsidianTheme.textPrimary),
          ),
          child: Slider(
            value: value.toDouble(),
            min: 1,
            max: max.toDouble(),
            divisions: max - 1,
            label: "$value Gradi",
            onChanged: (val) => onChanged(val.toInt()),
          ),
        ),
      ],
    );
  }
}
