// lib/shared/widgets/superset_badge.dart
// 🔗 SUPERSET BADGE - Badge visibile per superset/circuit/rest-pause
// Massima priorità visibilità!

import 'package:flutter/material.dart';
import '../theme/workout_design_system.dart';

/// Badge per indicare tipo esercizio speciale (superset, circuit, etc.)
class SupersetBadge extends StatelessWidget {
  final String type; // 'superset', 'circuit', 'rest-pause', 'isometric'
  final String? customText;
  final double? fontSize;
  final bool isLarge;

  const SupersetBadge({
    super.key,
    required this.type,
    this.customText,
    this.fontSize,
    this.isLarge = false,
  });

  /// Badge grande (per header)
  factory SupersetBadge.large(String type) {
    return SupersetBadge(
      type: type,
      isLarge: true,
      fontSize: WorkoutDesignSystem.fontSizeH3,
    );
  }

  /// Badge compatto (per liste)
  factory SupersetBadge.compact(String type) {
    return SupersetBadge(
      type: type,
      isLarge: false,
      fontSize: WorkoutDesignSystem.fontSizeCaption,
    );
  }

  @override
  Widget build(BuildContext context) {
    final emoji = WorkoutDesignSystem.getExerciseTypeEmoji(type);
    final color = WorkoutDesignSystem.getBadgeColor(type);
    final decoration = WorkoutDesignSystem.getBadgeDecoration(type);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLarge
            ? WorkoutDesignSystem.spacingS
            : WorkoutDesignSystem.spacingXS,
        vertical: isLarge
            ? WorkoutDesignSystem.spacingXS
            : WorkoutDesignSystem.spacingXXS,
      ),
      decoration: decoration,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            emoji,
            style: TextStyle(
              fontSize: fontSize ?? WorkoutDesignSystem.fontSizeCaption,
            ),
          ),
          SizedBox(width: WorkoutDesignSystem.spacingXXS),
          Text(
            customText ?? _getTypeLabel(type),
            style: TextStyle(
              fontSize: fontSize ?? WorkoutDesignSystem.fontSizeCaption,
              fontWeight: WorkoutDesignSystem.fontWeightSemiBold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _getTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'superset':
        return 'SUPERSET';
      case 'circuit':
        return 'CIRCUIT';
      case 'dropset':
        return 'DROPSET';
      case 'giant set':
        return 'GIANT SET';
      case 'rest-pause':
        return 'REST-PAUSE';
      case 'isometric':
        return 'ISOMETRIC';
      default:
        return 'NORMALE';
    }
  }
}

