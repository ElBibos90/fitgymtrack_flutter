import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/config/app_config.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../bloc/workout_bloc.dart';
import '../../models/workout_models.dart';

class WorkoutPlanDetailsScreen extends StatefulWidget {
  final int workoutPlanId;
  final String workoutPlanName;

  const WorkoutPlanDetailsScreen({
    super.key,
    required this.workoutPlanId,
    required this.workoutPlanName,
  });

  @override
  State<WorkoutPlanDetailsScreen> createState() => _WorkoutPlanDetailsScreenState();
}

class _WorkoutPlanDetailsScreenState extends State<WorkoutPlanDetailsScreen> {
  @override
  void initState() {
    super.initState();
    // Carica gli esercizi della scheda
    context.read<WorkoutBloc>().add(GetWorkoutExercises(schedaId: widget.workoutPlanId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.workoutPlanName,
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Theme.of(context).textTheme.titleLarge?.color,
            size: 20.sp,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BlocConsumer<WorkoutBloc, WorkoutState>(
        listener: (context, state) {
          if (state is WorkoutError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          return LoadingOverlay(
            isLoading: state is WorkoutLoading || state is WorkoutLoadingWithMessage,
            child: _buildBody(context, state),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, WorkoutState state) {
    if (state is WorkoutExercisesLoaded && state.schedaId == widget.workoutPlanId) {
      return _buildExercisesList(context, state.exercises);
    }

    if (state is WorkoutError) {
      return _buildErrorState(state);
    }

    // Stato iniziale o loading
    return _buildLoadingState();
  }

  Widget _buildExercisesList(BuildContext context, List<WorkoutExercise> exercises) {
    if (exercises.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppConfig.spacingM.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Esercizi della scheda',
            style: TextStyle(
              color: Theme.of(context).textTheme.titleLarge?.color,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppConfig.spacingM.h),
          ...exercises.map((exercise) => _buildExerciseCard(exercise)),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(WorkoutExercise exercise) {
    return Container(
      margin: EdgeInsets.only(bottom: AppConfig.spacingM.h),
      padding: EdgeInsets.all(AppConfig.spacingM.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Theme.of(context).dividerColor,
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
                  exercise.nome,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.titleLarge?.color,
                    fontWeight: FontWeight.w600,
                    fontSize: 16.sp,
                  ),
                ),
              ),
              if (exercise.imageUrl != null)
                Container(
                  width: 50.w,
                  height: 50.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.r),
                    color: Theme.of(context).cardColor,
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: Image.network(
                      exercise.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            color: AppColors.indigo600.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Icon(
                            Icons.fitness_center,
                            color: AppColors.indigo600,
                            size: 20.sp,
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          decoration: BoxDecoration(
                            color: AppColors.indigo600.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Center(
                            child: SizedBox(
                              width: 16.w,
                              height: 16.h,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.indigo600),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
          if (exercise.descrizione != null && exercise.descrizione!.isNotEmpty) ...[
            SizedBox(height: AppConfig.spacingS.h),
            Text(
              exercise.descrizione!,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 14.sp,
              ),
            ),
          ],
          SizedBox(height: AppConfig.spacingS.h),
          Row(
            children: [
              _buildInfoChip(
                icon: Icons.repeat,
                label: '${exercise.serie} serie',
                color: AppColors.indigo600,
              ),
              SizedBox(width: AppConfig.spacingS.w),
              if (exercise.ripetizioni != null)
                _buildInfoChip(
                  icon: Icons.fitness_center,
                  label: '${exercise.ripetizioni} rip',
                  color: AppColors.green600,
                ),
              if (exercise.peso != null && exercise.peso! > 0) ...[
                SizedBox(width: AppConfig.spacingS.w),
                _buildInfoChip(
                  icon: Icons.scale,
                  label: '${exercise.peso} kg',
                  color: AppColors.orange600,
                ),
              ],
            ],
          ),
          if (exercise.tempoRecupero != null && exercise.tempoRecupero! > 0) ...[
            SizedBox(height: AppConfig.spacingS.h),
            _buildInfoChip(
              icon: Icons.timer,
              label: '${exercise.tempoRecupero} min recupero',
              color: AppColors.warning,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppConfig.spacingS.w,
        vertical: 4.h,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14.sp,
            color: color,
          ),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center_outlined,
            size: 80.sp,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
          SizedBox(height: AppConfig.spacingL.h),
          Text(
            'Nessun esercizio',
            style: TextStyle(
              color: Theme.of(context).textTheme.titleLarge?.color,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppConfig.spacingS.h),
          Text(
            'Questa scheda non contiene esercizi',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontSize: 14.sp,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Caricamento esercizi...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(WorkoutError state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80.sp,
            color: AppColors.error,
          ),
          SizedBox(height: AppConfig.spacingL.h),
          Text(
            'Errore nel caricamento',
            style: TextStyle(
              color: AppColors.error,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppConfig.spacingS.h),
          Text(
            state.message,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontSize: 14.sp,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppConfig.spacingXL.h),
          ElevatedButton(
            onPressed: () {
              context.read<WorkoutBloc>().add(GetWorkoutExercises(schedaId: widget.workoutPlanId));
            },
            child: const Text('Riprova'),
          ),
        ],
      ),
    );
  }
}
