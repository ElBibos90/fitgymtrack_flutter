// lib/core/services/user_role_service.dart

import '../../features/auth/models/login_response.dart';

/// 🎯 Servizio per gestire i ruoli utente e le relative funzionalità
class UserRoleService {
  
  /// Verifica se l'utente è standalone (gestisce tutto da solo)
  static bool isStandaloneUser(User? user) {
    return user?.roleId == 4;
  }
  
  /// Verifica se l'utente è collegato a una palestra
  static bool isGymUser(User? user) {
    return user?.roleId == 2;
  }
  
  /// Verifica se l'utente può gestire le schede (creare/modificare/cancellare)
  static bool canManageWorkoutSchemes(User? user) {
    return isStandaloneUser(user);
  }
  
  /// Verifica se l'utente può vedere le azioni rapide (Misure, Nutrizione, Template)
  static bool canSeeQuickActions(User? user) {
    return isStandaloneUser(user);
  }
  
  /// Verifica se l'utente può vedere il banner donazione
  static bool canSeeDonationBanner(User? user) {
    return isStandaloneUser(user);
  }
  
  /// Verifica se l'utente può vedere il tab abbonamento
  static bool canSeeSubscriptionTab(User? user) {
    return isStandaloneUser(user);
  }
  
  /// Verifica se l'utente può vedere i template schede
  static bool canSeeWorkoutTemplates(User? user) {
    return isStandaloneUser(user);
  }
  
  /// Verifica se l'utente deve vedere l'abbonamento palestra
  static bool shouldSeeGymSubscription(User? user) {
    return isGymUser(user);
  }
  
  /// Ottiene il nome del ruolo utente
  static String getRoleName(User? user) {
    switch (user?.roleId) {
      case 2:
        return 'Membro Palestra';
      case 4:
        return 'Utente Standalone';
      default:
        return 'Utente';
    }
  }
  
  /// Ottiene la descrizione del ruolo utente
  static String getRoleDescription(User? user) {
    switch (user?.roleId) {
      case 2:
        return 'Sei collegato a una palestra. La tua scheda è gestita dal trainer.';
      case 4:
        return 'Gestisci tutto da solo. Puoi creare e modificare le tue schede.';
      default:
        return 'Ruolo utente non riconosciuto.';
    }
  }
}
