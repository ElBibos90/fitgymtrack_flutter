import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../models/course_models_clean.dart';

/// 📋 Sezione informazioni corso
class CourseInfoSection extends StatelessWidget {
  final Course course;

  const CourseInfoSection({
    super.key,
    required this.course,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con titolo e badge
          Row(
            children: [
              // Icona categoria
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: Color(course.colorValue).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  _getCategoryIcon(course.category ?? 'Generale'),
                  color: Color(course.colorValue),
                  size: 24.sp,
                ),
              ),
              
              SizedBox(width: 16.w),
              
              // Titolo e categoria
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                        color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      course.category ?? 'Generale',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Badge stato
              _buildStatusBadge(),
            ],
          ),
          
          SizedBox(height: 20.h),
          
          // Descrizione
          if (course.description?.isNotEmpty == true) ...[
            Text(
              'Descrizione',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              course.description!,
              style: TextStyle(
                fontSize: 14.sp,
                color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            SizedBox(height: 20.h),
          ],
          
          // Info orari e giorni
          _buildInfoGrid(context),
          
          SizedBox(height: 20.h),
          
          // Info posti
          _buildParticipantsInfo(isDarkMode),
        ],
      ),
    );
  }

  /// Griglia informazioni
  Widget _buildInfoGrid(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          // Orario
          _buildInfoRow(
            icon: Icons.access_time,
            label: 'Orario',
            value: course.formattedTime,
            isDarkMode: isDarkMode,
          ),
          
          SizedBox(height: 12.h),
          
          // Giorni
          _buildInfoRow(
            icon: Icons.calendar_today,
            label: 'Giorni',
            value: course.formattedDays,
            isDarkMode: isDarkMode,
          ),
          
          SizedBox(height: 12.h),
          
          // Tipo ricorrenza
          _buildInfoRow(
            icon: Icons.repeat,
            label: 'Ricorrenza',
            value: _getRecurrenceText(),
            isDarkMode: isDarkMode,
          ),
        ],
      ),
    );
  }

  /// Riga informativa
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDarkMode,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20.sp,
          color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
        ),
        SizedBox(width: 12.w),
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  /// Info partecipanti
  Widget _buildParticipantsInfo(bool isDarkMode) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: course.hasLimitedSpots 
            ? AppColors.warning.withValues(alpha: 0.1)
            : AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: course.hasLimitedSpots 
              ? AppColors.warning.withValues(alpha: 0.3)
              : AppColors.success.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.people_outline,
            size: 20.sp,
            color: course.hasLimitedSpots ? AppColors.warning : AppColors.success,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Partecipanti',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  course.hasLimitedSpots 
                      ? 'Massimo ${course.maxParticipants} partecipanti'
                      : 'Posti illimitati',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: course.hasLimitedSpots ? AppColors.warning : AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Badge stato
  Widget _buildStatusBadge() {
    Color badgeColor;
    String badgeText;
    
    switch (course.status) {
      case 'active':
        badgeColor = AppColors.success;
        badgeText = 'Attivo';
        break;
      case 'inactive':
        badgeColor = AppColors.warning;
        badgeText = 'Inattivo';
        break;
      case 'suspended':
        badgeColor = AppColors.error;
        badgeText = 'Sospeso';
        break;
      default:
        badgeColor = AppColors.textSecondary;
        badgeText = course.status ?? 'Sconosciuto';
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        badgeText,
        style: TextStyle(
          fontSize: 12.sp,
          color: badgeColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Testo ricorrenza
  String _getRecurrenceText() {
    switch (course.recurrenceType) {
      case 'weekly':
        return 'Settimanale';
      case 'daily':
        return 'Giornaliera';
      case 'monthly':
        return 'Mensile';
      case 'custom':
        return 'Personalizzata';
      default:
        return course.recurrenceType ?? 'Non specificato';
    }
  }

  /// Ottieni icona per categoria
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'yoga':
        return Icons.self_improvement;
      case 'pilates':
        return Icons.fitness_center;
      case 'crossfit':
        return Icons.sports_gymnastics;
      case 'cardio':
        return Icons.directions_run;
      case 'muscolazione':
        return Icons.fitness_center;
      case 'danza':
        return Icons.music_note;
      case 'arti marziali':
        return Icons.sports_martial_arts;
      case 'nuoto':
        return Icons.pool;
      case 'spinning':
        return Icons.directions_bike;
      default:
        return Icons.sports;
    }
  }
}
