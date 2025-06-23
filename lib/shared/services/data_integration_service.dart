// lib/shared/services/data_integration_service.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/models/login_response.dart'; // Per AuthLoginSuccess
import '../../features/workouts/bloc/workout_history_bloc.dart';
import '../../features/subscription/bloc/subscription_bloc.dart';

/// Service per gestire l'integrazione con i dati reali
/// Prepara l'app per usare BLoC invece di dati mock
class DataIntegrationService {

  /// Inizializza tutti i dati necessari per un utente autenticato
  static void initializeUserData(BuildContext context, int userId) {
    print('[CONSOLE] [data_integration_service] 🚀 Initializing data for user: $userId');

    // Carica subscription data
    _loadSubscriptionData(context);

    // Carica workout history
    _loadWorkoutHistory(context, userId);

    // Carica user stats
    _loadUserStats(context, userId);

    print('[CONSOLE] [data_integration_service] ✅ Data initialization completed');
  }

  /// Pulisce tutti i dati quando l'utente fa logout
  static void clearUserData(BuildContext context) {
    print('[CONSOLE] [data_integration_service] 🧹 Clearing user data');

    // Reset workout history
    context.read<WorkoutHistoryBloc>().add(const ResetWorkoutHistoryState());

    // Altri reset se necessari...

    print('[CONSOLE] [data_integration_service] ✅ User data cleared');
  }

  /// Ricarica tutti i dati (per pull-to-refresh)
  static Future<void> refreshAllData(BuildContext context) async {
    print('[CONSOLE] [data_integration_service] 🔄 Refreshing all data');

    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated || authState is AuthLoginSuccess) {
      int userId;
      if (authState is AuthAuthenticated) {
        userId = authState.user.id;
      } else {
        userId = (authState as AuthLoginSuccess).user.id;
      }

      // Refresh subscription
      _loadSubscriptionData(context);

      // Refresh workout data
      context.read<WorkoutHistoryBloc>().add(RefreshWorkoutHistory(userId: userId));

      // Delay per UX
      await Future.delayed(const Duration(milliseconds: 500));

      print('[CONSOLE] [data_integration_service] ✅ All data refreshed');
    }
  }

  /// Verifica se i dati sono pronti per essere utilizzati
  static bool isDataReady(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final subscriptionState = context.read<SubscriptionBloc>().state;
    final workoutHistoryState = context.read<WorkoutHistoryBloc>().state;

    return (authState is AuthAuthenticated || authState is AuthLoginSuccess) &&
        subscriptionState is SubscriptionLoaded &&
        (workoutHistoryState is WorkoutHistoryLoaded ||
            workoutHistoryState is WorkoutHistoryInitial);
  }

  /// Calcola dati aggregati per la dashboard
  static DashboardData calculateDashboardData(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final subscriptionState = context.read<SubscriptionBloc>().state;
    final workoutHistoryState = context.read<WorkoutHistoryBloc>().state;

    // Dati utente - FIX: Gestisci anche AuthLoginSuccess
    String userName = 'Utente';
    if (authState is AuthAuthenticated) {
      userName = authState.user.username.isNotEmpty
          ? authState.user.username
          : (authState.user.email?.split('@').first ?? 'Utente');
    } else if (authState is AuthLoginSuccess) {
      userName = authState.user.username.isNotEmpty
          ? authState.user.username
          : (authState.user.email?.split('@').first ?? 'Utente');
    }

    // Dati subscription
    bool hasPremium = false;
    int workoutCount = 0;
    int maxWorkouts = 3;

    if (subscriptionState is SubscriptionLoaded) {
      hasPremium = subscriptionState.subscription.isPremium;
      workoutCount = subscriptionState.subscription.currentCount;
      maxWorkouts = subscriptionState.subscription.maxWorkouts ?? 3;
    }

    // Dati workout history
    int totalWorkouts = 0;
    DateTime? lastWorkoutDate;

    if (workoutHistoryState is WorkoutHistoryLoaded) {
      totalWorkouts = workoutHistoryState.workoutHistory.length;
      if (workoutHistoryState.workoutHistory.isNotEmpty) {
        // Trova l'ultimo workout
        final sortedWorkouts = workoutHistoryState.workoutHistory
          ..sort((a, b) => b.dataAllenamento.compareTo(a.dataAllenamento));
        lastWorkoutDate = DateTime.tryParse(sortedWorkouts.first.dataAllenamento);
      }
    }

    return DashboardData(
      userName: userName,
      hasPremium: hasPremium,
      workoutCount: workoutCount,
      maxWorkouts: maxWorkouts,
      totalWorkouts: totalWorkouts,
      lastWorkoutDate: lastWorkoutDate,
    );
  }

  /// Calcola profile completeness basato sui dati reali
  static int calculateProfileCompleteness(BuildContext context) {
    // TODO: Integrare con il vero profilo utente quando sarà implementato
    // Per ora restituisce un valore simulato
    return 75;
  }

  /// Calcola streak di allenamenti
  static int calculateWorkoutStreak(BuildContext context) {
    final workoutHistoryState = context.read<WorkoutHistoryBloc>().state;

    if (workoutHistoryState is WorkoutHistoryLoaded) {
      final workouts = workoutHistoryState.workoutHistory;
      if (workouts.isEmpty) return 0;

      // Ordina per data decrescente
      final sortedWorkouts = workouts
        ..sort((a, b) => b.dataAllenamento.compareTo(a.dataAllenamento));

      int streak = 0;
      DateTime? lastDate;

      for (final workout in sortedWorkouts) {
        final workoutDate = DateTime.tryParse(workout.dataAllenamento);
        if (workoutDate == null) continue;

        if (lastDate == null) {
          // Primo workout
          lastDate = workoutDate;
          streak = 1;
        } else {
          // Controlla se è consecutivo (entro 2 giorni)
          final daysDifference = lastDate.difference(workoutDate).inDays;
          if (daysDifference <= 2) {
            streak++;
            lastDate = workoutDate;
          } else {
            break; // Streak interrotta
          }
        }
      }

      return streak;
    }

    return 0;
  }

  /// Ottiene il peso massimo sollevato
  static double getMaxWeight(BuildContext context) {
    // TODO: Integrare con i dati reali delle serie completate
    // Per ora restituisce un valore simulato
    return 120.0;
  }

  /// Calcola il tempo totale di allenamento
  static int getTotalWorkoutMinutes(BuildContext context) {
    final workoutHistoryState = context.read<WorkoutHistoryBloc>().state;

    if (workoutHistoryState is WorkoutHistoryLoaded) {
      return workoutHistoryState.workoutHistory
          .fold(0, (total, workout) => total + (workout.durataMinuti ?? 0));
    }

    return 0;
  }

  // ============================================================================
  // METODI PRIVATI
  // ============================================================================

  static void _loadSubscriptionData(BuildContext context) {
    context.read<SubscriptionBloc>().add(
      const LoadSubscriptionEvent(checkExpired: true),
    );
  }

  static void _loadWorkoutHistory(BuildContext context, int userId) {
    context.read<WorkoutHistoryBloc>().add(
      GetWorkoutHistory(userId: userId),
    );
  }

  static void _loadUserStats(BuildContext context, int userId) {
    context.read<WorkoutHistoryBloc>().add(
      GetUserStats(userId: userId),
    );
  }
}

/// Data class per i dati aggregati della dashboard
class DashboardData {
  final String userName;
  final bool hasPremium;
  final int workoutCount;
  final int maxWorkouts;
  final int totalWorkouts;
  final DateTime? lastWorkoutDate;

  const DashboardData({
    required this.userName,
    required this.hasPremium,
    required this.workoutCount,
    required this.maxWorkouts,
    required this.totalWorkouts,
    this.lastWorkoutDate,
  });

  /// Percentuale di utilizzo del piano gratuito
  double get usagePercentage => maxWorkouts > 0 ? workoutCount / maxWorkouts : 0.0;

  /// Indica se l'utente sta raggiungendo il limite
  bool get isNearLimit => usagePercentage >= 0.8;

  /// Messaggio di status dell'account
  String get statusMessage {
    if (hasPremium) {
      return 'Account Premium Attivo';
    } else if (isNearLimit) {
      return 'Limite quasi raggiunto';
    } else {
      return 'Account Gratuito';
    }
  }

  /// Formattazione dell'ultima data di allenamento
  String get lastWorkoutFormatted {
    if (lastWorkoutDate == null) return 'Nessun allenamento';

    final now = DateTime.now();
    final difference = now.difference(lastWorkoutDate!);

    if (difference.inDays == 0) {
      return 'Oggi';
    } else if (difference.inDays == 1) {
      return 'Ieri';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} giorni fa';
    } else {
      return '${(difference.inDays / 7).floor()} settiman${difference.inDays >= 14 ? 'e' : 'a'} fa';
    }
  }
}

/// Mixin per widget che devono reagire ai cambiamenti dei dati
mixin DataIntegrationMixin<T extends StatefulWidget> on State<T> {

  /// Ascolta i cambiamenti dei dati e aggiorna l'UI
  void listenToDataChanges() {
    // Listener per auth changes
    context.read<AuthBloc>().stream.listen((authState) {
      if (authState is AuthAuthenticated) {
        DataIntegrationService.initializeUserData(context, authState.user.id);
      } else if (authState is AuthUnauthenticated) {
        DataIntegrationService.clearUserData(context);
      }
    });
  }

  /// Verifica se i dati sono pronti
  bool get isDataReady => DataIntegrationService.isDataReady(context);

  /// Ottiene i dati aggregati della dashboard
  DashboardData get dashboardData => DataIntegrationService.calculateDashboardData(context);

  /// Ricarica tutti i dati
  Future<void> refreshData() => DataIntegrationService.refreshAllData(context);
}