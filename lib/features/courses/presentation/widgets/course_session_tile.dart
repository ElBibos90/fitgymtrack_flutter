import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../bloc/courses_bloc.dart';
import '../../bloc/courses_state.dart';
import '../../models/course_models_clean.dart';

/// 📅 Tile per una sessione di corso
class CourseSessionTile extends StatelessWidget {
  final CourseSession session;
  final VoidCallback onEnroll;
  final VoidCallback? onCancel;

  const CourseSessionTile({
    super.key,
    required this.session,
    required this.onEnroll,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return BlocBuilder<CoursesBloc, CoursesState>(
      builder: (context, state) {
        // Verifica se l'operazione è in corso per questa sessione
        final isEnrolling = state is CourseOperationInProgressState && 
            state.sessionId == session.id;
        
        
        // Verifica se l'utente è iscritto (usando i nuovi campi dall'API)
        final isEnrolled = session.isUserEnrolled;
        
        return Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con data e orario
              Row(
                children: [
                  // Data
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: Color(session.colorValue).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      session.formattedDate,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Color(session.colorValue),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  
                  SizedBox(width: 12.w),
                  
                  // Orario
                  Expanded(
                    child: Text(
                      session.formattedTime,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  
                  // Badge stato
                  _buildStatusBadge(),
                ],
              ),
              
              SizedBox(height: 12.h),
              
              // Info sessione
              Row(
                children: [
                  // Luogo
                  if (session.location?.isNotEmpty == true) ...[
                    Icon(
                      Icons.location_on_outlined,
                      size: 16.sp,
                      color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Text(
                        session.location!,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ] else ...[
                    Icon(
                      Icons.location_on_outlined,
                      size: 16.sp,
                      color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'Da definire',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
              
              SizedBox(height: 12.h),
              
              // Info partecipanti e pulsante
              Row(
                children: [
                  // Partecipanti
                  _buildParticipantsInfo(isDarkMode),
                  
                  const Spacer(),
                  
                  // Pulsante iscrizione
                  _buildEnrollButton(isEnrolling, isEnrolled, isDarkMode),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Badge stato sessione
  Widget _buildStatusBadge() {
    Color badgeColor;
    String badgeText;
    
    switch (session.status) {
      case 'scheduled':
        badgeColor = AppColors.success;
        badgeText = 'Programmata';
        break;
      case 'completed':
        badgeColor = AppColors.textSecondary;
        badgeText = 'Completata';
        break;
      case 'cancelled':
        badgeColor = AppColors.error;
        badgeText = 'Cancellata';
        break;
      case 'in_progress':
        badgeColor = AppColors.warning;
        badgeText = 'In Corso';
        break;
      default:
        badgeColor = AppColors.textSecondary;
        badgeText = session.status ?? 'Sconosciuto';
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

  /// Info partecipanti
  Widget _buildParticipantsInfo(bool isDarkMode) {
    return Row(
      children: [
        Icon(
          Icons.people_outline,
          size: 16.sp,
          color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
        ),
        SizedBox(width: 4.w),
        Text(
          session.maxParticipants != null
              ? '${session.currentParticipants ?? 0}/${session.maxParticipants}'
              : '${session.currentParticipants ?? 0}',
          style: TextStyle(
            fontSize: 14.sp,
            color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (session.isFull) ...[
          SizedBox(width: 4.w),
          Text(
            '(Completo)',
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  /// Pulsante iscrizione
  Widget _buildEnrollButton(bool isEnrolling, bool isEnrolled, bool isDarkMode) {
    if (!session.isScheduled) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: AppColors.textSecondary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Text(
          'Non disponibile',
          style: TextStyle(
            fontSize: 12.sp,
            color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }
    
    if (session.isFull && !isEnrolled) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Text(
          'Completo',
          style: TextStyle(
            fontSize: 12.sp,
            color: AppColors.error,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    
    // Se l'utente è iscritto, mostra due pulsanti: "Iscritto" e "Disdici corso"
    if (isEnrolled) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pulsante "Iscritto" (verde)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: AppColors.success),
            ),
            child: Text(
              'Iscritto',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          SizedBox(width: 8.w),
          
          // Pulsante "Disdici corso" (rosso)
          CustomButton(
            text: 'Disdici corso',
            onPressed: isEnrolling ? null : onCancel,
            type: ButtonType.outline,
            size: ButtonSize.small,
            isLoading: isEnrolling,
          ),
        ],
      );
    }
    
    // Se l'utente non è iscritto, mostra il pulsante "Iscriviti"
    return CustomButton(
      text: isEnrolling ? 'Iscrizione...' : 'Iscriviti',
      onPressed: isEnrolling ? null : onEnroll,
      type: ButtonType.primary,
      size: ButtonSize.small,
      isLoading: isEnrolling,
    );
  }
}
