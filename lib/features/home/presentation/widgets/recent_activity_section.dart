// lib/features/home/presentation/widgets/recent_activity_section.dart (FIX)

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/loading_shimmer_widgets.dart';
import '../../../../shared/widgets/error_handling_widgets.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../workouts/bloc/workout_history_bloc.dart';

/// 🔧 FIX: Sezione attività recente con gestione migliorata degli errori
class RecentActivitySection extends StatefulWidget {
  const RecentActivitySection({super.key});

  @override
  State<RecentActivitySection> createState() => _RecentActivitySectionState();
}

class _RecentActivitySectionState extends State<RecentActivitySection> {
  // 🔧 FIX: Flag per evitare retry multipli
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    // 🔧 FIX: Verifica e carica dati se necessario dopo il build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndLoadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Attività Recente',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.go('/workouts/history'),
                child: Text(
                  'Vedi tutto',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.indigo600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),

        // 🔧 FIX: BlocBuilder migliorato con gestione stati
        BlocBuilder<WorkoutHistoryBloc, WorkoutHistoryState>(
          builder: (context, state) {
            return _buildStateHandler(state, context);
          },
        ),
      ],
    );
  }

  // ============================================================================
  // 🔧 FIX: GESTIONE STATI MIGLIORATA
  // ============================================================================

  Widget _buildStateHandler(WorkoutHistoryState state, BuildContext context) {
    //debugPrint('[CONSOLE] [recent_activity]🔍 Current state: ${state.runtimeType}');

    // 🔧 FIX: Gestione stato Loading
    if (state is WorkoutHistoryLoading) {
      return _buildLoadingState();
    }

    // 🔧 FIX: Gestione stato Success
    if (state is WorkoutHistoryLoaded) {
      return _buildSuccessState(state);
    }

    // 🔧 FIX: Gestione stato Error migliorata
    if (state is WorkoutHistoryError) {
      return _buildErrorState(state, context);
    }

    // 🔧 FIX: Gestione stato Initial - Tenta caricamento se auth è ok
    if (state is WorkoutHistoryInitial) {
      return _buildInitialState(context);
    }

    // Fallback per stati non gestiti
    return _buildUnknownState();
  }

  // ============================================================================
  // 🔧 FIX: METODI DI BUILD PER OGNI STATO
  // ============================================================================

  Widget _buildLoadingState() {
    return Container(
      height: 120.h,
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      child: const ShimmerRecentActivity(),
    );
  }

  Widget _buildSuccessState(WorkoutHistoryLoaded state) {
    if (state.workoutHistory.isEmpty) {
      return _buildEmptyState();
    }

    // Mostra gli ultimi 3 allenamenti
    final recentWorkouts = state.workoutHistory.take(3).toList();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        children: recentWorkouts.map((workout) =>
            _buildWorkoutCard(workout)).toList(),
      ),
    );
  }

  Widget _buildErrorState(WorkoutHistoryError state, BuildContext context) {
    //debugPrint('[CONSOLE] [recent_activity]❌ Error state: ${state.message}');

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 32.sp,
          ),
          SizedBox(height: 8.h),
          Text(
            NetworkErrorHandler.getReadableMessage(state.exception ?? state.message),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.red[700],
            ),
          ),
          SizedBox(height: 12.h),
          // 🔧 FIX: Pulsante riprova migliorato
          ElevatedButton(
            onPressed: _isRetrying ? null : () => _retryLoadWorkouts(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: _isRetrying
                ? SizedBox(
              width: 16.w,
              height: 16.h,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : const Text('Riprova'),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialState(BuildContext context) {
    // 🔧 FIX: Controlla se l'utente è autenticato prima di mostrare errore
    final authState = context.read<AuthBloc>().state;

    if (authState is AuthAuthenticated || authState is AuthLoginSuccess) {
      // L'utente è autenticato ma i dati non sono ancora caricati
      // Mostra loading invece di errore
      return _buildLoadingState();
    }

    // Se non è autenticato, mostra un messaggio appropriato
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(16.w),
      child: Text(
        'Accedi per visualizzare la tua attività recente',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14.sp,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          Icon(
            Icons.fitness_center_outlined,
            size: 48.sp,
            color: Colors.grey[400],
          ),
          SizedBox(height: 12.h),
          Text(
            'Nessun allenamento ancora',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Inizia il tuo primo workout!',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnknownState() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(16.w),
      child: Text(
        'Stato sconosciuto. Riapri la schermata.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14.sp,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  // ============================================================================
  // 🔧 FIX: METODI DI SUPPORTO MIGLIORATI
  // ============================================================================

  /// Controlla e carica dati se necessario
  void _checkAndLoadData() {
    final authState = context.read<AuthBloc>().state;
    final workoutState = context.read<WorkoutHistoryBloc>().state;

    // 🔧 FIX: Carica dati solo se autenticato e dati non già caricati/in caricamento
    if ((authState is AuthAuthenticated || authState is AuthLoginSuccess) &&
        workoutState is WorkoutHistoryInitial) {
      _retryLoadWorkouts(context);
    }
  }

  /// 🔧 FIX: Metodo retry migliorato con protezione da retry multipli
  void _retryLoadWorkouts(BuildContext context) {
    if (_isRetrying) {
      return;
    }

    setState(() {
      _isRetrying = true;
    });

    final authBloc = context.read<AuthBloc>();
    final authState = authBloc.state;

    if (authState is AuthAuthenticated) {
      final userId = authState.user.id;
      context.read<WorkoutHistoryBloc>().add(GetWorkoutHistory(userId: userId));
    } else if (authState is AuthLoginSuccess) {
      final userId = authState.user.id;
      context.read<WorkoutHistoryBloc>().add(GetWorkoutHistory(userId: userId));
    } else {
      // Prova a verificare lo stato auth
      authBloc.add(const AuthStatusChecked());
    }

    // Reset retry flag dopo delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isRetrying = false;
        });
      }
    });
  }

  /// Build della card singolo workout
  Widget _buildWorkoutCard(dynamic workout) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8.r),
          onTap: () => _navigateToWorkoutDetails(workout),
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Row(
              children: [
                Icon(
                  Icons.fitness_center,
                  color: AppColors.indigo600,
                  size: 20.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workout.schedaNome ?? 'Allenamento',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _formatDate(workout.dataAllenamento),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14.sp,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Naviga ai dettagli dell'allenamento
  void _navigateToWorkoutDetails(dynamic workout) {
    context.go('/workouts/details/${workout.id}');
  }

  /// Formatta la data in formato user-friendly
  String _formatDate(dynamic date) {
    try {
      DateTime dateTime;
      if (date is String) {
        dateTime = DateTime.parse(date);
      } else if (date is DateTime) {
        dateTime = date;
      } else {
        return 'Data non disponibile';
      }

      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 0) {
        return '${difference.inDays} giorn${difference.inDays == 1 ? 'o' : 'i'} fa';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} or${difference.inHours == 1 ? 'a' : 'e'} fa';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minut${difference.inMinutes == 1 ? 'o' : 'i'} fa';
      } else {
        return 'Adesso';
      }
    } catch (e) {
      return 'Data non valida';
    }
  }
}