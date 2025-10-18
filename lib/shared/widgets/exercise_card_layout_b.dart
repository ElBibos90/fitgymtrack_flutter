// lib/shared/widgets/exercise_card_layout_b.dart
// 🎨 LAYOUT B: Side-by-side (Come STRONG)
// Layout unificato per tutti gli esercizi (normale, superset, circuit)
// Data: 17 Ottobre 2025

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/workout_design_system.dart';
import 'weight_reps_card.dart';
import 'use_previous_data_toggle.dart';

/// 🏋️ EXERCISE CARD - LAYOUT B (Side-by-side)
/// Layout unificato per tutti gli esercizi
/// Compatibile con superset, circuit e esercizi singoli
class ExerciseCardLayoutB extends StatelessWidget {
  final String exerciseName;
  final List<String> muscleGroups;
  final String? exerciseImageUrl;
  final double weight;
  final int reps;
  final int currentSeries;
  final int totalSeries;
  final int? restSeconds;
  final bool isModified;
  final bool isCompleted; // 🚀 NUOVO: Indica se l'esercizio è completato
  final bool isTimerActive; // 🚀 NUOVO: Indica se il timer di recupero è attivo
  final VoidCallback onEditParameters;
  final VoidCallback onCompleteSeries;
  final Function(String url, dynamic error)? onImageLoadError; // [NEW_PROGR] Callback per errori immagine
  
  // 🎯 FASE 5: Sistema "Usa Dati Precedenti"
  final bool usePreviousData;
  final ValueChanged<bool>? onUsePreviousDataChanged;
  final bool isLoadingPreviousData;
  final String? previousDataStatusMessage;
  
  // Superset/Circuit specific
  final String? groupType; // 'superset' o 'circuit'
  final List<String>? groupExerciseNames;
  final int? currentExerciseIndex;
  final bool showWarning;

  const ExerciseCardLayoutB({
    super.key,
    required this.exerciseName,
    required this.muscleGroups,
    this.exerciseImageUrl,
    required this.weight,
    required this.reps,
    required this.currentSeries,
    required this.totalSeries,
    this.restSeconds,
    required this.isModified,
    required this.isCompleted, // 🚀 NUOVO: Parametro per esercizio completato
    required this.isTimerActive, // 🚀 NUOVO: Parametro per timer attivo
    required this.onEditParameters,
    required this.onCompleteSeries,
    this.onImageLoadError,
    // 🎯 FASE 5: Sistema "Usa Dati Precedenti"
    this.usePreviousData = false,
    this.onUsePreviousDataChanged,
    this.isLoadingPreviousData = false,
    this.previousDataStatusMessage,
    this.groupType,
    this.groupExerciseNames,
    this.currentExerciseIndex,
    this.showWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Superset/Circuit indicators (se applicabile)
        if (groupType != null) ...[
          _buildGroupIndicators(context),
          SizedBox(height: WorkoutDesignSystem.spacingM.h),
        ],
        
        // Warning (se superset/circuit) - 🎯 FASE 5: RIMOSSO per risparmiare spazio
        // if (showWarning) ...[
        //   _buildWarning(context),
        //   SizedBox(height: WorkoutDesignSystem.spacingM.h),
        // ],

        // Main exercise content
        _buildExerciseContent(context),
      ],
    );
  }

  /// 🔗 Group indicators (Superset/Circuit)
  Widget _buildGroupIndicators(BuildContext context) {
    final isSuperset = groupType == 'superset';
    final icon = isSuperset ? '🔗' : '🔄';
    final title = isSuperset ? 'SUPERSET' : 'CIRCUIT';
    final exerciseCount = groupExerciseNames?.length ?? 0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isSuperset 
              ? [WorkoutDesignSystem.supersetPurple600, WorkoutDesignSystem.supersetPurple700]
              : [WorkoutDesignSystem.circuitOrange600, WorkoutDesignSystem.circuitOrange700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: WorkoutDesignSystem.borderRadiusM,
        boxShadow: _getCardShadow(context),
      ),
      padding: EdgeInsets.all(WorkoutDesignSystem.spacingM.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Row(
            children: [
              Text(
                icon,
                style: TextStyle(fontSize: 16.sp),
              ),
              SizedBox(width: 8.w),
              Text(
                '$title ($exerciseCount esercizi)',
                style: TextStyle(
                  fontSize: WorkoutDesignSystem.fontSizeH3.sp,
                  fontWeight: WorkoutDesignSystem.fontWeightSemiBold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Text(
                'Serie $currentSeries/$totalSeries',
                style: TextStyle(
                  fontSize: WorkoutDesignSystem.fontSizeCaption.sp,
                  fontWeight: WorkoutDesignSystem.fontWeightSemiBold,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          
          SizedBox(height: WorkoutDesignSystem.spacingS.h),
          
          // Exercise list
          if (groupExerciseNames != null) ...[
            Row(
              children: groupExerciseNames!.asMap().entries.map((entry) {
                final index = entry.key;
                final name = entry.value;
                final isCurrent = index == currentExerciseIndex;
                final isCompleted = index < (currentExerciseIndex ?? 0);
                
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: index < groupExerciseNames!.length - 1 ? 8.w : 0),
                    padding: EdgeInsets.symmetric(
                      horizontal: WorkoutDesignSystem.spacingS.w,
                      vertical: WorkoutDesignSystem.spacingXS.h,
                    ),
                    decoration: BoxDecoration(
                      color: isCurrent 
                          ? Colors.white.withValues(alpha: 0.3)
                          : isCompleted
                              ? Colors.green.withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.2),
                      borderRadius: WorkoutDesignSystem.borderRadiusS,
                      border: isCurrent ? Border.all(color: Colors.white, width: 2) : null,
                    ),
                    child: Text(
                      '${index + 1}. ${_truncateName(name)}',
                      style: TextStyle(
                        fontSize: WorkoutDesignSystem.fontSizeSmall.sp,
                        fontWeight: isCurrent 
                            ? WorkoutDesignSystem.fontWeightSemiBold 
                            : WorkoutDesignSystem.fontWeightMedium,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  /// ⚠️ Warning message
  Widget _buildWarning(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(WorkoutDesignSystem.spacingS.w),
      decoration: BoxDecoration(
        color: WorkoutDesignSystem.accent600,
        borderRadius: WorkoutDesignSystem.borderRadiusS,
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_rounded,
            size: 16.sp,
            color: Colors.white,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'NO recupero tra esercizi ${groupType == 'superset' ? 'linkati' : 'del circuit'}',
              style: TextStyle(
                fontSize: WorkoutDesignSystem.fontSizeSmall.sp,
                fontWeight: WorkoutDesignSystem.fontWeightMedium,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🏋️ Main exercise content (Layout B)
  Widget _buildExerciseContent(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: _getCardGradient(context),
        borderRadius: WorkoutDesignSystem.borderRadiusM,
        boxShadow: _getCardShadow(context),
        border: isModified 
            ? Border.all(color: WorkoutDesignSystem.primary600, width: 2)
            : Border.all(color: _getBorderColor(context), width: 1),
      ),
      padding: EdgeInsets.all(WorkoutDesignSystem.spacingM.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise info row (Layout B: Side-by-side)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Exercise image (80x80px)
              Container(
                width: 80.w,
                height: 80.w,
                decoration: BoxDecoration(
                  color: _getImageBackgroundColor(context),
                  borderRadius: WorkoutDesignSystem.borderRadiusS,
                  border: Border.all(
                    color: _getBorderColor(context),
                    width: 1,
                  ),
                ),
                child: exerciseImageUrl != null && exerciseImageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: WorkoutDesignSystem.borderRadiusS,
                        child: CachedNetworkImage(
                          imageUrl: exerciseImageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Center(
                            child: CircularProgressIndicator(
                              color: WorkoutDesignSystem.primary600,
                              strokeWidth: 2.w,
                            ),
                          ),
                          errorWidget: (context, url, error) {
                            // [NEW_PROGR] Log errore caricamento immagine in ExerciseCardLayoutB
                            // ignore: avoid_print
                            print('[NEW_PROGR] Errore CachedNetworkImage: $url, Errore: $error');
                            if (onImageLoadError != null) {
                              onImageLoadError!(url, error);
                            }
                            return _buildImagePlaceholder(context);
                          },
                        ),
                      )
                    : _buildImagePlaceholder(context),
              ),
              
              SizedBox(width: WorkoutDesignSystem.spacingM.w),
              
              // Exercise info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Exercise name
                    Text(
                      exerciseName,
                      style: TextStyle(
                        fontSize: WorkoutDesignSystem.fontSizeH1.sp,
                        fontWeight: WorkoutDesignSystem.fontWeightBold,
                        color: _getTextColor(context),
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    SizedBox(height: WorkoutDesignSystem.spacingXS.h),
                    
                    // Muscle groups
                    Wrap(
                      spacing: 6.w,
                      runSpacing: 4.h,
                      children: muscleGroups.map((muscle) => 
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: _getTagBackgroundColor(context),
                            borderRadius: WorkoutDesignSystem.borderRadiusS,
                          ),
                          child: Text(
                            muscle,
                            style: TextStyle(
                              fontSize: WorkoutDesignSystem.fontSizeSmall.sp,
                              fontWeight: WorkoutDesignSystem.fontWeightMedium,
                              color: _getTagTextColor(context),
                            ),
                          ),
                        ),
                      ).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: WorkoutDesignSystem.spacingM.h),
          
          // Progress info
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: WorkoutDesignSystem.spacingM.w,
              vertical: WorkoutDesignSystem.spacingS.h,
            ),
            decoration: BoxDecoration(
              color: _getProgressBackgroundColor(context),
              borderRadius: WorkoutDesignSystem.borderRadiusS,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Serie: $currentSeries/$totalSeries',
                  style: TextStyle(
                    fontSize: WorkoutDesignSystem.fontSizeBody.sp,
                    fontWeight: WorkoutDesignSystem.fontWeightSemiBold,
                    color: WorkoutDesignSystem.primary600,
                  ),
                ),
                if (restSeconds != null) ...[
                  Text(
                    '⏱️ Recupero: ${_formatRestTime(restSeconds!)}',
                    style: TextStyle(
                      fontSize: WorkoutDesignSystem.fontSizeCaption.sp,
                      fontWeight: WorkoutDesignSystem.fontWeightMedium,
                      color: _getTextColor(context, isSecondary: true),
                    ),
                  ),
                ] else if (groupType != null) ...[
                  Text(
                    '⏱️ Recupero dopo $groupType',
                    style: TextStyle(
                      fontSize: WorkoutDesignSystem.fontSizeCaption.sp,
                      fontWeight: WorkoutDesignSystem.fontWeightMedium,
                      color: _getTextColor(context, isSecondary: true),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          SizedBox(height: WorkoutDesignSystem.spacingM.h),
          
          // 🎯 FASE 5: Toggle "Usa Dati Precedenti"
          if (onUsePreviousDataChanged != null) ...[
            UsePreviousDataToggle(
              usePreviousData: usePreviousData,
              onChanged: onUsePreviousDataChanged!,
              isLoading: isLoadingPreviousData,
              statusMessage: previousDataStatusMessage,
            ),
            SizedBox(height: WorkoutDesignSystem.spacingM.h),
          ],
          
          // Parameters (Weight & Reps)
          Row(
            children: [
              Expanded(
                child: WeightRepsCard.weight(
                  weight: weight,
                  onEdit: onEditParameters,
                  previousWeight: null, // TODO: Implementare storico
                  isModified: isModified,
                  hasPlateauBadge: false, // TODO: Implementare plateau
                ),
              ),
              SizedBox(width: WorkoutDesignSystem.weightRepsCardGap.w),
              Expanded(
                child: WeightRepsCard.reps(
                  reps: reps,
                  onEdit: onEditParameters,
                  previousReps: null, // TODO: Implementare storico
                  isModified: isModified,
                  hasPlateauBadge: false, // TODO: Implementare plateau
                  isIsometric: false, // TODO: Implementare isometric
                ),
              ),
            ],
          ),
          
          SizedBox(height: WorkoutDesignSystem.spacingL.h),
          
          // Complete button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (isCompleted || isTimerActive) ? null : () {
                HapticFeedback.lightImpact();
                onCompleteSeries();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: (isCompleted || isTimerActive)
                    ? Colors.grey[400] 
                    : WorkoutDesignSystem.primary600,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  vertical: WorkoutDesignSystem.spacingM.h,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: WorkoutDesignSystem.borderRadiusM,
                ),
                elevation: (isCompleted || isTimerActive) ? 0 : 2,
              ),
              child: Text(
                isCompleted 
                    ? 'Esercizio Completato' 
                    : isTimerActive
                    ? 'Timer di Recupero Attivo'
                    : 'Completa Serie $currentSeries',
                style: TextStyle(
                  fontSize: WorkoutDesignSystem.fontSizeH3.sp,
                  fontWeight: WorkoutDesignSystem.fontWeightSemiBold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 📸 Image placeholder
  Widget _buildImagePlaceholder(BuildContext context) {
    return Container(
      width: 80.w,
      height: 80.w,
      decoration: BoxDecoration(
        color: _getImageBackgroundColor(context),
        borderRadius: WorkoutDesignSystem.borderRadiusS,
      ),
      child: Icon(
        Icons.fitness_center_rounded,
        size: 32.sp,
        color: _getTextColor(context, isSecondary: true),
      ),
    );
  }

  /// 🔧 Helper methods
  String _truncateName(String name) {
    if (name.length <= 12) return name;
    return '${name.substring(0, 12)}...';
  }

  String _formatRestTime(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}m${remainingSeconds > 0 ? ' ${remainingSeconds}s' : ''}';
  }

  // 🌙 Dark mode helpers
  bool _isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  Color _getTextColor(BuildContext context, {bool isSecondary = false}) {
    if (_isDarkMode(context)) {
      return isSecondary 
          ? WorkoutDesignSystem.darkTextSecondary 
          : WorkoutDesignSystem.darkTextPrimary;
    }
    return isSecondary 
        ? WorkoutDesignSystem.gray700 
        : WorkoutDesignSystem.gray900;
  }

  Color _getBorderColor(BuildContext context) {
    return _isDarkMode(context) 
        ? WorkoutDesignSystem.darkBorder 
        : WorkoutDesignSystem.gray200;
  }

  Color _getImageBackgroundColor(BuildContext context) {
    return _isDarkMode(context) 
        ? WorkoutDesignSystem.darkSurfaceElevated 
        : WorkoutDesignSystem.gray100;
  }

  Color _getTagBackgroundColor(BuildContext context) {
    return _isDarkMode(context) 
        ? WorkoutDesignSystem.darkSurfaceElevated 
        : WorkoutDesignSystem.gray100;
  }

  Color _getTagTextColor(BuildContext context) {
    return _isDarkMode(context) 
        ? WorkoutDesignSystem.darkTextSecondary 
        : WorkoutDesignSystem.gray700;
  }

  Color _getProgressBackgroundColor(BuildContext context) {
    return _isDarkMode(context) 
        ? WorkoutDesignSystem.darkSurfaceElevated 
        : WorkoutDesignSystem.gray50;
  }

  LinearGradient _getCardGradient(BuildContext context) {
    if (_isDarkMode(context)) {
      return isModified
          ? const LinearGradient(
              colors: [WorkoutDesignSystem.darkSurface, WorkoutDesignSystem.darkBackground],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            )
          : WorkoutDesignSystem.cardSubtleGradientDark;
    }
    return isModified
        ? const LinearGradient(
            colors: [Colors.white, WorkoutDesignSystem.primary50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )
        : WorkoutDesignSystem.cardSubtleGradient;
  }

  List<BoxShadow> _getCardShadow(BuildContext context) {
    if (_isDarkMode(context)) {
      return [
        BoxShadow(
          color: const Color(0x1A000000),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];
    }
    return WorkoutDesignSystem.shadowLevel1;
  }
}
