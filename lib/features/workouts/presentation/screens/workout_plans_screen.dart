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
import '../../../../core/services/user_role_service.dart';
import '../../../../core/di/dependency_injection.dart';

import '../../bloc/workout_bloc.dart';
import '../widgets/workout_widgets.dart';
import '../../../auth/bloc/auth_bloc.dart';

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

class _WorkoutPlansScreenState extends State<WorkoutPlansScreen>
    with RouteAware {
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

    // 🔧 FIX: Forza il caricamento immediato quando si torna da un allenamento
    _loadWorkoutPlans();
    
    // 🚀 FIX: NON caricare automaticamente i workout qui!
    //print('[CONSOLE] [workout_plans_screen]🔧 WorkoutPlansScreen initialized - NOT loading data yet');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final routeObserver = getIt<RouteObserver<ModalRoute<void>>>();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
    // NON forzare il refresh qui!
    // _hasLoadedData = false;
    // _isTabVisible = true;
    // _loadWorkoutPlans();
  }

  @override
  void dispose() {
    // 🚀 NUOVO: Scollega il controller
    widget.controller?._detachState();
    // Deregistra dal RouteObserver
    final routeObserver = getIt<RouteObserver<ModalRoute<void>>>();
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // Quando si torna su questa schermata, forza il reload delle schede
    _loadWorkoutPlans();
    super.didPopNext();
  }

  /// 🚀 METODI PRIVATI chiamati dal controller
  void _onTabVisible() {
    //print('[CONSOLE] [workout_plans_screen]👁️ Tab became visible - isTabVisible: $_isTabVisible, hasLoadedData: $_hasLoadedData');

    if (!_isTabVisible) {
      _isTabVisible = true;

      // Carica i dati solo la prima volta che la tab diventa visibile
      if (!_hasLoadedData) {
        //print('[CONSOLE] [workout_plans_screen]🚀 First time tab is visible - loading workout plans now!');
        _loadWorkoutPlans();
        _hasLoadedData = true;
      }
    }
  }

  void _onTabHidden() {
    //print('[CONSOLE] [workout_plans_screen]👁️ Tab became hidden');
    _isTabVisible = false;
  }

  void _forceReload() {
    //print('[CONSOLE] [workout_plans_screen]🔄 Force reload requested');

    if (_isTabVisible) {
      _loadWorkoutPlans();
    } else {
      // Se non è visibile, resetta il flag per ricaricare quando diventerà visibile
      _hasLoadedData = false;
    }
  }

  /// 🚀 NUOVO: Metodo pubblico chiamato dal parent quando la tab diventa visibile
  void onTabVisible() {
    //print('[CONSOLE] [workout_plans_screen]👁️ Tab became visible - isTabVisible: $_isTabVisible, hasLoadedData: $_hasLoadedData');

    if (!_isTabVisible) {
      _isTabVisible = true;

      // Carica i dati solo la prima volta che la tab diventa visibile
      if (!_hasLoadedData) {
        //print('[CONSOLE] [workout_plans_screen]🚀 First time tab is visible - loading workout plans now!');
        _loadWorkoutPlans();
        _hasLoadedData = true;
      }
    }
  }

  /// 🚀 NUOVO: Metodo pubblico chiamato dal parent quando la tab diventa nascosta
  void onTabHidden() {
    //print('[CONSOLE] [workout_plans_screen]👁️ Tab became hidden');
    _isTabVisible = false;
  }

  /// 🔧 FIX: Metodo di caricamento ora privato e chiamato solo quando necessario
  Future<void> _loadWorkoutPlans() async {
    //print('[CONSOLE] [workout_plans_screen]📊 Loading workout plans...');
    
    final userId = await _sessionService.getCurrentUserId();
    if (userId != null) {
      _workoutBloc.loadWorkoutPlans(userId);
    } else {
      //print('[CONSOLE] [workout_plans_screen]❌ No user ID found - cannot load workout plans');
    }
  }

  Future<void> _refreshWorkoutPlans() async {
    //print('[CONSOLE] [workout_plans_screen]🔄 Refreshing workout plans...');

    final userId = await _sessionService.getCurrentUserId();
    if (userId != null) {
      _workoutBloc.refreshWorkoutPlans(userId);
    }
  }

  /// 🚀 NUOVO: Metodo pubblico per forzare il reload (utile per quando si torna da altre schermate)
  void forceReload() {
    //print('[CONSOLE] [workout_plans_screen]🔄 Force reload requested');

    if (_isTabVisible) {
      _loadWorkoutPlans();
    } else {
      // Se non è visibile, resetta il flag per ricaricare quando diventerà visibile
      _hasLoadedData = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final currentUser = authState is AuthAuthenticated 
            ? authState.user 
            : authState is AuthLoginSuccess 
                ? authState.user 
                : null;
        final canManageSchede = UserRoleService.canManageWorkoutSchemes(currentUser);
        
        // 🔍 DEBUG: Log per verificare i permessi
        //print('[CONSOLE] [Permessi]🔍 DEBUG PERMESSI:');
        //print('[CONSOLE] [Permessi]- User ID: ${currentUser?.id}');
        //print('[CONSOLE] [Permessi] - Role ID: ${currentUser?.roleId}');
        //print('[CONSOLE] [Permessi] - isStandaloneUser: ${UserRoleService.isStandaloneUser(currentUser)}');
        //print('[CONSOLE] [Permessi] - isGymUser: ${UserRoleService.isGymUser(currentUser)}');
        //print('[CONSOLE] [Permessi] - canManageWorkoutSchemes: $canManageSchede');
        
        return Scaffold(
          appBar: CustomAppBar(
            title: 'Mie Schede',
            actions: canManageSchede ? [
              IconButton(
                icon: const Icon(Icons.fitness_center_rounded),
                onPressed: () => context.push('/templates'),
                tooltip: 'Template Schede',
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => context.push('/workouts/create'),
                tooltip: 'Crea Scheda',
              ),
            ] : null,
          ),
          body: BlocConsumer<WorkoutBloc, WorkoutState>(
        listener: (context, state) {
          if (state is WorkoutPlansLoaded) {
            // 🔧 FIX: Aggiorna i flag quando i dati vengono caricati
            _hasLoadedData = true;
            _isTabVisible = true;
          }
          
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
            isLoading:
                state is WorkoutLoading || state is WorkoutLoadingWithMessage,
            message: state is WorkoutLoadingWithMessage ? state.message : null,
            child: RefreshIndicator(
              onRefresh: _refreshWorkoutPlans,
              child: _buildContent(state, canManageSchede),
            ),
          );
        },
      ),
        );
      },
    );
  }

  Widget _buildContent(WorkoutState state, bool canManageSchede) {
    // 🚀 NUOVO: Se non abbiamo ancora caricato i dati e la tab non è visibile, mostra loading
    if (!_hasLoadedData && !_isTabVisible) {
      return _buildInitialState();
    }

    if (state is WorkoutPlansLoaded) {
      return _buildWorkoutPlansList(state, canManageSchede);
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

  Widget _buildWorkoutPlansList(WorkoutPlansLoaded state, bool canManageSchede) {
    if (state.workoutPlans.isEmpty) {
      return _buildEmptyPlansState(canManageSchede);
    }

    return ListView.builder(
      padding: EdgeInsets.all(AppConfig.spacingM.w),
      itemCount: state.workoutPlans.length,
      itemBuilder: (context, index) {
        final workoutPlan = state.workoutPlans[index];

        return WorkoutPlanCard(
          workoutPlan: workoutPlan,
          parentContext: context,
          canManageSchede: canManageSchede,
          onTap: () {
            Future.microtask(() => _showWorkoutDetails(workoutPlan));
          },
          onEdit: canManageSchede ? () {
            Future.microtask(
                () => context.push('/workouts/edit/${workoutPlan.id}'));
          } : null,
          onDelete: canManageSchede ? () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Elimina Scheda'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'Sei sicuro di voler eliminare la scheda "${workoutPlan.nome}"?'),
                    SizedBox(height: AppConfig.spacingM.h),
                    Container(
                      padding: EdgeInsets.all(AppConfig.spacingS.w),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppConfig.radiusS.r),
                        border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning,
                            color: AppColors.error,
                            size: 16.sp,
                          ),
                          SizedBox(width: AppConfig.spacingS.w),
                          Expanded(
                            child: Text(
                              'Questa azione non può essere annullata.',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppColors.error,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Annulla'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Elimina'),
                  ),
                ],
              ),
            );
            if (confirmed == true) {
              _deleteWorkout(workoutPlan.id);
            }
          } : null,
          onStartWorkout: () {
            Future.microtask(() => _startWorkout(workoutPlan));
          },
        );
      },
    );
  }

  Widget _buildEmptyPlansState(bool canManageSchede) {
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
          // Pulsanti per creare schede (solo per utenti standalone)
          if (canManageSchede)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
                SizedBox(width: AppConfig.spacingM.w),
                ElevatedButton.icon(
                  onPressed: () => context.push('/templates'),
                  icon: const Icon(Icons.fitness_center_rounded),
                  label: const Text('Template Schede'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple600,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: AppConfig.spacingL.w,
                      vertical: AppConfig.spacingM.h,
                    ),
                  ),
                ),
              ],
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
    context.push('/workouts/plan/${workoutPlan.id}?name=${Uri.encodeComponent(workoutPlan.nome)}');
  }

  void _startWorkout(workoutPlan) {
    context.push('/workouts/${workoutPlan.id}/start');
  }

  void _deleteWorkout(int schedaId) {
    _workoutBloc.deleteWorkout(schedaId);
  }
}
