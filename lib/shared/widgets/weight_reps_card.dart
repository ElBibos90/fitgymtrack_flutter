// lib/shared/widgets/weight_reps_card.dart
// 💪 WEIGHT/REPS CARD - Card moderna per peso e ripetizioni
// Mobile-optimized: 155px width × 80px height
// WRAPPER: usa logica esistente, solo UI nuova!

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/workout_design_system.dart';

/// Card moderna per visualizzare e modificare peso o ripetizioni
class WeightRepsCard extends StatelessWidget {
  final String label; // 'PESO' o 'RIPETIZIONI'
  final String value; // '60.0' o '8'
  final String unit; // 'kg' o 'reps' o 'sec'
  final VoidCallback onTap;
  final bool isModified; // Se è stato modificato dall'utente
  final String? comparison; // '+5kg', '-2', '= 0'
  final Color? comparisonColor;
  final bool hasPlateauBadge;
  final double? width;
  final double? height;
  

  const WeightRepsCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.onTap,
    this.isModified = false,
    this.comparison,
    this.comparisonColor,
    this.hasPlateauBadge = false,
    this.width,
    this.height,
  });

  /// Factory per PESO
  factory WeightRepsCard.weight({
    required double weight,
    required VoidCallback onEdit,
    String? previousWeight,
    bool isModified = false,
    bool hasPlateauBadge = false,
  }) {
    // Calcola confronto con peso precedente
    String? comparison;
    Color? comparisonColor;

    if (previousWeight != null) {
      final prev = double.tryParse(previousWeight) ?? 0.0;
      final diff = weight - prev;

      if (diff > 0) {
        comparison = '+${diff.toStringAsFixed(1)}kg';
        comparisonColor = WorkoutDesignSystem.success600;
      } else if (diff < 0) {
        comparison = '${diff.toStringAsFixed(1)}kg';
        comparisonColor = WorkoutDesignSystem.accent600;
      } else {
        comparison = '= 0';
        comparisonColor = WorkoutDesignSystem.gray400;
      }
    }

    return WeightRepsCard(
      label: 'PESO',
      value: weight.toStringAsFixed(1),
      unit: 'kg',
      onTap: onEdit,
      isModified: isModified,
      comparison: comparison,
      comparisonColor: comparisonColor,
      hasPlateauBadge: hasPlateauBadge,
    );
  }

  /// Factory per RIPETIZIONI
  factory WeightRepsCard.reps({
    required int reps,
    required VoidCallback onEdit,
    int? previousReps,
    bool isModified = false,
    bool hasPlateauBadge = false,
    bool isIsometric = false,
  }) {
    // Calcola confronto con reps precedenti
    String? comparison;
    Color? comparisonColor;

    if (previousReps != null) {
      final diff = reps - previousReps;

      if (diff > 0) {
        comparison = '+$diff';
        comparisonColor = WorkoutDesignSystem.success600;
      } else if (diff < 0) {
        comparison = '$diff';
        comparisonColor = WorkoutDesignSystem.accent600;
      } else {
        comparison = '= 0';
        comparisonColor = WorkoutDesignSystem.gray400;
      }
    }

    return WeightRepsCard(
      key: ValueKey('reps_${isIsometric}_$reps'), // 🔥 FORCE REBUILD quando isIsometric cambia
      label: isIsometric ? 'SECONDI' : 'RIPETIZIONI',
      value: reps.toString(),
      unit: isIsometric ? 'sec' : 'reps',
      onTap: onEdit,
      isModified: isModified,
      comparison: comparison,
      comparisonColor: comparisonColor,
      hasPlateauBadge: hasPlateauBadge,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: WorkoutDesignSystem.animationNormal,
        width: width ?? WorkoutDesignSystem.weightRepsCardWidth.w,
        height: height ?? 70.h, // 🔧 FIX: Altezza professionale per contenere tutto il contenuto
        decoration: BoxDecoration(
          gradient: _getCardGradient(context, isModified),
          borderRadius: WorkoutDesignSystem.borderRadiusM,
          boxShadow: _getCardShadow(context),
          border: isModified
              ? Border.all(
                  color: WorkoutDesignSystem.primary600,
                  width: 2,
                )
              : Border.all(
                  color: _getBorderColor(context),
                  width: 1,
                ),
        ),
        child: Stack(
          children: [
            // Content principale
            Padding(
              padding: EdgeInsets.all(8.w), // 🔧 FIX: Padding professionale per comfort visivo
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Label + edit icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: WorkoutDesignSystem.fontSizeCaption.sp,
                          fontWeight: WorkoutDesignSystem.fontWeightSemiBold,
                          color: _getTextColor(context, isSecondary: true),
                          letterSpacing: 0.5,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Badge plateau (se presente)
                          if (hasPlateauBadge) ...[
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 4.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: WorkoutDesignSystem.circuitOrange600,
                                borderRadius: WorkoutDesignSystem.borderRadiusS,
                              ),
                              child: Text(
                                'PLATEAU',
                                style: TextStyle(
                                  fontSize: 8.sp,
                                  fontWeight: WorkoutDesignSystem.fontWeightBold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 4.w),
                          ],
                          // Edit icon
                          Icon(
                            Icons.edit_rounded,
                            size: 14.sp,
                            color: isModified
                                ? WorkoutDesignSystem.primary600
                                : _getTextColor(context, isSecondary: true),
                          ),
                        ],
                      ),
                    ],
                  ),

                  SizedBox(height: 2.h), // 🔧 FIX: Spacer rimosso, spacing fisso

                  // Valore grande
                  Flexible(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          child: Text(
                            value,
                            style: TextStyle(
                              fontSize: 20.sp, // 🔧 FIX: Font size professionale per leggibilità
                              fontWeight: WorkoutDesignSystem.fontWeightBold,
                              fontFamily: WorkoutDesignSystem.fontFamilyNumbers,
                              color: isModified
                                  ? WorkoutDesignSystem.primary600
                                  : _getTextColor(context),
                              height: 1.0,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          unit,
                          style: TextStyle(
                            fontSize: WorkoutDesignSystem.fontSizeCaption.sp,
                            fontWeight: WorkoutDesignSystem.fontWeightMedium,
                            color: _getTextColor(context, isSecondary: true),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 2.h), // 🔧 FIX: Ridotto da 4 a 2

                  // Confronto con ultimo (se presente)
                  if (comparison != null) ...[
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: comparisonColor?.withValues(alpha: 0.1),
                        borderRadius: WorkoutDesignSystem.borderRadiusS,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getComparisonIcon(comparison!),
                            size: 12.sp,
                            color: comparisonColor,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            comparison!,
                            style: TextStyle(
                              fontSize: WorkoutDesignSystem.fontSizeSmall.sp,
                              fontWeight: WorkoutDesignSystem.fontWeightSemiBold,
                              color: comparisonColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Badge "modificato" (se modificato)
            if (isModified)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 6.w,
                    vertical: 3.h,
                  ),
                  decoration: BoxDecoration(
                    color: WorkoutDesignSystem.primary600,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(WorkoutDesignSystem.radiusM),
                      bottomLeft: Radius.circular(WorkoutDesignSystem.radiusM),
                    ),
                  ),
                  child: Icon(
                    Icons.check,
                    size: 12.sp,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getComparisonIcon(String comparison) {
    if (comparison.startsWith('+')) {
      return Icons.trending_up_rounded;
    } else if (comparison.startsWith('-')) {
      return Icons.trending_down_rounded;
    } else {
      return Icons.trending_flat_rounded;
    }
  }

  // 🌙 DARK MODE HELPERS
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

  LinearGradient _getCardGradient(BuildContext context, bool isModified) {
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
    // In dark mode riduciamo le ombre per un look più pulito
    if (_isDarkMode(context)) {
      return [
        BoxShadow(
          color: const Color(0x1A000000), // Molto leggera
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];
    }
    return WorkoutDesignSystem.shadowLevel1;
  }
}

/// Container per 2 card affiancate (peso + reps)
class WeightRepsCardPair extends StatelessWidget {
  final WeightRepsCard weightCard;
  final WeightRepsCard repsCard;

  const WeightRepsCardPair({
    super.key,
    required this.weightCard,
    required this.repsCard,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: WorkoutDesignSystem.mobileHorizontalPadding.w,
      ),
      child: Row(
        children: [
          weightCard,
          SizedBox(width: WorkoutDesignSystem.weightRepsCardGap.w),
          repsCard,
        ],
      ),
    );
  }
}

