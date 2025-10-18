// lib/shared/widgets/use_previous_data_toggle.dart
// 🎯 TOGGLE "USA DATI PRECEDENTI" - Sistema Fase 5
// Toggle switch per decidere se caricare automaticamente dati precedenti
// Data: 17 Ottobre 2025

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/workout_design_system.dart';

/// 🎯 Toggle Switch per "Usa Dati Precedenti"
/// Permette all'utente di decidere se caricare automaticamente peso/ripetizioni dell'ultimo allenamento
class UsePreviousDataToggle extends StatelessWidget {
  final bool usePreviousData;
  final ValueChanged<bool> onChanged;
  final bool isLoading;
  final String? statusMessage;

  const UsePreviousDataToggle({
    super.key,
    required this.usePreviousData,
    required this.onChanged,
    this.isLoading = false,
    this.statusMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: _getBackgroundColor(context),
        borderRadius: WorkoutDesignSystem.borderRadiusM,
        border: Border.all(
          color: _getBorderColor(context),
          width: 1,
        ),
        boxShadow: _getCardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con icona e titolo
          Row(
            children: [
              Icon(
                Icons.history,
                size: 20.sp,
                color: _getIconColor(context),
              ),
              SizedBox(width: 8.w),
              Text(
                'Usa Dati Precedenti',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: WorkoutDesignSystem.fontWeightSemiBold,
                  color: _getTextColor(context),
                ),
              ),
              Spacer(),
              // Toggle switch
              Switch(
                value: usePreviousData,
                onChanged: isLoading ? null : onChanged,
                activeColor: WorkoutDesignSystem.primary600,
                inactiveThumbColor: _getTextColor(context, isSecondary: true),
                inactiveTrackColor: _getBorderColor(context),
              ),
            ],
          ),
          
          SizedBox(height: 8.h),
          
          // Descrizione
          Text(
            usePreviousData 
                ? 'Carica automaticamente peso e ripetizioni dell\'ultimo allenamento'
                : 'Mostra solo confronto con l\'ultimo allenamento',
            style: TextStyle(
              fontSize: 12.sp,
              color: _getTextColor(context, isSecondary: true),
              height: 1.3,
            ),
          ),
          
          // Status message (se presente)
          if (statusMessage != null) ...[
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: _getStatusBackgroundColor(context),
                borderRadius: WorkoutDesignSystem.borderRadiusS,
              ),
              child: Row(
                children: [
                  Icon(
                    _getStatusIcon(),
                    size: 14.sp,
                    color: _getStatusColor(context),
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      statusMessage!,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: _getStatusColor(context),
                        fontWeight: WorkoutDesignSystem.fontWeightMedium,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 🌙 DARK MODE HELPERS
  bool _isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  Color _getBackgroundColor(BuildContext context) {
    return _isDarkMode(context) 
        ? WorkoutDesignSystem.darkSurface
        : Colors.white;
  }

  Color _getBorderColor(BuildContext context) {
    return _isDarkMode(context) 
        ? WorkoutDesignSystem.darkBorder
        : WorkoutDesignSystem.gray200;
  }

  Color _getTextColor(BuildContext context, {bool isSecondary = false}) {
    if (_isDarkMode(context)) {
      return isSecondary 
          ? WorkoutDesignSystem.darkTextSecondary 
          : WorkoutDesignSystem.darkTextPrimary;
    }
    return isSecondary 
        ? WorkoutDesignSystem.neutral600 
        : WorkoutDesignSystem.gray900;
  }

  Color _getIconColor(BuildContext context) {
    return _isDarkMode(context) 
        ? WorkoutDesignSystem.primary400
        : WorkoutDesignSystem.primary600;
  }

  Color _getStatusBackgroundColor(BuildContext context) {
    if (isLoading) {
      return _isDarkMode(context) 
          ? WorkoutDesignSystem.warning500.withValues(alpha: 0.2)
          : WorkoutDesignSystem.warning100;
    }
    return _isDarkMode(context) 
        ? WorkoutDesignSystem.success500.withValues(alpha: 0.2)
        : WorkoutDesignSystem.success100;
  }

  Color _getStatusColor(BuildContext context) {
    if (isLoading) {
      return WorkoutDesignSystem.warning600;
    }
    return WorkoutDesignSystem.success600;
  }

  IconData _getStatusIcon() {
    if (isLoading) {
      return Icons.hourglass_empty;
    }
    return Icons.check_circle;
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