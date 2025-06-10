// lib/shared/widgets/plateau_widgets.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../features/workouts/models/plateau_models.dart';

/// 🎯 PLATEAU BADGE - Badge discreto per plateau rilevati
/// ✅ Design minimale e non invasivo
/// ✅ Tap per mostrare suggerimenti
/// 🔧 FIX 2: Rispetta dismiss dell'utente
class PlateauBadge extends StatelessWidget {
  final PlateauInfo? plateauInfo;
  final VoidCallback? onTap;
  final bool showTooltip;

  const PlateauBadge({
    super.key,
    this.plateauInfo,
    this.onTap,
    this.showTooltip = true,
  });

  @override
  Widget build(BuildContext context) {
    // Non mostrare se non c'è plateau o è dismissed
    if (plateauInfo == null || plateauInfo!.isDismissed) {
      return const SizedBox.shrink();
    }

    final badge = GestureDetector(
      onTap: onTap ?? () => _showPlateauDialog(context),
      child: Container(
        width: 8.w,
        height: 8.w,
        decoration: BoxDecoration(
          color: _getPlateauColor(plateauInfo!.plateauType),
          borderRadius: BorderRadius.circular(4.r),
          boxShadow: [
            BoxShadow(
              color: _getPlateauColor(plateauInfo!.plateauType).withOpacity(0.4),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
    );

    if (!showTooltip) return badge;

    return Tooltip(
      message: 'Plateau rilevato - Tap per suggerimenti',
      preferBelow: false,
      child: badge,
    );
  }

  Color _getPlateauColor(PlateauType type) {
    switch (type) {
      case PlateauType.lightWeight:
        return Colors.orange;
      case PlateauType.heavyWeight:
        return Colors.red;
      case PlateauType.lowReps:
        return Colors.blue;
      case PlateauType.highReps:
        return Colors.purple;
      case PlateauType.moderate:
        return Colors.deepOrange;
    }
  }

  void _showPlateauDialog(BuildContext context) {
    if (plateauInfo == null) return;

    showDialog(
      context: context,
      builder: (context) => PlateauSuggestionDialog(plateauInfo: plateauInfo!),
    );
  }
}

/// 🎯 PLATEAU SUGGESTION DIALOG - Dialog con suggerimenti
class PlateauSuggestionDialog extends StatelessWidget {
  final PlateauInfo plateauInfo;

  const PlateauSuggestionDialog({
    super.key,
    required this.plateauInfo,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      backgroundColor: colorScheme.surface,
      title: Row(
        children: [
          Icon(
            Icons.trending_flat,
            color: _getPlateauColor(plateauInfo.plateauType),
            size: 24.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'Plateau Rilevato',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            plateauInfo.exerciseName,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            plateauInfo.detailedDescription,
            style: TextStyle(
              fontSize: 14.sp,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Suggerimenti:',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 8.h),
          ...plateauInfo.suggestions.take(2).map((suggestion) =>
              Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Row(
                  children: [
                    Icon(
                      _getSuggestionIcon(suggestion.type),
                      color: _getPlateauColor(plateauInfo.plateauType),
                      size: 16.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        suggestion.description,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: _getConfidenceColor(suggestion.confidence).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        suggestion.confidenceText,
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: _getConfidenceColor(suggestion.confidence),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Ignora',
            style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            // TODO: Implementa apply suggestion se necessario
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _getPlateauColor(plateauInfo.plateauType),
            foregroundColor: Colors.white,
          ),
          child: const Text('Applica'),
        ),
      ],
    );
  }

  Color _getPlateauColor(PlateauType type) {
    switch (type) {
      case PlateauType.lightWeight:
        return Colors.orange;
      case PlateauType.heavyWeight:
        return Colors.red;
      case PlateauType.lowReps:
        return Colors.blue;
      case PlateauType.highReps:
        return Colors.purple;
      case PlateauType.moderate:
        return Colors.deepOrange;
    }
  }

  IconData _getSuggestionIcon(SuggestionType type) {
    switch (type) {
      case SuggestionType.increaseWeight:
        return Icons.arrow_upward;
      case SuggestionType.increaseReps:
        return Icons.add;
      case SuggestionType.advancedTechnique:
        return Icons.psychology;
      case SuggestionType.reduceRest:
        return Icons.timer;
      case SuggestionType.changeTempo:
        return Icons.speed;
    }
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }
}