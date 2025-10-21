import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../shared/widgets/error_handling_widgets.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../bloc/courses_bloc.dart';
import '../../bloc/courses_event.dart';
import '../../bloc/courses_state.dart';
import '../../models/course_models_clean.dart';
import '../widgets/my_course_enrollment_tile.dart';

/// 🎓 Schermata "I Miei Corsi"
class MyCoursesScreen extends StatefulWidget {
  const MyCoursesScreen({super.key});

  @override
  State<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen> {
  @override
  void initState() {
    super.initState();
    // Carica le iscrizioni all'avvio
    context.read<CoursesBloc>().add(const LoadMyEnrollmentsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: CustomAppBar(
        title: 'I Miei Corsi',
        showBackButton: true,
        actions: [
          // Pulsante refresh
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<CoursesBloc>().add(const RefreshMyEnrollmentsEvent());
            },
          ),
        ],
      ),
      body: BlocConsumer<CoursesBloc, CoursesState>(
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
              return _buildEmptyState();
            }
            
            return _buildEnrollmentsList(state);
          }
          
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  /// Lista iscrizioni
  Widget _buildEnrollmentsList(MyEnrollmentsLoadedState state) {
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
                AppColors.primary,
              ),
              SizedBox(height: 12.h),
              ...upcomingEnrollments.map((enrollment) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: MyCourseEnrollmentTile(
                  enrollment: enrollment,
                  onCancel: () {
                    _showCancelDialog(enrollment);
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
                AppColors.textSecondary,
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
  Widget _buildSectionHeader(String title, int count, Color color) {
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
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(width: 8.w),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12.r),
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
  Widget _buildEmptyState() {
    return EmptyState(
      icon: Icons.school_outlined,
      title: 'Nessun corso iscritto',
      description: 'Non sei ancora iscritto a nessun corso.\nEsplora i corsi disponibili e iscriviti!',
      buttonText: 'Vedi Corsi Disponibili',
      onButtonPressed: () {
        context.push('/courses');
      },
    );
  }

  /// Dialog conferma annullamento
  void _showCancelDialog(MyEnrollment enrollment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annulla Iscrizione'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sei sicuro di voler annullare l\'iscrizione a:'),
            SizedBox(height: 8.h),
            Text(
              enrollment.courseTitle,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 4.h),
            Text('${enrollment.formattedSessionDate} - ${enrollment.formattedTime}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<CoursesBloc>().add(
                CancelEnrollmentEvent(enrollmentId: enrollment.enrollmentId),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Conferma'),
          ),
        ],
      ),
    );
  }
}
