// lib/shared/widgets/plateau_widgets.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../features/workouts/models/plateau_models.dart';

/// 🎯 PLATEAU BADGE - Badge visibile e cliccabile per plateau rilevati
/// ✅ Design più grande e facilmente cliccabile
/// ✅ Tap per mostrare suggerimenti
/// 🔧 FIX: Dimensioni maggiori e area di tap estesa
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

    final plateauColor = _getPlateauColor(plateauInfo!.plateauType);

    // 🔧 FIX: Area di tap estesa per facilità d'uso
    final badge = GestureDetector(
      onTap: onTap ?? () => _showPlateauDialog(context),
      child: Container(
        padding: EdgeInsets.all(4.w), // Padding per area di tap più grande
        child: Container(
          width: 16.w,  // 🔧 FIX: Raddoppiata da 8.w a 16.w
          height: 16.w, // 🔧 FIX: Raddoppiata da 8.w a 16.w
          decoration: BoxDecoration(
            color: plateauColor,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: Colors.white,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: plateauColor.withValues(alpha:0.6),
                blurRadius: 4,
                offset: const Offset(0, 2),
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(
            Icons.warning_rounded,
            size: 10.w,
            color: Colors.white,
          ),
        ),
      ),
    );

    if (!showTooltip) return badge;

    return Tooltip(
      message: 'Plateau rilevato - Tap per suggerimenti',
      preferBelow: false,
      textStyle: TextStyle(
        fontSize: 12.sp,
        color: Colors.white,
      ),
      decoration: BoxDecoration(
        color: plateauColor.withValues(alpha:0.9),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: badge,
    );
  }

  Color _getPlateauColor(PlateauType type) {
    switch (type) {
      case PlateauType.lightWeight:
        return const Color(0xFFFF9800); // Arancione
      case PlateauType.heavyWeight:
        return const Color(0xFFF44336); // Rosso
      case PlateauType.lowReps:
        return const Color(0xFF2196F3); // Blu
      case PlateauType.highReps:
        return const Color(0xFF9C27B0); // Viola
      case PlateauType.moderate:
        return const Color(0xFFFF5722); // Deep Orange
    }
  }

  void _showPlateauDialog(BuildContext context) {
    if (plateauInfo == null) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => PlateauSuggestionDialog(plateauInfo: plateauInfo!),
    );
  }
}

/// 🎯 PLATEAU SUGGESTION DIALOG - Dialog migliorato con suggerimenti
/// 🔧 FIX: UI più chiara e actionable
class PlateauSuggestionDialog extends StatelessWidget {
  final PlateauInfo plateauInfo;

  const PlateauSuggestionDialog({
    super.key,
    required this.plateauInfo,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final plateauColor = _getPlateauColor(plateauInfo.plateauType);

    return AlertDialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: plateauColor.withValues(alpha:0.15),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              Icons.trending_flat_rounded,
              color: plateauColor,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plateau Rilevato',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  plateauInfo.typeDescription,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: plateauColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nome esercizio e dettagli
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withValues(alpha:0.5),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
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
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      _buildInfoChip(
                        context,
                        '${plateauInfo.currentWeight.toStringAsFixed(1)} kg',
                        Icons.fitness_center_rounded,
                        plateauColor,
                      ),
                      SizedBox(width: 8.w),
                      _buildInfoChip(
                        context,
                        '${plateauInfo.currentReps} reps',
                        Icons.repeat_rounded,
                        plateauColor,
                      ),
                      SizedBox(width: 8.w),
                      _buildInfoChip(
                        context,
                        '${plateauInfo.sessionsInPlateau} sessioni',
                        Icons.calendar_today_rounded,
                        plateauColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // Suggerimenti
            if (plateauInfo.suggestions.isNotEmpty) ...[
              Text(
                'Suggerimenti per la Progressione:',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 12.h),
              ...plateauInfo.suggestions.take(3).map((suggestion) =>
                  _buildSuggestionCard(context, suggestion, plateauColor),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Capito',
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha:0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            _showProgressionOptions(context);
          },
          style: FilledButton.styleFrom(
            backgroundColor: plateauColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('Applica Suggerimento'),
        ),
      ],
    );
  }

  Widget _buildInfoChip(BuildContext context, String text, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withValues(alpha:0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12.sp,
            color: color,
          ),
          SizedBox(width: 4.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(BuildContext context, ProgressionSuggestion suggestion, Color plateauColor) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: _getConfidenceColor(suggestion.confidence).withValues(alpha:0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: _getConfidenceColor(suggestion.confidence).withValues(alpha:0.15),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              _getSuggestionIcon(suggestion.type),
              color: _getConfidenceColor(suggestion.confidence),
              size: 16.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion.description,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  suggestion.confidenceDescription,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: _getConfidenceColor(suggestion.confidence),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: _getConfidenceColor(suggestion.confidence).withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Text(
              suggestion.confidenceText,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: _getConfidenceColor(suggestion.confidence),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showProgressionOptions(BuildContext context) {
    if (plateauInfo.suggestions.isEmpty) return;

    final bestSuggestion = plateauInfo.bestSuggestion!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Applica Progressione'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Vuoi applicare questo suggerimento al prossimo allenamento?'),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withValues(alpha:0.5),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                bestSuggestion.description,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14.sp,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implementa applicazione del suggerimento
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Suggerimento applicato al prossimo allenamento!'),
                  backgroundColor: _getPlateauColor(plateauInfo.plateauType),
                ),
              );
            },
            child: const Text('Applica'),
          ),
        ],
      ),
    );
  }

  Color _getPlateauColor(PlateauType type) {
    switch (type) {
      case PlateauType.lightWeight:
        return const Color(0xFFFF9800); // Arancione
      case PlateauType.heavyWeight:
        return const Color(0xFFF44336); // Rosso
      case PlateauType.lowReps:
        return const Color(0xFF2196F3); // Blu
      case PlateauType.highReps:
        return const Color(0xFF9C27B0); // Viola
      case PlateauType.moderate:
        return const Color(0xFFFF5722); // Deep Orange
    }
  }

  IconData _getSuggestionIcon(SuggestionType type) {
    switch (type) {
      case SuggestionType.increaseWeight:
        return Icons.arrow_upward_rounded;
      case SuggestionType.increaseReps:
        return Icons.add_rounded;
      case SuggestionType.advancedTechnique:
        return Icons.psychology_rounded;
      case SuggestionType.reduceRest:
        return Icons.timer_rounded;
      case SuggestionType.changeTempo:
        return Icons.speed_rounded;
    }
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return const Color(0xFF4CAF50); // Verde
    if (confidence >= 0.6) return const Color(0xFFFF9800); // Arancione
    return const Color(0xFFF44336); // Rosso
  }
}

/// 🎯 PLATEAU INDICATOR - Indicatore compatto per liste
/// 🔧 FIX: Versione più grande per liste di esercizi
class PlateauIndicator extends StatelessWidget {
  final PlateauInfo? plateauInfo;
  final bool showText;
  final VoidCallback? onTap;

  const PlateauIndicator({
    super.key,
    this.plateauInfo,
    this.showText = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (plateauInfo == null || plateauInfo!.isDismissed) {
      return const SizedBox.shrink();
    }

    final plateauColor = _getPlateauColor(plateauInfo!.plateauType);

    return GestureDetector(
      onTap: onTap ?? () => _showPlateauDialog(context),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: showText ? 8.w : 4.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: plateauColor.withValues(alpha:0.15),
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(color: plateauColor.withValues(alpha:0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.trending_flat_rounded,
              size: 14.sp,
              color: plateauColor,
            ),
            if (showText) ...[
              SizedBox(width: 4.w),
              Text(
                'Plateau',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: plateauColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getPlateauColor(PlateauType type) {
    switch (type) {
      case PlateauType.lightWeight:
        return const Color(0xFFFF9800);
      case PlateauType.heavyWeight:
        return const Color(0xFFF44336);
      case PlateauType.lowReps:
        return const Color(0xFF2196F3);
      case PlateauType.highReps:
        return const Color(0xFF9C27B0);
      case PlateauType.moderate:
        return const Color(0xFFFF5722);
    }
  }

  void _showPlateauDialog(BuildContext context) {
    if (plateauInfo == null) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => PlateauSuggestionDialog(plateauInfo: plateauInfo!),
    );
  }
}

/// 🎯 PLATEAU SUMMARY CARD - Card riassuntiva per dashboard
class PlateauSummaryCard extends StatelessWidget {
  final List<PlateauInfo> plateaus;
  final VoidCallback? onViewAll;

  const PlateauSummaryCard({
    super.key,
    required this.plateaus,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    if (plateaus.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final activePlateaus = plateaus.where((p) => !p.isDismissed).toList();

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.trending_flat_rounded,
                  color: Colors.orange,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Plateau Rilevati',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                if (onViewAll != null)
                  TextButton(
                    onPressed: onViewAll,
                    child: const Text('Vedi tutti'),
                  ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              '${activePlateaus.length} esercizi in plateau',
              style: TextStyle(
                fontSize: 14.sp,
                color: colorScheme.onSurface.withValues(alpha:0.7),
              ),
            ),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 4.h,
              children: activePlateaus.take(3).map((plateau) =>
                  PlateauIndicator(
                    plateauInfo: plateau,
                    showText: true,
                  ),
              ).toList(),
            ),
          ],
        ),
      ),
    );
  }
}