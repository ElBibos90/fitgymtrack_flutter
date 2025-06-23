// lib/features/home/services/dashboard_service.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/quick_action.dart';
import '../../tools/presentation/widgets/one_rep_max_dialog.dart';

/// Service per gestire la business logic della dashboard
class DashboardService {

  /// Configura le Quick Actions principali
  static List<QuickAction> getQuickActions(BuildContext context) {
    return [
      QuickAction(
        id: 'start_workout',
        icon: Icons.play_circle_fill_rounded,
        title: 'Inizia\nAllenamento',
        color: const Color(0xFF48BB78), // Verde
        onTap: () => _navigateToWorkouts(context),
      ),
      QuickAction(
        id: 'calculate_1rm',
        icon: Icons.calculate_rounded,
        title: 'Calcola\n1RM',
        color: const Color(0xFF667EEA), // Blu
        onTap: () => _showOneRepMaxDialog(context),
      ),
      QuickAction(
        id: 'achievements',
        icon: Icons.emoji_events_rounded,
        title: 'Achievement',
        color: const Color(0xFFED8936), // Arancione
        onTap: () => _navigateToAchievements(context),
      ),
      QuickAction(
        id: 'profile',
        icon: Icons.person_rounded,
        title: 'Profilo',
        color: const Color(0xFF9F7AEA), // Viola
        onTap: () => _navigateToProfile(context),
      ),
    ];
  }

  /// Quick Actions secondarie (future features)
  static List<QuickAction> getSecondaryActions(BuildContext context) {
    return [
      QuickAction(
        id: 'body_measurements',
        icon: Icons.straighten_rounded,
        title: 'Misure\nCorporee',
        color: const Color(0xFF38B2AC), // Teal
        onTap: () => _showComingSoonDialog(context, 'Misure Corporee'),
        isEnabled: false, // Future feature
      ),
      QuickAction(
        id: 'nutrition',
        icon: Icons.restaurant_rounded,
        title: 'Nutrizione',
        color: const Color(0xFF38A169), // Verde scuro
        onTap: () => _showComingSoonDialog(context, 'Nutrizione'),
        isEnabled: false, // Future feature
      ),
    ];
  }

  // ============================================================================
  // NAVIGATION HELPERS
  // ============================================================================

  /// Naviga alla tab Workouts usando GoRouter
  static void _navigateToWorkouts(BuildContext context) {
    // Per ora usa GoRouter, in futuro integreremo con bottom navigation
    context.go('/workouts');
  }

  /// Naviga alla schermata Achievements
  static void _navigateToAchievements(BuildContext context) {
    context.push('/achievements');
  }

  /// Naviga alla schermata Profilo
  static void _navigateToProfile(BuildContext context) {
    context.push('/profile');
  }

  // ============================================================================
  // DIALOG HELPERS
  // ============================================================================

  /// Mostra il dialog per calcolare 1RM
  static void _showOneRepMaxDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const OneRepMaxDialog(),
    );
  }

  /// Dialog placeholder per funzionalità future
  static void _showComingSoonDialog(BuildContext context, String featureName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$featureName'),
        content: Text('Funzionalità in arrivo!\n\nStiamo lavorando per portarti $featureName nel prossimo aggiornamento.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // GREETING HELPERS
  // ============================================================================

  /// Genera saluto personalizzato basato sull'ora
  static String getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 6) {
      return 'Nottambulo?';
    } else if (hour < 12) {
      return 'Buongiorno';
    } else if (hour < 18) {
      return 'Buon pomeriggio';
    } else if (hour < 22) {
      return 'Buonasera';
    } else {
      return 'Buonanotte';
    }
  }

  /// Genera messaggio motivazionale casuale
  static String getMotivationalMessage() {
    final messages = [
      'Oggi è il giorno perfetto per allenarsi! 💪',
      'Un passo alla volta verso i tuoi obiettivi! 🎯',
      'La costanza è la chiave del successo! 🔑',
      'Ogni allenamento ti rende più forte! 🏋️',
      'Inizia oggi, ringraziati domani! ⭐',
      'Il tuo corpo può farlo, convincere la mente! 🧠',
      'Non si tratta di essere perfetti, ma di migliorare! 📈',
      'L\'energia aumenta con l\'uso! ⚡',
    ];

    final randomIndex = DateTime.now().millisecond % messages.length;
    return messages[randomIndex];
  }

  // ============================================================================
  // UTILITIES
  // ============================================================================

  /// Formatta data per display UI
  static String formatLastWorkoutDate(DateTime? lastWorkout) {
    if (lastWorkout == null) return 'Nessun allenamento registrato';

    final now = DateTime.now();
    final difference = now.difference(lastWorkout);

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

  /// Calcola streak di allenamenti
  static int calculateWorkoutStreak(List<DateTime> workoutDates) {
    if (workoutDates.isEmpty) return 0;

    // Ordina le date in ordine decrescente
    final sortedDates = workoutDates..sort((a, b) => b.compareTo(a));

    int streak = 0;
    DateTime currentDate = DateTime.now();

    for (final workoutDate in sortedDates) {
      final daysDifference = currentDate.difference(workoutDate).inDays;

      // Se c'è un gap di più di 1 giorno, interrompi la streak
      if (daysDifference > 1) break;

      streak++;
      currentDate = workoutDate;
    }

    return streak;
  }
}