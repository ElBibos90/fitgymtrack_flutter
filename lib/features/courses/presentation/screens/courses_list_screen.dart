import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../shared/widgets/loading_shimmer_widgets.dart';
import '../../../../shared/widgets/error_handling_widgets.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../bloc/courses_bloc.dart';
import '../../models/course_models_clean.dart';
import '../../bloc/courses_event.dart';
import '../../bloc/courses_state.dart';
import '../widgets/course_card.dart';
import '../widgets/course_search_bar.dart';
import '../widgets/course_category_filter.dart';
import '../widgets/course_detail_modal.dart';
import '../../../notifications/presentation/widgets/modern_notification_menu.dart';

/// 🎓 Schermata lista corsi disponibili
class CoursesListScreen extends StatefulWidget {
  const CoursesListScreen({super.key});

  @override
  State<CoursesListScreen> createState() => _CoursesListScreenState();
}

class _CoursesListScreenState extends State<CoursesListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    // Carica i corsi all'avvio
    context.read<CoursesBloc>().add(const LoadCoursesEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: CustomAppBar(
        title: 'Corsi Disponibili',
        actions: [
          // Menu notifiche moderno
          ModernNotificationMenu(
            color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
            size: 24.0,
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra di ricerca e filtri
          _buildSearchAndFilters(),
          
          // Lista corsi
          Expanded(
            child: BlocConsumer<CoursesBloc, CoursesState>(
              listener: (context, state) {
                // Gestisci navigazione - ora apriamo un modal invece di navigare
                if (state is NavigateToCourseDetailsState) {
                  _showCourseDetailModal(context, state.courseId);
                }
                
                // Gestisci errori
                if (state is CoursesErrorState) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is CoursesLoadingState) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (state is CoursesErrorState) {
                  return ErrorStateWidget(
                    errorType: ErrorType.unknown,
                    message: state.message,
                    onRetry: () => context.read<CoursesBloc>().add(const LoadCoursesEvent()),
                  );
                }
                
                if (state is CoursesLoadedState) {
                  if (state.filteredCourses.isEmpty) {
                    return _buildEmptyState(state);
                  }
                  
                  return _buildCoursesList(state);
                }
                
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Barra di ricerca e filtri
  Widget _buildSearchAndFilters() {
    return Container(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          // Barra di ricerca
          CourseSearchBar(
            controller: _searchController,
            onSearchChanged: (query) {
              context.read<CoursesBloc>().add(SearchCoursesEvent(query: query));
            },
          ),
          
          SizedBox(height: 12.h),
          
          // Filtro categorie
          CourseCategoryFilter(
            selectedCategory: _selectedCategory,
            onCategoryChanged: (category) {
              setState(() {
                _selectedCategory = category;
              });
              context.read<CoursesBloc>().add(
                FilterCoursesByCategoryEvent(category: category),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Lista corsi
  Widget _buildCoursesList(CoursesLoadedState state) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<CoursesBloc>().add(const RefreshCoursesEvent());
      },
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: state.filteredCourses.length,
        itemBuilder: (context, index) {
          final course = state.filteredCourses[index];
          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: CourseCard(
              course: course,
              onTap: () {
                context.read<CoursesBloc>().add(
                  NavigateToCourseDetailsEvent(courseId: course.id),
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// Stato vuoto
  Widget _buildEmptyState(CoursesLoadedState state) {
    String message;
    String? actionText;
    VoidCallback? onAction;
    
    if (state.searchQuery != null && state.searchQuery!.isNotEmpty) {
      message = 'Nessun corso trovato per "${state.searchQuery}"';
      actionText = 'Cancella ricerca';
      onAction = () {
        _searchController.clear();
        context.read<CoursesBloc>().add(const ResetFiltersEvent());
      };
    } else if (state.selectedCategory != null) {
      message = 'Nessun corso disponibile per la categoria "${state.selectedCategory}"';
      actionText = 'Mostra tutti';
      onAction = () {
        setState(() {
          _selectedCategory = null;
        });
        context.read<CoursesBloc>().add(const ResetFiltersEvent());
      };
    } else {
      message = 'Nessun corso disponibile al momento';
      actionText = 'Aggiorna';
      onAction = () {
        context.read<CoursesBloc>().add(const RefreshCoursesEvent());
      };
    }
    
    return EmptyState(
      icon: Icons.school_outlined,
      title: 'Nessun corso trovato',
      description: message,
      buttonText: actionText,
      onButtonPressed: onAction,
    );
  }

  /// Mostra il modal con i dettagli del corso
  void _showCourseDetailModal(BuildContext context, int courseId) {
    final coursesBloc = context.read<CoursesBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BlocProvider.value(
        value: coursesBloc,
        child: CourseDetailModal(courseId: courseId),
      ),
    );
  }
}
