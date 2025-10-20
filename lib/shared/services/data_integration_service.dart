// lib/shared/services/data_integration_service.dart (VERSIONE COMPLETA)

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/workouts/bloc/workout_history_bloc.dart';
import '../../features/subscription/bloc/subscription_bloc.dart';

/// 🔧 FIX: Service completo per gestire l'integrazione con i dati reali
/// Risolve problemi di timing durante l'inizializzazione + mantiene funzionalità originali
class DataIntegrationService {

  // 🔧 FIX: Flag per tracciare inizializzazioni in corso
  static final Set<int> _initializingUsers = <int>{};

  /// Inizializza tutti i dati necessari per un utente autenticato
  static void initializeUserData(BuildContext context, int userId) {
    // 🔧 FIX: Evita inizializzazioni multiple simultanee
    if (_initializingUsers.contains(userId)) {
      print('[CONSOLE] [data_integration_service] ⚠️ Already initializing for user: $userId');
      return;
    }

    _initializingUsers.add(userId);
    //print('[CONSOLE] [data_integration_service] 🚀 Initializing data for user: $userId');

    try {
      // Carica subscription data
      _loadSubscriptionData(context);

      // 🔧 FIX: Carica workout history con delay minimo per stabilità
      Future.microtask(() {
        if (context.mounted) {
          _loadWorkoutHistory(context, userId);
          // 🔧 RIMOSSO: _loadUserStats che causa errore 404
          // _loadUserStats(context, userId);
        }
      });

      //print('[CONSOLE] [data_integration_service] ✅ Data initialization completed for user: $userId');
    } finally {
      // 🔧 FIX: Pulisci flag dopo delay per permettere retry se necessario
      Future.delayed(const Duration(seconds: 3), () {
        _initializingUsers.remove(userId);
      });
    }
  }

  /// Pulisce tutti i dati quando l'utente fa logout
  static void clearUserData(BuildContext context) {
    //print('[CONSOLE] [data_integration_service] 🧹 Clearing user data');

    // 🔧 FIX: Pulisci flag inizializzazioni
    _initializingUsers.clear();

    // Reset workout history
    if (context.mounted) {
      context.read<WorkoutHistoryBloc>().add(const ResetWorkoutHistoryState());
    }

    // 🧹 NUOVO: Reset subscription bloc per evitare cache contamination
    if (context.mounted) {
      try {
        context.read<SubscriptionBloc>().add(const ResetSubscriptionBlocEvent());
        //print('[CONSOLE] [data_integration_service] ✅ Subscription bloc reset');
      } catch (e) {
        print('[CONSOLE] [data_integration_service] ⚠️ Error resetting subscription bloc: $e');
      }
    }

    //print('[CONSOLE] [data_integration_service] ✅ User data cleared');
  }

  /// Ricarica tutti i dati (per pull-to-refresh)
  static Future<void> refreshAllData(BuildContext context) async {
    //print('[CONSOLE] [data_integration_service] 🔄 Refreshing all data');

    if (!context.mounted) return;

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
      if (context.mounted) {
        context.read<WorkoutHistoryBloc>().add(RefreshWorkoutHistory(userId: userId));
      }

      // Delay per UX
      await Future.delayed(const Duration(milliseconds: 500));

      //print('[CONSOLE] [data_integration_service] ✅ All data refreshed for user: $userId');
    }
  }

  /// 🔧 FIX: Verifica se i dati sono pronti per essere utilizzati
  static bool isDataReady(BuildContext context) {
    if (!context.mounted) return false;

    final authState = context.read<AuthBloc>().state;
    final subscriptionState = context.read<SubscriptionBloc>().state;
    final workoutHistoryState = context.read<WorkoutHistoryBloc>().state;

    final isAuthOk = (authState is AuthAuthenticated || authState is AuthLoginSuccess);
    final isSubscriptionOk = (subscriptionState is SubscriptionLoaded || subscriptionState is SubscriptionInitial);
    final isWorkoutOk = (workoutHistoryState is WorkoutHistoryLoaded ||
        workoutHistoryState is WorkoutHistoryInitial ||
        workoutHistoryState is WorkoutHistoryLoading);

    //print('[CONSOLE] [data_integration_service] 🔍 Data ready check: Auth=$isAuthOk, Sub=$isSubscriptionOk, Workout=$isWorkoutOk');

    return isAuthOk && isSubscriptionOk && isWorkoutOk;
  }

  /// 🔧 FIX: Calcola dati aggregati per la dashboard con gestione errori
  static DashboardData calculateDashboardData(BuildContext context) {
    if (!context.mounted) {
      return _getDefaultDashboardData();
    }

    try {
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
      DateTime? lastWorkout;

      if (workoutHistoryState is WorkoutHistoryLoaded) {
        totalWorkouts = workoutHistoryState.workoutHistory.length;
        if (workoutHistoryState.workoutHistory.isNotEmpty) {
          lastWorkout = DateTime.tryParse(workoutHistoryState.workoutHistory.first.dataAllenamento ?? '');
        }
      }

      return DashboardData(
        userName: userName,
        hasPremium: hasPremium,
        workoutCount: workoutCount,
        maxWorkouts: maxWorkouts,
        totalWorkouts: totalWorkouts,
        lastWorkoutDate: lastWorkout,
      );
    } catch (e) {
      print('[CONSOLE] [data_integration_service] ❌ Error calculating dashboard data: $e');
      return _getDefaultDashboardData();
    }
  }

  // ============================================================================
  // 🔧 FIX: METODI PRIVATI MIGLIORATI
  // ============================================================================

  static void _loadSubscriptionData(BuildContext context) {
    if (context.mounted) {
      //print('[CONSOLE] [data_integration_service] 📋 Loading subscription data');
      context.read<SubscriptionBloc>().add(
        const LoadSubscriptionEvent(checkExpired: true),
      );
    }
  }

  static void _loadWorkoutHistory(BuildContext context, int userId) {
    if (context.mounted) {
      //print('[CONSOLE] [data_integration_service] 📊 Loading workout history for userId: $userId');
      context.read<WorkoutHistoryBloc>().add(
        GetWorkoutHistory(userId: userId),
      );
    }
  }

  static void _loadUserStats(BuildContext context, int userId) {
    if (context.mounted) {
      //print('[CONSOLE] [data_integration_service] 📈 Loading user stats for userId: $userId');
      context.read<WorkoutHistoryBloc>().add(
        GetUserStats(userId: userId),
      );
    }
  }

  static DashboardData _getDefaultDashboardData() {
    return const DashboardData(
      userName: 'Utente',
      hasPremium: false,
      workoutCount: 0,
      maxWorkouts: 3,
      totalWorkouts: 0,
      lastWorkoutDate: null,
    );
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
      DateTime? lastWorkoutDate;

      for (final workout in sortedWorkouts) {
        final workoutDate = DateTime.tryParse(workout.dataAllenamento);
        if (workoutDate == null) continue;

        if (lastWorkoutDate == null) {
          lastWorkoutDate = workoutDate;
          streak = 1;
        } else {
          final daysDifference = lastWorkoutDate.difference(workoutDate).inDays;
          if (daysDifference <= 2) { // Massimo 1 giorno di pausa
            streak++;
            lastWorkoutDate = workoutDate;
          } else {
            break;
          }
        }
      }

      return streak;
    }
    return 0;
  }

  /// Calcola minuti totali di allenamento
  static int getTotalWorkoutMinutes(BuildContext context) {
    final workoutHistoryState = context.read<WorkoutHistoryBloc>().state;

    if (workoutHistoryState is WorkoutHistoryLoaded) {
      final workouts = workoutHistoryState.workoutHistory;

      // Stima: ogni allenamento dura circa 45-60 minuti
      // TODO: Quando avremo i dati reali di durata, sostituire questo calcolo
      return workouts.length * 50; // 50 minuti per allenamento
    }
    return 0;
  }
}

// ============================================================================
// 🔧 FIX: CLASSE DATI DASHBOARD COMPLETA
// ============================================================================

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

  @override
  String toString() {
    return 'DashboardData(userName: $userName, hasPremium: $hasPremium, '
        'workoutCount: $workoutCount, totalWorkouts: $totalWorkouts, '
        'usagePercentage: ${(usagePercentage * 100).toStringAsFixed(1)}%)';
  }
}

// ============================================================================
// MIXIN PER WIDGET CHE DEVONO REAGIRE AI CAMBIAMENTI DEI DATI
// ============================================================================

/// Mixin per widget che devono reagire ai cambiamenti dei dati
mixin DataIntegrationMixin<T extends StatefulWidget> on State<T> {

  /// Ascolta i cambiamenti dei dati e aggiorna l'UI
  void listenToDataChanges() {
    // Listener per auth changes
    context.read<AuthBloc>().stream.listen((authState) {
      if (authState is AuthAuthenticated) {
        DataIntegrationService.initializeUserData(context, authState.user.id);
      } else if (authState is AuthLoginSuccess) {
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