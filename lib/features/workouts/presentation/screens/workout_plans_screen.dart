// lib/features/workouts/presentation/screens/workout_plans_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/dependency_injection.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/custom_snackbar.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../core/services/session_service.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../bloc/workout_bloc.dart';
import '../../models/workout_plan_models.dart';
import '../widgets/workout_plan_card.dart';

class WorkoutPlansScreen extends StatefulWidget {
  const WorkoutPlansScreen({super.key});

  @override
  State<WorkoutPlansScreen> createState() => _WorkoutPlansScreenState();
}

class _WorkoutPlansScreenState extends State<WorkoutPlansScreen> {
  late final WorkoutBloc _workoutBloc;
  late final SessionService _sessionService;

  int? _currentUserId;
  bool _isLoadingUserId = true;

  @override
  void initState() {
    super.initState();
    _workoutBloc = getIt<WorkoutBloc>();
    _sessionService = getIt<SessionService>();
    _initializeUserId();
  }

  Future<void> _initializeUserId() async {
    try {
      // Prima prova a recuperare da SessionService
      final userId = await _sessionService.getCurrentUserId();

      if (userId != null) {
        setState(() {
          _currentUserId = userId;
          _isLoadingUserId = false;
        });
        _loadWorkoutPlans();
      } else {
        // Se non c'è in SessionService, prova dall'AuthBloc
        final authState = context.read<AuthBloc>().state;
        if (authState is AuthAuthenticated) {
          setState(() {
            _currentUserId = authState.user.id;
            _isLoadingUserId = false;
          });
          _loadWorkoutPlans();
        } else if (authState is AuthLoginSuccess) {
          setState(() {
            _currentUserId = authState.user.id;
            _isLoadingUserId = false;
          });
          _loadWorkoutPlans();
        } else {
          // Utente non autenticato
          setState(() {
            _isLoadingUserId = false;
          });
          // Reindirizza al login
          if (mounted) {
            context.go('/login');
          }
        }
      }
    } catch (e) {
      setState(() {
        _isLoadingUserId = false;
      });
      if (mounted) {
        CustomSnackbar.show(
          context,
          message: 'Errore nel recupero dati utente',
          isSuccess: false,
        );
      }
    }
  }

  void _loadWorkoutPlans() {
    if (_currentUserId != null) {
      _workoutBloc.loadWorkoutPlans(_currentUserId!);
    }
  }

  @override
  void dispose() {
    _workoutBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _workoutBloc,
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Le Mie Schede',
          showBackButton: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadWorkoutPlans,
              tooltip: 'Aggiorna',
            ),
          ],
        ),
        body: _isLoadingUserId
            ? const Center(child: CircularProgressIndicator())
            : _currentUserId == null
            ? const Center(
          child: Text('Errore: utente non autenticato'),
        )
            : BlocConsumer<WorkoutBloc, WorkoutState>(
          listener: (context, state) {
            if (state is WorkoutError) {
              CustomSnackbar.show(
                context,
                message: state.message,
                isSuccess: false,
              );
            } else if (state is WorkoutPlanDeleted) {
              CustomSnackbar.show(
                context,
                message: state.message,
                isSuccess: true,
              );
              // Ricarica la lista dopo eliminazione
              _loadWorkoutPlans();
            }
          },
          builder: (context, state) {
            return LoadingOverlay(
              isLoading: state is WorkoutLoading,
              message: state is WorkoutLoadingWithMessage ? state.message : null,
              child: _buildBody(context, state),
            );
          },
        ),
        floatingActionButton: _currentUserId != null
            ? FloatingActionButton.extended(
          onPressed: () => _navigateToCreateWorkout(),
          backgroundColor: AppColors.indigo600,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('Nuova Scheda'),
        )
            : null,
      ),
    );
  }

  Widget _buildBody(BuildContext context, WorkoutState state) {
    if (state is WorkoutError) {
      return ErrorState(
        message: state.message,
        onRetry: _loadWorkoutPlans,
      );
    }

    if (state is WorkoutPlansLoaded) {
      if (state.workoutPlans.isEmpty) {
        return EmptyState(
          icon: Icons.fitness_center,
          title: 'Nessuna Scheda',
          description: 'Non hai ancora creato nessuna scheda di allenamento.\nTocca il pulsante + per iniziare!',
          buttonText: 'Crea Prima Scheda',
          onButtonPressed: _navigateToCreateWorkout,
        );
      }

      return RefreshIndicator(
        onRefresh: () async => _loadWorkoutPlans(),
        child: ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: state.workoutPlans.length,
          itemBuilder: (context, index) {
            final workoutPlan = state.workoutPlans[index];
            return Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: WorkoutPlanCard(
                workoutPlan: workoutPlan,
                onTap: () => _navigateToWorkoutDetail(workoutPlan),
                onEdit: () => _navigateToEditWorkout(workoutPlan),
                onDelete: () => _showDeleteConfirmation(workoutPlan),
                onStartWorkout: () => _startWorkout(workoutPlan),
              ),
            );
          },
        ),
      );
    }

    // Loading state o initial state
    if (state is WorkoutInitial) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Fallback
    return const SizedBox.shrink();
  }

  void _navigateToCreateWorkout() {
    context.push('/workouts/create');
  }

  void _navigateToEditWorkout(WorkoutPlan workoutPlan) {
    context.push('/workouts/edit/${workoutPlan.id}');
  }

  void _navigateToWorkoutDetail(WorkoutPlan workoutPlan) {
    context.push('/workouts/${workoutPlan.id}');
  }

  void _startWorkout(WorkoutPlan workoutPlan) {
    context.push('/workouts/${workoutPlan.id}/start');
  }

  void _showDeleteConfirmation(WorkoutPlan workoutPlan) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Elimina Scheda'),
          content: Text(
            'Sei sicuro di voler eliminare la scheda "${workoutPlan.nome}"?\n\nQuesta azione non può essere annullata.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annulla'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _workoutBloc.deleteWorkout(workoutPlan.id);
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
              ),
              child: const Text('Elimina'),
            ),
          ],
        );
      },
    );
  }
}