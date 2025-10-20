import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../bloc/courses_bloc.dart';
import '../../bloc/courses_state.dart';
import '../../models/course_models_clean.dart';

/// 📅 Tile per un'iscrizione a un corso
class MyCourseEnrollmentTile extends StatelessWidget {
  final CourseEnrollment enrollment;
  final VoidCallback? onCancel;

  const MyCourseEnrollmentTile({
    super.key,
    required this.enrollment,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CoursesBloc, CoursesState>(
      builder: (context, state) {
        // Verifica se l'operazione è in corso per questa iscrizione
        final isCancelling = state is CourseOperationInProgressState && 
            state.enrollmentId == enrollment.enrollmentId;
        
        return Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con titolo corso e stato
              Row(
                children: [
                  // Icona categoria
                  Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: BoxDecoration(
                      color: Color(enrollment.colorValue).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      _getCategoryIcon(enrollment.category),
                      color: Color(enrollment.colorValue),
                      size: 20.sp,
                    ),
                  ),
                  
                  SizedBox(width: 12.w),
                  
                  // Titolo corso
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          enrollment.courseTitle,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          enrollment.category,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Badge stato iscrizione
                  _buildEnrollmentStatusBadge(),
                ],
              ),
              
              SizedBox(height: 12.h),
              
              // Info sessione
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Column(
                  children: [
                    // Data e orario
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16.sp,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          enrollment.formattedSessionDate,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.access_time,
                          size: 16.sp,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          enrollment.formattedTime,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    
                    if (enrollment.location.isNotEmpty) ...[
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 16.sp,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              enrollment.location,
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              SizedBox(height: 12.h),
              
              // Footer con info partecipazione e pulsante
              Row(
                children: [
                  // Info partecipazione
                  _buildParticipationInfo(),
                  
                  const Spacer(),
                  
                  // Pulsante azione
                  _buildActionButton(isCancelling),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Badge stato iscrizione
  Widget _buildEnrollmentStatusBadge() {
    Color badgeColor;
    String badgeText;
    
    if (enrollment.hasAttended) {
      badgeColor = AppColors.success;
      badgeText = 'Partecipato';
    } else if (enrollment.isEnrolled && enrollment.isSessionScheduled) {
      badgeColor = AppColors.primary;
      badgeText = 'Iscritto';
    } else if (!enrollment.isSessionScheduled) {
      badgeColor = AppColors.textSecondary;
      badgeText = 'Completata';
    } else {
      badgeColor = AppColors.warning;
      badgeText = 'In Attesa';
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
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

  /// Info partecipazione
  Widget _buildParticipationInfo() {
    return Row(
      children: [
        Icon(
          enrollment.hasAttended ? Icons.check_circle : Icons.pending,
          size: 16.sp,
          color: enrollment.hasAttended ? AppColors.success : AppColors.textSecondary,
        ),
        SizedBox(width: 4.w),
        Text(
          enrollment.hasAttended 
              ? 'Hai partecipato'
              : enrollment.isSessionScheduled 
                  ? 'In attesa'
                  : 'Sessione completata',
          style: TextStyle(
            fontSize: 12.sp,
            color: enrollment.hasAttended ? AppColors.success : AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Pulsante azione
  Widget _buildActionButton(bool isCancelling) {
    // Non mostrare pulsante per sessioni passate o già partecipate
    if (!enrollment.isEnrolled || !enrollment.isSessionScheduled || enrollment.hasAttended) {
      return const SizedBox.shrink();
    }
    
    return CustomButton(
      text: isCancelling ? 'Annullamento...' : 'Annulla',
      onPressed: isCancelling ? null : onCancel,
      size: ButtonSize.small,
      type: ButtonType.outline,
      isLoading: isCancelling,
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
