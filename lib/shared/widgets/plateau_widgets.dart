// lib/shared/widgets/plateau_widgets.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/workouts/models/plateau_models.dart';
import '../../features/workouts/bloc/plateau_bloc.dart';

/// 🎯 OPZIONE 1: PlateauIndicator Minimale - Solo Badge + Popup su Tap
/// ✅ PIXEL OVERFLOW FIXED
/// ❌ Rimosso banner invasivo
/// 🔴 Solo badge discreti
/// 📱 Tap → Popup dettagli
class PlateauIndicator extends StatelessWidget {
  final PlateauInfo plateauInfo;
  final VoidCallback? onDismiss;
  final Function(ProgressionSuggestion)? onApplySuggestion;

  const PlateauIndicator({
    super.key,
    required this.plateauInfo,
    this.onDismiss,
    this.onApplySuggestion,
  });

  Color get _plateauColor {
    final colorHex = plateauInfo.colorHex;
    return Color(int.parse(colorHex.substring(1), radix: 16) + 0xFF000000);
  }

  @override
  Widget build(BuildContext context) {
    // 🔧 OPZIONE 1: Completamente rimosso il banner invasivo
    // Ora il plateau è gestito solo dai PlateauBadge sui parameter cards
    return const SizedBox.shrink();
  }
}

/// 🔴 Badge discreto per parameter cards - VERSIONE COMPATTA
class PlateauBadge extends StatelessWidget {
  final PlateauInfo? plateauInfo;
  final VoidCallback? onTap;

  const PlateauBadge({
    super.key,
    this.plateauInfo,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (plateauInfo != null) {
          _showPlateauDialog(context, plateauInfo!);
        } else if (onTap != null) {
          onTap!();
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: const Color(0xFFFF5722).withOpacity(0.9),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Text(
          'Plateau',
          style: TextStyle(
            fontSize: 8.sp,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// 📱 Mostra popup dettagliato su tap
  void _showPlateauDialog(BuildContext context, PlateauInfo plateauInfo) {
    showDialog(
      context: context,
      builder: (context) => PlateauDetailDialog(plateauInfo: plateauInfo),
    );
  }
}

/// 📱 Dialog dettagliato per plateau - VERSIONE COMPATTA E RESPONSIVE
class PlateauDetailDialog extends StatelessWidget {
  final PlateauInfo plateauInfo;

  const PlateauDetailDialog({
    super.key,
    required this.plateauInfo,
  });

  Color get _plateauColor {
    final colorHex = plateauInfo.colorHex;
    return Color(int.parse(colorHex.substring(1), radix: 16) + 0xFF000000);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.7; // Max 70% altezza schermo

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: maxHeight,
          maxWidth: 350.w, // Larghezza fissa per evitare overflow
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header compatto
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: _plateauColor.withOpacity(0.1),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  topRight: Radius.circular(16.r),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.trending_flat,
                    color: _plateauColor,
                    size: 24.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Plateau Rilevato',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: _plateauColor,
                          ),
                        ),
                        Text(
                          '${plateauInfo.sessionsInPlateau} allenamenti identici',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: _plateauColor.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: _plateauColor.withOpacity(0.7),
                      size: 20.sp,
                    ),
                    padding: EdgeInsets.all(4.w),
                    constraints: BoxConstraints(
                      minWidth: 32.w,
                      minHeight: 32.w,
                    ),
                  ),
                ],
              ),
            ),

            // Content scrollabile per evitare overflow
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nome esercizio
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: _plateauColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: _plateauColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        plateauInfo.exerciseName,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: _plateauColor,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    SizedBox(height: 16.h),

                    // Valori attuali - Layout compatto
                    _buildCurrentValues(context),

                    SizedBox(height: 16.h),

                    // Suggerimenti - Compatti
                    _buildSuggestionsList(context),
                  ],
                ),
              ),
            ),

            // Bottom actions
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        // Dismiss plateau
                        context.read<PlateauBloc>().dismissPlateau(plateauInfo.exerciseId);
                      },
                      icon: Icon(Icons.close, size: 16.sp),
                      label: Text(
                        'Nascondi',
                        style: TextStyle(fontSize: 12.sp),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.check, size: 16.sp),
                      label: Text(
                        'OK',
                        style: TextStyle(fontSize: 12.sp),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _plateauColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentValues(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: _plateauColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          // Peso attuale
          Expanded(
            child: _buildValueItem(
              'Peso',
              '${plateauInfo.currentWeight.toStringAsFixed(1)} kg',
              Icons.fitness_center,
            ),
          ),

          SizedBox(width: 16.w),

          // Ripetizioni attuali
          Expanded(
            child: _buildValueItem(
              'Ripetizioni',
              plateauInfo.currentReps.toString(),
              Icons.repeat,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: _plateauColor,
          size: 16.sp,
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.sp,
            color: _plateauColor.withOpacity(0.8),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: _plateauColor,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildSuggestionsList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '💡 Suggerimenti per Progredire:',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: _plateauColor,
          ),
        ),

        SizedBox(height: 8.h),

        // Limita a max 3 suggerimenti per evitare overflow
        ...plateauInfo.suggestions.take(3).map((suggestion) =>
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: _buildSuggestionCard(suggestion, context),
            ),
        ),

        // Mostra il numero dei suggerimenti nascosti
        if (plateauInfo.suggestions.length > 3)
          Padding(
            padding: EdgeInsets.only(top: 4.h),
            child: Text(
              '• E altri ${plateauInfo.suggestions.length - 3} suggerimenti...',
              style: TextStyle(
                fontSize: 11.sp,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSuggestionCard(ProgressionSuggestion suggestion, BuildContext context) {
    final confidenceColor = Color(
      int.parse(suggestion.confidenceColorHex.substring(1), radix: 16) + 0xFF000000,
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: _plateauColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getSuggestionIcon(suggestion.type),
            color: _plateauColor,
            size: 16.sp,
          ),

          SizedBox(width: 8.w),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion.description,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  'Confidenza: ${suggestion.confidenceText}',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: confidenceColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
}

/// Dialog per plateau di gruppo (superset/circuit) - VERSIONE COMPATTA
class GroupPlateauDialog extends StatelessWidget {
  final GroupPlateauAnalysis groupAnalysis;

  const GroupPlateauDialog({
    super.key,
    required this.groupAnalysis,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.8; // Max 80% altezza schermo

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: maxHeight,
          maxWidth: 350.w,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5722).withOpacity(0.1),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  topRight: Radius.circular(16.r),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.trending_flat,
                    color: const Color(0xFFFF5722),
                    size: 24.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Plateau nel ${_getGroupTypeText()}',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFF5722),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${groupAnalysis.exercisesInPlateau}/${groupAnalysis.totalExercises} esercizi',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: const Color(0xFFFF5722).withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Color(0xFFFF5722)),
                    iconSize: 20.sp,
                  ),
                ],
              ),
            ),

            // Content scrollabile
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nome gruppo
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5722).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        groupAnalysis.groupName,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFF5722),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    SizedBox(height: 16.h),

                    // Lista plateau (max 5 per evitare overflow)
                    Text(
                      'Esercizi in plateau:',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 8.h),

                    ...groupAnalysis.plateauList.take(5).map((plateau) =>
                        _buildPlateauItem(plateau, context),
                    ),

                    if (groupAnalysis.plateauList.length > 5)
                      Padding(
                        padding: EdgeInsets.only(top: 8.h),
                        child: Text(
                          '• E altri ${groupAnalysis.plateauList.length - 5} esercizi...',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Bottom button
            Container(
              padding: EdgeInsets.all(16.w),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5722),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    'Chiudi',
                    style: TextStyle(fontSize: 14.sp),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlateauItem(PlateauInfo plateau, BuildContext context) {
    final plateauColor = Color(
      int.parse(plateau.colorHex.substring(1), radix: 16) + 0xFF000000,
    );

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: plateauColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: plateauColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nome esercizio
          Text(
            plateau.exerciseName,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: plateauColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          SizedBox(height: 4.h),

          // Valori e suggerimento in riga compatta
          Row(
            children: [
              Text(
                '${plateau.currentWeight.toStringAsFixed(1)}kg x ${plateau.currentReps}',
                style: TextStyle(fontSize: 10.sp),
              ),
              const Spacer(),
              Text(
                '${plateau.sessionsInPlateau} sessioni',
                style: TextStyle(
                  fontSize: 9.sp,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getGroupTypeText() {
    switch (groupAnalysis.groupType) {
      case 'superset':
        return 'Superset';
      case 'circuit':
        return 'Circuit';
      default:
        return 'Gruppo';
    }
  }
}

/// Widget per mostrare statistiche plateau - VERSIONE COMPATTA
class PlateauStatisticsCard extends StatelessWidget {
  final PlateauStatistics statistics;

  const PlateauStatisticsCard({
    super.key,
    required this.statistics,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.all(16.w),
      child: Padding(
        padding: EdgeInsets.all(12.w), // Padding ridotto
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📊 Statistiche Plateau',
              style: TextStyle(
                fontSize: 14.sp, // Font size ridotto
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),

            SizedBox(height: 12.h),

            // Statistiche principali in layout compatto
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Rilevati',
                    statistics.totalPlateauDetected.toString(),
                    Icons.trending_flat,
                    colorScheme,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Percentuale',
                    '${statistics.globalPlateauPercentage.toStringAsFixed(1)}%',
                    Icons.pie_chart,
                    colorScheme,
                  ),
                ),
              ],
            ),

            // Info compatte se disponibili
            if (statistics.mostCommonPlateauType != null ||
                statistics.mostCommonSuggestionType != null) ...[
              SizedBox(height: 12.h),
              Text(
                statistics.summaryDescription,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, ColorScheme colorScheme) {
    return Column(
      children: [
        Icon(
          icon,
          color: colorScheme.primary,
          size: 20.sp, // Icona più piccola
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp, // Font ridotto
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.sp, // Font ridotto
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}