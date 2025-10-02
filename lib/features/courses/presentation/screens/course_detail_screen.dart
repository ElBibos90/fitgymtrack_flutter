import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../shared/widgets/loading_shimmer_widgets.dart';
import '../../../../shared/widgets/error_handling_widgets.dart';
import '../../bloc/courses_bloc.dart';
import '../../bloc/courses_event.dart';
import '../../bloc/courses_state.dart';
import '../../models/course_models_clean.dart';
import '../widgets/course_session_tile.dart';
import '../widgets/course_info_section.dart';

/// 🎓 Schermata dettaglio corso
class CourseDetailScreen extends StatefulWidget {
  final int courseId;

  const CourseDetailScreen({
    super.key,
    required this.courseId,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  String? _selectedMonth;
  late CoursesBloc _coursesBloc;

  @override
  void initState() {
    super.initState();
    _coursesBloc = context.read<CoursesBloc>();
    //print('[STATE] CourseDetailScreen: initState - Starting course details for courseId: ${widget.courseId}');
    // Carica prima i dettagli del corso
    _coursesBloc.add(
      LoadCourseDetailsEvent(courseId: widget.courseId),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: CustomAppBar(
        title: 'Dettaglio Corso',
        showBackButton: true,
      ),
      body: BlocConsumer<CoursesBloc, CoursesState>(
        listener: (context, state) {
          // Carica le sessioni quando i dettagli del corso sono caricati
          if (state is CourseDetailsLoadedState && state.sessions.isEmpty) {
            context.read<CoursesBloc>().add(
              LoadCourseSessionsEvent(courseId: widget.courseId),
            );
          }
          
          // Gestisci errori
          if (state is CourseDetailsErrorState) {
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
          if (state is CourseDetailsLoadingState) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (state is CourseDetailsErrorState) {
            return ErrorStateWidget(
              errorType: ErrorType.unknown,
              message: state.message,
              onRetry: () {
                context.read<CoursesBloc>().add(
                  LoadCourseDetailsEvent(courseId: widget.courseId),
                );
              },
            );
          }
          
          if (state is CourseDetailsLoadedState) {
            return _buildCourseDetail(state);
          }
          
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  /// Costruisci il dettaglio del corso
  Widget _buildCourseDetail(CourseDetailsLoadedState state) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<CoursesBloc>().add(
          LoadCourseDetailsEvent(courseId: widget.courseId),
        );
        context.read<CoursesBloc>().add(
          LoadCourseSessionsEvent(courseId: widget.courseId),
        );
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info corso
            CourseInfoSection(course: state.course),
            
            SizedBox(height: 24.h),
            
            // Selettore mese
            _buildMonthSelector(state),
            
            SizedBox(height: 16.h),
            
            // Lista sessioni
            _buildSessionsList(state),
          ],
        ),
      ),
    );
  }

  /// Selettore mese
  Widget _buildMonthSelector(CourseDetailsLoadedState state) {
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
          Text(
            'Seleziona Mese',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          
          SizedBox(height: 12.h),
          
          // Pulsanti mese
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              _buildMonthButton('Mese Corrente', null, state),
              _buildMonthButton('Prossimo Mese', _getNextMonth(), state),
              _buildMonthButton('Mese Dopo', _getMonthAfterNext(), state),
            ],
          ),
        ],
      ),
    );
  }

  /// Pulsante mese
  Widget _buildMonthButton(String label, String? month, CourseDetailsLoadedState state) {
    final isSelected = _selectedMonth == month;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMonth = month;
        });
        context.read<CoursesBloc>().add(
          LoadCourseSessionsEvent(
            courseId: widget.courseId,
            month: month,
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// Lista sessioni
  Widget _buildSessionsList(CourseDetailsLoadedState state) {
    if (state.sessions.isEmpty) {
      return Container(
        padding: EdgeInsets.all(32.w),
        child: Column(
          children: [
            Icon(
              Icons.event_busy,
              size: 48.sp,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 16.h),
            Text(
              'Nessuna sessione disponibile',
              style: TextStyle(
                fontSize: 16.sp,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Non ci sono sessioni programmate per il periodo selezionato',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sessioni Disponibili (${state.sessions.length})',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        
        SizedBox(height: 12.h),
        
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.sessions.length,
          separatorBuilder: (context, index) => SizedBox(height: 8.h),
          itemBuilder: (context, index) {
            final session = state.sessions[index];
            return CourseSessionTile(
              session: session,
              onEnroll: () {
                context.read<CoursesBloc>().add(
                  EnrollInSessionEvent(sessionId: session.id),
                );
              },
              onCancel: () {
                // Per ora, mostriamo un dialog di conferma
                _showCancelDialog(context, session);
              },
            );
          },
        ),
      ],
    );
  }

  /// Ottieni il prossimo mese
  String _getNextMonth() {
    final now = DateTime.now();
    final nextMonth = DateTime(now.year, now.month + 1);
    return '${nextMonth.year}-${nextMonth.month.toString().padLeft(2, '0')}';
  }

  /// Ottieni il mese dopo il prossimo
  String _getMonthAfterNext() {
    final now = DateTime.now();
    final monthAfterNext = DateTime(now.year, now.month + 2);
    return '${monthAfterNext.year}-${monthAfterNext.month.toString().padLeft(2, '0')}';
  }

  /// Dialog conferma disiscrizione
  void _showCancelDialog(BuildContext context, CourseSession session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disdici Corso'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sei sicuro di voler disdire l\'iscrizione a:'),
            SizedBox(height: 8.h),
            Text(
              session.courseTitle ?? 'Corso',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 4.h),
            Text('${session.formattedDate} - ${session.formattedTime}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              //print('[DEBUG] 🚫 Dialog: Pulsante Annulla cliccato');
              Navigator.of(context).pop();
            },
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              //print('[DEBUG] 🚫 Dialog: Pulsante Conferma cliccato per sessionId: ${session.id}');
              Navigator.of(context).pop();
              
              // Disdici l'iscrizione alla sessione
              //print('[DEBUG] 🚫 Dialog: Chiamata context.read<CoursesBloc>()');
              final bloc = context.read<CoursesBloc>();
              //print('[DEBUG] 🚫 Dialog: BLoC ottenuto, aggiungo evento');
              bloc.add(CancelSessionEnrollmentEvent(sessionId: session.id));
              //print('[DEBUG] 🚫 Dialog: Evento aggiunto al BLoC');
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
