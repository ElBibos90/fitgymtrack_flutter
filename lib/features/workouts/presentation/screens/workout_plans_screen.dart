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
import '../../models/workout_plan_models.dart';
import '../widgets/workout_widgets.dart';

/// 🚀 NUOVO: Interfaccia per tab con lazy loading
abstract class LazyLoadableTab {
  void onTabVisible();
  void onTabHidden();
  void forceReload();
}

/// 🚀 NUOVO: Controller per gestire lazy loading
class WorkoutTabController implements LazyLoadableTab {
  _WorkoutPlansScreenState? _state;

  void _attachState(_WorkoutPlansScreenState state) {
    _state = state;
  }

  void _detachState() {
    _state = null;
  }

  @override
  void onTabVisible() {
    _state?._onTabVisible();
  }

  @override
  void onTabHidden() {
    _state?._onTabHidden();
  }

  @override
  void forceReload() {
    _state?._forceReload();
  }
}

class WorkoutPlansScreen extends StatefulWidget {
  final WorkoutTabController? controller;

  const WorkoutPlansScreen({super.key, this.controller});

  @override
  State<WorkoutPlansScreen> createState() => _WorkoutPlansScreenState();
}

class _WorkoutPlansScreenState extends State<WorkoutPlansScreen> {
  late WorkoutBloc _workoutBloc;
  late SessionService _sessionService;

  // 🚀 LAZY LOADING: Flag per sapere se abbiamo già caricato i dati
  bool _hasLoadedData = false;
  bool _isTabVisible = false;

  @override
  void initState() {
    super.initState();
    _workoutBloc = context.read<WorkoutBloc>();
    _sessionService = getIt<SessionService>();

    // 🚀 NUOVO: Collega il controller allo state
    widget.controller?._attachState(this);

    // 🚀 FIX: NON caricare automaticamente i workout qui!
    print('[CONSOLE] [workout_plans_screen]🔧 WorkoutPlansScreen initialized - NOT loading data yet');
  }

  @override
  void dispose() {
    // 🚀 NUOVO: Scollega il controller
    widget.controller?._detachState();
    super.dispose();
  }

  /// 🚀 METODI PRIVATI chiamati dal controller
  void _onTabVisible() {
    print('[CONSOLE] [workout_plans_screen]👁️ Tab became visible - isTabVisible: $_isTabVisible, hasLoadedData: $_hasLoadedData');

    if (!_isTabVisible) {
      _isTabVisible = true;

      // Carica i dati solo la prima volta che la tab diventa visibile
      if (!_hasLoadedData) {
        print('[CONSOLE] [workout_plans_screen]🚀 First time tab is visible - loading workout plans now!');
        _loadWorkoutPlans();
        _hasLoadedData = true;
      }
    }
  }

  void _onTabHidden() {
    print('[CONSOLE] [workout_plans_screen]👁️ Tab became hidden');
    _isTabVisible = false;
  }

  void _forceReload() {
    print('[CONSOLE] [workout_plans_screen]🔄 Force reload requested');

    if (_isTabVisible) {
      _loadWorkoutPlans();
    } else {
      // Se non è visibile, resetta il flag per ricaricare quando diventerà visibile
      _hasLoadedData = false;
    }
  }

  /// 🚀 NUOVO: Metodo pubblico chiamato dal parent quando la tab diventa visibile
  void onTabVisible() {
    print('[CONSOLE] [workout_plans_screen]👁️ Tab became visible - isTabVisible: $_isTabVisible, hasLoadedData: $_hasLoadedData');

    if (!_isTabVisible) {
      _isTabVisible = true;

      // Carica i dati solo la prima volta che la tab diventa visibile
      if (!_hasLoadedData) {
        print('[CONSOLE] [workout_plans_screen]🚀 First time tab is visible - loading workout plans now!');
        _loadWorkoutPlans();
        _hasLoadedData = true;
      }
    }
  }

  /// 🚀 NUOVO: Metodo pubblico chiamato dal parent quando la tab diventa nascosta
  void onTabHidden() {
    print('[CONSOLE] [workout_plans_screen]👁️ Tab became hidden');
    _isTabVisible = false;
  }

  /// 🔧 FIX: Metodo di caricamento ora privato e chiamato solo quando necessario
  Future<void> _loadWorkoutPlans() async {
    print('[CONSOLE] [workout_plans_screen]📊 Loading workout plans...');

    final userId = await _sessionService.getCurrentUserId();
    if (userId != null) {
      _workoutBloc.loadWorkoutPlans(userId);
    } else {
      print('[CONSOLE] [workout_plans_screen]❌ No user ID found - cannot load workout plans');
    }
  }

  Future<void> _refreshWorkoutPlans() async {
    print('[CONSOLE] [workout_plans_screen]🔄 Refreshing workout plans...');

    final userId = await _sessionService.getCurrentUserId();
    if (userId != null) {
      _workoutBloc.refreshWorkoutPlans(userId);
    }
  }

  /// 🚀 NUOVO: Metodo pubblico per forzare il reload (utile per quando si torna da altre schermate)
  void forceReload() {
    print('[CONSOLE] [workout_plans_screen]🔄 Force reload requested');

    if (_isTabVisible) {
      _loadWorkoutPlans();
    } else {
      // Se non è visibile, resetta il flag per ricaricare quando diventerà visibile
      _hasLoadedData = false;
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
    // 🚀 NUOVO: Se non abbiamo ancora caricato i dati e la tab non è visibile, mostra loading
    if (!_hasLoadedData && !_isTabVisible) {
      return _buildInitialState();
    }

    if (state is WorkoutPlansLoaded) {
      return _buildWorkoutPlansList(state);
    } else if (state is WorkoutError) {
      return _buildErrorState(state);
    } else if (state is WorkoutInitial && !_hasLoadedData) {
      return _buildInitialState();
    }

    // Loading state
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  /// 🚀 NUOVO: Stato iniziale quando non abbiamo ancora caricato
  Widget _buildInitialState() {
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
            'Le tue schede di allenamento',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: AppConfig.spacingS.h),
          Text(
            'Seleziona questa tab per visualizzare le tue schede',
            style: TextStyle(
              fontSize: 16.sp,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (_isTabVisible && !_hasLoadedData) ...[
            SizedBox(height: AppConfig.spacingXL.h),
            CircularProgressIndicator(
              color: AppColors.indigo600,
            ),
            SizedBox(height: AppConfig.spacingM.h),
            Text(
              'Caricamento schede...',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
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
          onDelete: () => _deleteWorkout(workoutPlan.id),
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

  // ============================================================================
  // AZIONI SCHEDE (invariate)
  // ============================================================================

  void _showWorkoutDetails(workoutPlan) {
    context.push('/workouts/${workoutPlan.id}');
  }

  void _editWorkout(workoutPlan) {
    context.push('/workouts/edit/${workoutPlan.id}');
  }

  void _startWorkout(workoutPlan) {
    context.push('/workouts/${workoutPlan.id}/start');
  }

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