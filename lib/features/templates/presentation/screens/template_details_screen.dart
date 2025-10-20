// lib/features/templates/presentation/screens/template_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../../shared/widgets/custom_snackbar.dart';
import '../../bloc/template_bloc.dart';
import '../../models/template_models.dart';
import '../widgets/template_exercise_card.dart';
import '../widgets/template_rating_widget.dart';
import '../widgets/template_rating_stats_widget.dart';
import '../widgets/create_workout_dialog.dart';

class TemplateDetailsScreen extends StatefulWidget {
  final int templateId;

  const TemplateDetailsScreen({
    super.key,
    required this.templateId,
  });

  @override
  State<TemplateDetailsScreen> createState() => _TemplateDetailsScreenState();
}

class _TemplateDetailsScreenState extends State<TemplateDetailsScreen> {
  final GlobalKey<TemplateRatingWidgetState> _ratingWidgetKey = GlobalKey<TemplateRatingWidgetState>();

  @override
  void initState() {
    super.initState();
    context.read<TemplateBloc>().add(LoadTemplateDetails(widget.templateId));
  }

  void _createWorkoutFromTemplate(WorkoutTemplate template) {
    showDialog(
      context: context,
      builder: (context) => CreateWorkoutDialog(
        template: template,
        onWorkoutCreated: (response) {
          CustomSnackbar.show(
            context,
            message: 'Scheda creata con successo!',
            isSuccess: true,
          );
          
          // Ricarica i dettagli del template per aggiornare il conteggio utilizzi
          context.read<TemplateBloc>().add(LoadTemplateDetails(widget.templateId));
          
          // Naviga alla dashboard e cambia tab
          _navigateToWorkoutsTab();
        },
      ),
    );
  }

  void _navigateToWorkoutsTab() {
    // Chiudi il dialog
    Navigator.of(context).pop();
    
    // Naviga alla dashboard con parametro per cambiare tab
    context.go('/dashboard?tab=1');
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Dettagli Template'),
        backgroundColor: isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // 🔧 FIX: Ricarica la lista template quando si torna indietro
            context.read<TemplateBloc>().add(const RefreshTemplatesList());
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implementare condivisione template
            },
          ),
        ],
      ),
      body: BlocConsumer<TemplateBloc, TemplateState>(
        listener: (context, state) {
          if (state is TemplateError) {
            CustomSnackbar.show(
              context,
              message: state.message,
              isSuccess: false,
            );
          } else if (state is WorkoutCreatedFromTemplate) {
            CustomSnackbar.show(
              context,
              message: 'Scheda creata con successo!',
              isSuccess: true,
            );
            context.go('/workouts');
          } else if (state is TemplateRated) {
            // 🔧 FIX: Mostra feedback per valutazione inviata
            CustomSnackbar.show(
              context,
              message: state.response.message,
              isSuccess: true,
            );
          }
        },
        builder: (context, state) {
          if (state is TemplateDetailsLoading) {
            return const LoadingOverlay(
              isLoading: true,
              child: SizedBox.shrink(),
            );
          }

          if (state is TemplateDetailsLoaded) {
            final template = state.template;
            final userPremium = state.userPremium;

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header del template
                  _buildTemplateHeader(template, userPremium),
                  
                  SizedBox(height: 16.h),
                  
                  // Informazioni template
                  _buildTemplateInfo(template),
                  
                  SizedBox(height: 16.h),
                  
                  // Esercizi
                  _buildExercisesSection(template),
                  
                  SizedBox(height: 16.h),
                  
                  // Statistiche template
                  _buildRatingStatsSection(template),
                  
                  SizedBox(height: 16.h),
                  
                  // Rating e recensioni
                  _buildRatingSection(template),
                  
                  
                  SizedBox(height: 100.h), // Spazio per il pulsante fisso
                ],
              ),
            );
          }

          return const Center(
            child: Text('Errore nel caricamento del template'),
          );
        },
      ),
      bottomNavigationBar: BlocBuilder<TemplateBloc, TemplateState>(
        builder: (context, state) {
          if (state is TemplateDetailsLoaded) {
            final template = state.template;
            final userPremium = state.userPremium;

            return Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: isDarkMode ? AppColors.cardBackgroundDark : AppColors.cardBackgroundLight,
                border: Border(
                  top: BorderSide(
                    color: AppColors.borderColor,
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: template.userHasAccess
                        ? () => _createWorkoutFromTemplate(template)
                        : _showPremiumDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: template.userHasAccess
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          template.userHasAccess ? Icons.add : Icons.lock,
                          size: 20.sp,
                          color: Colors.white,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          template.userHasAccess
                              ? 'Crea Scheda da Template'
                              : 'Richiede Abbonamento Premium',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildTemplateHeader(WorkoutTemplate template, bool userPremium) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDarkMode 
            ? AppColors.surfaceDark.withValues(alpha: 0.8)
            : AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDarkMode 
              ? AppColors.primary.withValues(alpha: 0.5)
              : AppColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  template.name,
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              if (template.isPremium && !userPremium)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Text(
                    'PREMIUM',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            template.description,
            style: TextStyle(
              fontSize: 16.sp,
              color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Icon(
                _getCategoryIcon(template.categoryIcon),
                size: 20.sp,
                color: Color(int.parse(template.categoryColor.replaceFirst('#', '0xff'))),
              ),
              SizedBox(width: 8.w),
              Text(
                template.categoryName,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateInfo(WorkoutTemplate template) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.cardBackgroundLight,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.borderColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informazioni Template',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          _buildInfoRow(
            icon: Icons.trending_up,
            label: 'Difficoltà',
            value: template.difficultyLevelFormatted,
            color: _getDifficultyColor(template.difficultyLevel),
          ),
          _buildInfoRow(
            icon: Icons.flag,
            label: 'Obiettivo',
            value: template.goalFormatted,
            color: _getGoalColor(template.goal),
          ),
          _buildInfoRow(
            icon: Icons.schedule,
            label: 'Durata stimata',
            value: template.estimatedDurationFormatted,
            color: AppColors.info,
          ),
          _buildInfoRow(
            icon: Icons.calendar_today,
            label: 'Durata programma',
            value: template.durationFormatted,
            color: AppColors.success,
          ),
          _buildInfoRow(
            icon: Icons.fitness_center,
            label: 'Sessioni/settimana',
            value: '${template.sessionsPerWeek}',
            color: AppColors.primary,
          ),
          _buildInfoRow(
            icon: Icons.people,
            label: 'Gruppi muscolari',
            value: template.muscleGroupsFormatted,
            color: AppColors.warning,
          ),
          _buildInfoRow(
            icon: Icons.sports_gymnastics,
            label: 'Attrezzature',
            value: template.equipmentFormatted,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20.sp,
            color: color,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExercisesSection(WorkoutTemplate template) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Esercizi (${template.exercises?.length ?? 0})',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 12.h),
          if (template.exercises != null && template.exercises!.isNotEmpty)
            ...template.exercises!.map((exercise) => Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: TemplateExerciseCard(exercise: exercise),
                ))
          else
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: AppColors.cardBackgroundLight,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppColors.borderColor,
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  'Nessun esercizio disponibile',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRatingStatsSection(WorkoutTemplate template) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: TemplateRatingStatsWidget(
        template: template,
        showDetails: true,
      ),
    );
  }

  Widget _buildRatingSection(WorkoutTemplate template) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Valuta questo template',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 12.h),
          TemplateRatingWidget(
            key: _ratingWidgetKey,
            template: template,
            onRatingSubmitted: (rating, review) {
              context.read<TemplateBloc>().add(RateTemplate(
                TemplateRatingRequest(
                  templateId: template.id,
                  rating: rating,
                  review: review,
                ),
              ));
            },
            onRatingSuccess: () {
              // 🔧 FIX: Resetta lo stato di loading del widget
              _ratingWidgetKey.currentState?.resetLoadingState();
            },
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String iconName) {
    switch (iconName) {
      case 'fitness_center':
        return Icons.fitness_center;
      case 'accessibility':
        return Icons.accessibility;
      case 'sports_gymnastics':
        return Icons.sports_gymnastics;
      case 'sports_mma':
        return Icons.sports_mma;
      case 'self_improvement':
        return Icons.self_improvement;
      case 'accessibility_new':
        return Icons.accessibility_new;
      case 'apps':
        return Icons.apps;
      default:
        return Icons.fitness_center;
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'beginner':
        return AppColors.success;
      case 'intermediate':
        return AppColors.warning;
      case 'advanced':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _getGoalColor(String goal) {
    switch (goal) {
      case 'strength':
        return AppColors.error;
      case 'hypertrophy':
        return AppColors.primary;
      case 'endurance':
        return AppColors.info;
      case 'weight_loss':
        return AppColors.success;
      case 'general':
        return AppColors.textSecondary;
      default:
        return AppColors.textSecondary;
    }
  }

  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Template Premium'),
        content: const Text(
          'Questo template è disponibile solo per utenti Premium. '
          'Aggiorna il tuo abbonamento per accedere a tutti i template professionali.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/subscription');
            },
            child: const Text('Aggiorna'),
          ),
        ],
      ),
    );
  }
}
