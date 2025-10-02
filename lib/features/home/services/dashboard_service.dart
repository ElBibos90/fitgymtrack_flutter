// lib/features/home/services/dashboard_service.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/quick_action.dart';
import '../../tools/presentation/widgets/one_rep_max_dialog.dart';
import '../../../core/services/user_role_service.dart';
import '../../../features/auth/models/login_response.dart';

/// Service per gestire la business logic della dashboard
class DashboardService {

  /// ✅ FIX: Configura le Quick Actions principali con CALLBACK FUNCTIONS
  static List<QuickAction> getQuickActions(
      BuildContext context, {
        VoidCallback? onNavigateToWorkouts,    // 🆕 Callback per navigazione workout
        VoidCallback? onNavigateToAchievements, // 🆕 Callback per achievements
        VoidCallback? onNavigateToProfile,      // 🆕 Callback per profilo
      }) {
    return [
      QuickAction(
        id: 'start_workout',
        icon: Icons.play_circle_fill_rounded,
        title: 'Inizia\nAllenamento',
        color: const Color(0xFF48BB78), // Verde
        onTap: onNavigateToWorkouts ?? () => _navigateToWorkouts(context), // 🔧 FIX: Usa callback se disponibile
      ),
      QuickAction(
        id: 'workout_history',
        icon: Icons.history_rounded,
        title: 'Storico\nAllenamenti',
        color: const Color(0xFF4299E1), // Blu
        onTap: () => _navigateToWorkoutHistory(context),
      ),
      QuickAction(
        id: 'calculate_1rm',
        icon: Icons.calculate_rounded,
        title: 'Calcola\n1RM',
        color: const Color(0xFF667EEA), // Blu
        onTap: () => _showOneRepMaxDialog(context), // ✅ Già funziona correttamente
      ),
      QuickAction(
        id: 'achievements',
        icon: Icons.emoji_events_rounded,
        title: 'Achievement',
        color: const Color(0xFFED8936), // Arancione
        onTap: onNavigateToAchievements ?? () => _navigateToAchievements(context), // 🔧 FIX: Usa callback se disponibile
      ),
    ];
  }

  /// Quick Actions secondarie (future features)
  /// 🎯 NUOVO: Nasconde azioni per utenti role_id: 2 (collegati a palestra)
  static List<QuickAction> getSecondaryActions(BuildContext context, {User? user}) {
    // Se l'utente è collegato a una palestra, non mostrare azioni secondarie
    if (!UserRoleService.canSeeQuickActions(user)) {
      return [];
    }
    
    return [
      QuickAction(
        id: 'templates',
        icon: Icons.fitness_center_rounded,
        title: 'Template\nSchede',
        color: const Color(0xFF667EEA), // Viola
        onTap: () => _navigateToTemplates(context),
        isEnabled: true, // ✅ NUOVO: Template schede disponibili
      ),
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
  // NAVIGATION HELPERS - 🚨 FALLBACK (da rimuovere quando tutto usa callback)
  // ============================================================================

  /// ❌ DEPRECATO: Naviga alla tab Workouts usando GoRouter (PROBLEMATICO)
  /// Usare invece la callback function onNavigateToWorkouts
  static void _navigateToWorkouts(BuildContext context) {
    //print('[CONSOLE] [dashboard_service]⚠️ WARNING: Using deprecated GoRouter navigation!');
    print('[CONSOLE] [dashboard_service]💡 SUGGESTION: Pass onNavigateToWorkouts callback instead');
    // Per ora usa GoRouter come fallback
    context.go('/workouts');
  }

  /// ❌ DEPRECATO: Naviga alla schermata Achievements
  /// Usare invece la callback function onNavigateToAchievements
  static void _navigateToAchievements(BuildContext context) {
    print('[CONSOLE] [dashboard_service]⚠️ WARNING: Using deprecated GoRouter navigation!');
    print('[CONSOLE] [dashboard_service]💡 SUGGESTION: Pass onNavigateToAchievements callback instead');
    context.push('/achievements');
  }

  /// ❌ DEPRECATO: Naviga alla schermata Profilo
  /// Usare invece la callback function onNavigateToProfile
  static void _navigateToProfile(BuildContext context) {
    print('[CONSOLE] [dashboard_service]⚠️ WARNING: Using deprecated GoRouter navigation!');
    print('[CONSOLE] [dashboard_service]💡 SUGGESTION: Pass onNavigateToProfile callback instead');
    context.push('/profile');
  }

  /// ✅ NUOVO: Naviga alla schermata Template
  static void _navigateToTemplates(BuildContext context) {
    context.push('/templates');
  }

  /// Navigazione allo storico allenamenti
  static void _navigateToWorkoutHistory(BuildContext context) {
    context.go('/workouts/history');
  }

  // ============================================================================
  // DIALOG HELPERS - ✅ Questi funzionano correttamente
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
  // GREETING HELPERS - ✅ Funzionalità esistenti mantenute
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
  // UTILITIES - ✅ Funzionalità esistenti mantenute
  // ============================================================================

  /// Formatta data per display UI
  static String formatLastWorkoutDate(DateTime? date) {
    if (date == null) return 'Nessun allenamento';

    final now = DateTime.now();
    final difference = now.difference(date);

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