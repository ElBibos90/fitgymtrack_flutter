import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../models/course_models_clean.dart';

/// 🎓 Card per visualizzare un corso
class CourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback? onTap;

  const CourseCard({
    super.key,
    required this.course,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con titolo e categoria
              Row(
                children: [
                  // Icona categoria
                  Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: BoxDecoration(
                      color: Color(course.colorValue).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      _getCategoryIcon(course.category ?? 'Generale'),
                      color: Color(course.colorValue),
                      size: 20.sp,
                    ),
                  ),
                  
                  SizedBox(width: 12.w),
                  
                  // Titolo e categoria
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.title,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          course.category ?? 'Generale',
                          style: TextStyle(
                            fontSize: 12.sp,
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
              
              SizedBox(height: 12.h),
              
              // Descrizione
              if (course.description?.isNotEmpty == true) ...[
                Text(
                  course.description!,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 12.h),
              ],
              
              // Info orari e giorni
              Row(
                children: [
                  // Orario
                  _buildInfoChip(
                    icon: Icons.access_time,
                    text: course.formattedTime,
                    isDarkMode: isDarkMode,
                  ),
                  
                  SizedBox(width: 8.w),
                  
                  // Giorni
                  Expanded(
                    child: _buildInfoChip(
                      icon: Icons.calendar_today,
                      text: course.formattedDays,
                      isDarkMode: isDarkMode,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 12.h),
              
              // Footer con posti e pulsante
              Row(
                children: [
                  // Info posti
                  if (course.hasLimitedSpots) ...[
                    Icon(
                      Icons.people_outline,
                      size: 16.sp,
                      color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'Max ${course.maxParticipants} partecipanti',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
                      ),
                    ),
                  ] else ...[
                    Icon(
                      Icons.people_outline,
                      size: 16.sp,
                      color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'Posti illimitati',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
                      ),
                    ),
                  ],
                  
                  const Spacer(),
                  
                  // Pulsante dettagli
                  GestureDetector(
                    onTap: onTap,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: Color(course.colorValue).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Text(
                        'Dettagli',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Color(course.colorValue),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Badge stato corso
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
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        badgeText,
        style: TextStyle(
          fontSize: 10.sp,
          color: badgeColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Chip informativo
  Widget _buildInfoChip({
    required IconData icon,
    required String text,
    required bool isDarkMode,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14.sp,
            color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
          SizedBox(width: 4.w),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.sp,
                color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
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
