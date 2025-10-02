import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../bloc/courses_bloc.dart';
import '../../bloc/courses_event.dart';
import '../../bloc/courses_state.dart';
import '../../models/course_models_clean.dart';
import '../widgets/course_info_section.dart';
import '../widgets/course_session_tile.dart';

/// 🎓 Modal per i dettagli del corso
class CourseDetailModal extends StatefulWidget {
  final int courseId;

  const CourseDetailModal({
    super.key,
    required this.courseId,
  });

  @override
  State<CourseDetailModal> createState() => _CourseDetailModalState();
}

class _CourseDetailModalState extends State<CourseDetailModal> {
  String? _selectedMonth;
  late CoursesBloc _coursesBloc;

  @override
  void initState() {
    super.initState();
    _coursesBloc = context.read<CoursesBloc>();
    // Carica i dettagli del corso
    _coursesBloc.add(
      LoadCourseDetailsEvent(courseId: widget.courseId),
    );
  }

  @override
  void dispose() {
    // Quando il modal viene chiuso, resetta lo stato del corso
    try {
      _coursesBloc.add(const ResetCourseDetailsEvent());
    } catch (e) {
      // Ignora errori durante il dispose
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: Column(
        children: [
          // Handle per trascinare
          Container(
            margin: EdgeInsets.only(top: 12.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          
          // Header con titolo e pulsante chiudi
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Dettaglio Corso',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close,
                    color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    size: 24.sp,
                  ),
                ),
              ],
            ),
          ),
          
          // Contenuto del modal
          Expanded(
            child: BlocConsumer<CoursesBloc, CoursesState>(
              listener: (context, state) {
                // Carica le sessioni quando i dettagli del corso sono caricati
                if (state is CourseDetailsLoadedState && state.sessions.isEmpty) {
                  context.read<CoursesBloc>().add(
                    LoadCourseSessionsEvent(courseId: widget.courseId),
                  );
                }
              },
              builder: (context, state) {
                
                if (state is CourseDetailsLoadingState) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (state is CourseDetailsErrorState) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64.sp,
                          color: AppColors.error,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'Errore nel caricamento',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          state.message,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 24.h),
                        ElevatedButton(
                          onPressed: () {
                            context.read<CoursesBloc>().add(
                              LoadCourseDetailsEvent(courseId: widget.courseId),
                            );
                          },
                          child: const Text('Riprova'),
                        ),
                      ],
                    ),
                  );
                }
                
                if (state is CourseDetailsLoadedState) {
                  return _buildCourseDetail(state, isDarkMode);
                }
                
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Costruisci il dettaglio del corso
  Widget _buildCourseDetail(CourseDetailsLoadedState state, bool isDarkMode) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<CoursesBloc>().add(
          LoadCourseDetailsEvent(courseId: widget.courseId),
        );
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info corso
            CourseInfoSection(course: state.course),
            
            SizedBox(height: 24.h),
            
            // Selettore mese
            _buildMonthSelector(state, isDarkMode),
            
            SizedBox(height: 16.h),
            
            // Lista sessioni
            _buildSessionsList(state, isDarkMode),
          ],
        ),
      ),
    );
  }

  /// Selettore mese
  Widget _buildMonthSelector(CourseDetailsLoadedState state, bool isDarkMode) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seleziona Mese',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 12.h),
           Wrap(
             spacing: 8.w,
             runSpacing: 8.h,
             children: [
               _buildMonthChip('Mese Corrente', _getCurrentMonth(), state, isDarkMode),
               _buildMonthChip('Prossimo Mese', _getNextMonth(), state, isDarkMode),
             ],
           ),
        ],
      ),
    );
  }

  /// Chip per il mese
  Widget _buildMonthChip(String label, String? month, CourseDetailsLoadedState state, bool isDarkMode) {
    final isSelected = _selectedMonth == month;
    return GestureDetector(
       onTap: () {
         print('[DEBUG] 📅 Modal: Pulsante "$label" cliccato con month=$month');
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
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : (isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            color: isSelected ? Colors.white : (isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  /// Lista sessioni
  Widget _buildSessionsList(CourseDetailsLoadedState state, bool isDarkMode) {
    if (state.sessions.isEmpty) {
      return Container(
        padding: EdgeInsets.all(32.w),
        child: Column(
          children: [
            Icon(
              Icons.event_available_outlined,
              size: 64.sp,
              color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
            SizedBox(height: 16.h),
            Text(
              'Nessuna sessione disponibile',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Non ci sono sessioni programmate per questo periodo',
              style: TextStyle(
                fontSize: 14.sp,
                color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
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
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
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
                 // Mostriamo un dialog di conferma
                 _showCancelDialog(context, session);
               },
             );
          },
        ),
      ],
    );
  }

  /// Ottieni il mese corrente
  String _getCurrentMonth() {
    final now = DateTime.now();
    final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    print('[DEBUG] 📅 Modal: _getCurrentMonth() restituisce $month');
    return month;
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
              //print('[DEBUG] 🚫 Modal Dialog: Pulsante Annulla cliccato');
              Navigator.of(context).pop();
            },
            child: const Text('Annulla'),
          ),
           ElevatedButton(
             onPressed: () {
               print('[DEBUG] 🚫 Modal Dialog: Pulsante Conferma cliccato per sessionId: ${session.id}');
               Navigator.of(context).pop();
               
               // Disdici l'iscrizione alla sessione
               print('[DEBUG] 🚫 Modal Dialog: Chiamata _coursesBloc.add()');
               _coursesBloc.add(CancelSessionEnrollmentEvent(sessionId: session.id));
               print('[DEBUG] 🚫 Modal Dialog: Evento aggiunto al BLoC');
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
