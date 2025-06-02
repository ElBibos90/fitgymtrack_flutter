// lib/features/workouts/presentation/screens/workout_plans_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../../shared/widgets/custom_snackbar.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/di/dependency_injection.dart';

import '../../bloc/workout_bloc.dart';
import '../../models/workout_plan_models.dart'; // ✅ AGGIUNTO: Import modelli
import '../widgets/workout_widgets.dart';

class WorkoutPlansScreen extends StatefulWidget {
  const WorkoutPlansScreen({super.key});

  @override
  State<WorkoutPlansScreen> createState() => _WorkoutPlansScreenState();
}

class _WorkoutPlansScreenState extends State<WorkoutPlansScreen> {
  late WorkoutBloc _workoutBloc;
  late SessionService _sessionService;

  @override
  void initState() {
    super.initState();
    _workoutBloc = context.read<WorkoutBloc>();
    _sessionService = getIt<SessionService>();
    _loadWorkoutPlans();
  }

  Future<void> _loadWorkoutPlans() async {
    final userId = await _sessionService.getCurrentUserId();
    if (userId != null) {
      _workoutBloc.loadWorkoutPlans(userId);
    }
  }

  Future<void> _refreshWorkoutPlans() async {
    final userId = await _sessionService.getCurrentUserId();
    if (userId != null) {
      _workoutBloc.refreshWorkoutPlans(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Mie Schede',
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/workouts/create'),
          ),
        ],
      ),
      body: BlocConsumer<WorkoutBloc, WorkoutState>(
        listener: (context, state) {
          // ✅ Gestione feedback per le operazioni
          if (state is WorkoutPlanDeleted) {
            CustomSnackbar.show(
              context,
              message: 'Scheda eliminata con successo',
              isSuccess: true,
            );
          } else if (state is WorkoutError) {
            CustomSnackbar.show(
              context,
              message: state.message,
              isSuccess: false,
            );
          }
        },
        builder: (context, state) {
          return LoadingOverlay(
            isLoading: state is WorkoutLoading || state is WorkoutLoadingWithMessage,
            message: state is WorkoutLoadingWithMessage ? state.message : null,
            child: RefreshIndicator(
              onRefresh: _refreshWorkoutPlans,
              child: _buildContent(state),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(WorkoutState state) {
    if (state is WorkoutPlansLoaded) {
      return _buildWorkoutPlansList(state);
    } else if (state is WorkoutError) {
      return _buildErrorState(state);
    } else if (state is WorkoutInitial) {
      return _buildEmptyState();
    }

    // Loading state
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildWorkoutPlansList(WorkoutPlansLoaded state) {
    if (state.workoutPlans.isEmpty) {
      return _buildEmptyPlansState();
    }

    return ListView.builder(
      padding: EdgeInsets.all(AppConfig.spacingM.w),
      itemCount: state.workoutPlans.length,
      itemBuilder: (context, index) {
        final workoutPlan = state.workoutPlans[index];

        return WorkoutPlanCard(
          workoutPlan: workoutPlan,
          onTap: () => _showWorkoutDetails(workoutPlan),
          onEdit: () => _editWorkout(workoutPlan),
          onDelete: () => _deleteWorkout(workoutPlan.id), // ✅ Implementata cancellazione
          onStartWorkout: () => _startWorkout(workoutPlan),
        );
      },
    );
  }

  Widget _buildEmptyPlansState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 80.sp,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: AppConfig.spacingL.h),
          Text(
            'Nessuna scheda trovata',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: AppConfig.spacingS.h),
          Text(
            'Crea la tua prima scheda di allenamento',
            style: TextStyle(
              fontSize: 16.sp,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppConfig.spacingXL.h),
          ElevatedButton.icon(
            onPressed: () => context.push('/workouts/create'),
            icon: const Icon(Icons.add),
            label: const Text('Crea Scheda'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.indigo600,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: AppConfig.spacingL.w,
                vertical: AppConfig.spacingM.h,
              ),
            ),
          ),
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
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.error,
            ),
          ),
          SizedBox(height: AppConfig.spacingS.h),
          Text(
            state.message,
            style: TextStyle(
              fontSize: 16.sp,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppConfig.spacingXL.h),
          ElevatedButton(
            onPressed: _loadWorkoutPlans,
            child: const Text('Riprova'),
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
          CircularProgressIndicator(
            color: AppColors.indigo600,
          ),
          SizedBox(height: AppConfig.spacingL.h),
          Text(
            'Caricamento schede...',
            style: TextStyle(
              fontSize: 16.sp,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // AZIONI SCHEDE
  // ============================================================================

  void _showWorkoutDetails(workoutPlan) {
    // Naviga ai dettagli della scheda
    context.push('/workouts/${workoutPlan.id}');
  }

  void _editWorkout(workoutPlan) {
    // Naviga alla modifica della scheda
    context.push('/workouts/edit/${workoutPlan.id}');
  }

  void _startWorkout(workoutPlan) {
    // Naviga all'allenamento attivo
    context.push('/workouts/${workoutPlan.id}/start');
  }

  // ✅ Implementazione cancellazione scheda
  Future<void> _deleteWorkout(int schedaId) async {
    try {
      _workoutBloc.deleteWorkout(schedaId);
    } catch (e) {
      CustomSnackbar.show(
        context,
        message: 'Errore nell\'eliminazione della scheda: $e',
        isSuccess: false,
      );
    }
  }
}