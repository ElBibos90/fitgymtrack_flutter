import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/error_handling_widgets.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../bloc/courses_bloc.dart';
import '../../bloc/courses_event.dart';
import '../../bloc/courses_state.dart';
import '../../models/course_models_clean.dart';
import '../widgets/my_course_enrollment_tile.dart';

/// 🎓 Tab "I Miei Corsi" - Mostra le iscrizioni dell'utente (usa MyEnrollment)
class MyCoursesTab extends StatelessWidget {
  const MyCoursesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return BlocConsumer<CoursesBloc, CoursesState>(
      listener: (context, state) {
        // Gestisci errori
        if (state is MyEnrollmentsErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
        
        if (state is CourseOperationErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
        
        if (state is CourseOperationSuccessState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
            ),
          );
          
          // Ricarica le iscrizioni dopo un'operazione riuscita
          context.read<CoursesBloc>().add(const LoadMyEnrollmentsEvent());
        }
      },
      builder: (context, state) {
        if (state is MyEnrollmentsLoadingState) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (state is MyEnrollmentsErrorState) {
          return ErrorStateWidget(
            errorType: ErrorType.unknown,
            message: state.message,
            onRetry: () => context.read<CoursesBloc>().add(const LoadMyEnrollmentsEvent()),
          );
        }
        
        if (state is MyEnrollmentsLoadedState) {
          if (state.enrollments.isEmpty) {
            return _buildEmptyState(context);
          }
          
          return _buildEnrollmentsList(context, state, isDarkMode);
        }
        
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  /// Lista iscrizioni
  Widget _buildEnrollmentsList(
    BuildContext context,
    MyEnrollmentsLoadedState state,
    bool isDarkMode,
  ) {
    // Raggruppa per stato
    final upcomingEnrollments = state.enrollments
        .where((e) => e.isEnrolled && e.isSessionScheduled)
        .toList();
    
    final pastEnrollments = state.enrollments
        .where((e) => !e.isSessionScheduled || e.hasAttended)
        .toList();
    
    return RefreshIndicator(
      onRefresh: () async {
        context.read<CoursesBloc>().add(const RefreshMyEnrollmentsEvent());
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Iscrizioni prossime
            if (upcomingEnrollments.isNotEmpty) ...[
              _buildSectionHeader(
                'Prossime Sessioni',
                upcomingEnrollments.length,
                isDarkMode ? const Color(0xFF90CAF9) : AppColors.indigo600,
                isDarkMode,
              ),
              SizedBox(height: 12.h),
              ...upcomingEnrollments.map((enrollment) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: MyCourseEnrollmentTile(
                  enrollment: enrollment,
                  onCancel: () {
                    _showCancelDialog(context, enrollment);
                  },
                ),
              )),
              SizedBox(height: 24.h),
            ],
            
            // Iscrizioni passate
            if (pastEnrollments.isNotEmpty) ...[
              _buildSectionHeader(
                'Sessioni Passate',
                pastEnrollments.length,
                isDarkMode 
                    ? Colors.white.withValues(alpha: 0.4)
                    : AppColors.textSecondary,
                isDarkMode,
              ),
              SizedBox(height: 12.h),
              ...pastEnrollments.map((enrollment) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: MyCourseEnrollmentTile(
                  enrollment: enrollment,
                  onCancel: null, // Non si può annullare una sessione passata
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  /// Header sezione
  Widget _buildSectionHeader(String title, int count, Color color, bool isDarkMode) {
    return Row(
      children: [
        Container(
          width: 4.w,
          height: 20.h,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2.r),
          ),
        ),
        SizedBox(width: 12.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : AppColors.textPrimary,
          ),
        ),
        SizedBox(width: 8.w),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 12.sp,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// Stato vuoto
  Widget _buildEmptyState(BuildContext context) {
    return EmptyState(
      icon: Icons.school_outlined,
      title: 'Nessuna Iscrizione',
      description: 'Non sei ancora iscritto a nessun corso.\nEsplora i corsi disponibili e trova quello perfetto per te!',
      buttonText: 'Esplora Corsi',
      onButtonPressed: () {
        // Passa al tab "Disponibili" (index 1)
        DefaultTabController.of(context).animateTo(1);
      },
    );
  }

  /// Dialog conferma annullamento
  void _showCancelDialog(BuildContext context, MyEnrollment enrollment) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text(
          'Annulla Iscrizione',
          style: TextStyle(
            color: isDarkMode ? Colors.white : AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sei sicuro di voler annullare l\'iscrizione a:',
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: (isDarkMode ? const Color(0xFF90CAF9) : AppColors.indigo600)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: (isDarkMode ? const Color(0xFF90CAF9) : AppColors.indigo600)
                      .withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    enrollment.courseTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15.sp,
                      color: isDarkMode ? const Color(0xFF90CAF9) : AppColors.indigo600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${enrollment.formattedSessionDate} - ${enrollment.formattedTime}',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (enrollment.isWithin24Hours) ...[
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.warning,
                      size: 16.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'Mancano meno di 24 ore alla sessione',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Chiudi',
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<CoursesBloc>().add(
                CancelEnrollmentEvent(enrollmentId: enrollment.enrollmentId),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: const Text('Conferma Annullamento'),
          ),
        ],
      ),
    );
  }
}

