// lib/features/home/presentation/widgets/quick_actions_grid.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/ui_animations.dart';
import '../../models/quick_action.dart';
import '../../services/dashboard_service.dart';

/// Widget per visualizzare la griglia delle Quick Actions
/// ✅ FIX: Ora supporta callback functions per navigazione corretta
class QuickActionsGrid extends StatelessWidget {
  final bool showSecondaryActions;
  final int crossAxisCount;
  final double childAspectRatio;

  // 🆕 CALLBACK FUNCTIONS per navigazione corretta
  final VoidCallback? onNavigateToWorkouts;
  final VoidCallback? onNavigateToAchievements;
  final VoidCallback? onNavigateToProfile;

  const QuickActionsGrid({
    super.key,
    this.showSecondaryActions = false,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.3,
    // 🆕 Aggiunti parametri per callback
    this.onNavigateToWorkouts,
    this.onNavigateToAchievements,
    this.onNavigateToProfile,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // ✅ FIX: Ottieni le azioni principali CON callback functions
    final primaryActions = DashboardService.getQuickActions(
      context,
      onNavigateToWorkouts: onNavigateToWorkouts,
      onNavigateToAchievements: onNavigateToAchievements,
      onNavigateToProfile: onNavigateToProfile,
    );

    // Opzionalmente aggiungi azioni secondarie
    final actions = showSecondaryActions
        ? [...primaryActions, ...DashboardService.getSecondaryActions(context)]
        : primaryActions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titolo sezione
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
          child: Text(
            'Azioni Rapide',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),

        // Griglia azioni
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16.w,
              mainAxisSpacing: 16.h,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: actions.length,
            itemBuilder: (context, index) {
              return AnimatedListItem(
                index: index,
                delay: const Duration(milliseconds: 100),
                child: QuickActionCard(
                  action: actions[index],
                  isDarkMode: isDarkMode,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Card singola per Quick Action - ✅ NON MODIFICATA
class QuickActionCard extends StatelessWidget {
  final QuickAction action;
  final bool isDarkMode;

  const QuickActionCard({
    super.key,
    required this.action,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: action.isEnabled ? action.onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: _getBackgroundColor(),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: action.isEnabled ? _getBoxShadow() : null,
          border: isDarkMode
              ? Border.all(
              color: action.isEnabled
                  ? Colors.grey.shade700
                  : Colors.grey.shade800,
              width: 0.5
          )
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icona con background colorato
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: action.color.withValues(alpha: action.isEnabled ? 0.1 : 0.05),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                action.icon,
                color: action.isEnabled
                    ? action.color
                    : action.color.withValues(alpha: 0.4),
                size: 24.sp,
              ),
            ),

            SizedBox(height: 8.h),

            // Titolo
            Flexible(
              child: Text(
                action.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: _getTextColor(),
                  height: 1.1,
                ),
              ),
            ),

            // Badge "Presto" per azioni disabilitate
            if (!action.isEnabled) ...[
              SizedBox(height: 4.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  'Presto',
                  style: TextStyle(
                    fontSize: 8.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Colore di background basato su tema e stato
  Color _getBackgroundColor() {
    if (!action.isEnabled) {
      return isDarkMode
          ? AppColors.surfaceDark.withValues(alpha: 0.5)
          : Colors.white.withValues(alpha: 0.5);
    }

    return isDarkMode ? AppColors.surfaceDark : Colors.white;
  }

  /// Colore del testo basato su tema e stato
  Color _getTextColor() {
    if (!action.isEnabled) {
      return isDarkMode
          ? Colors.grey.shade500
          : Colors.grey.shade500;
    }

    return isDarkMode ? Colors.white : AppColors.textPrimary;
  }

  /// Box shadow per card abilitate
  List<BoxShadow> _getBoxShadow() {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.1),
        blurRadius: 8.0,
        offset: const Offset(0, 2),
      ),
    ];
  }
}