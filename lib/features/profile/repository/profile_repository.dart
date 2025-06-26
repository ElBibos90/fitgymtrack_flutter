// lib/features/profile/repository/profile_repository.dart

import 'dart:developer';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/result.dart';
import '../models/user_profile_models.dart';

/// Repository per gestire le operazioni del profilo utente
class ProfileRepository {
  final ApiClient _apiClient;

  ProfileRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Ottiene il profilo dell'utente corrente o di un utente specifico
  Future<Result<UserProfile>> getUserProfile({int? userId}) async {
    try {
      log('[CONSOLE] [profile_repository] 📡 Getting user profile${userId != null ? ' for user $userId' : ''}');

      final response = await _apiClient.getUserProfile(userId: userId);

      log('[CONSOLE] [profile_repository] ✅ Profile response received: ${response.toString().substring(0, 100)}...');

      // Il backend restituisce direttamente l'oggetto profilo
      if (response is Map<String, dynamic>) {
        final profile = UserProfile.fromJson(response);
        log('[CONSOLE] [profile_repository] ✅ Profile parsed successfully for user ${profile.userId}');
        return Result.success(profile);
      } else {
        log('[CONSOLE] [profile_repository] ❌ Invalid response format: ${response.runtimeType}');
        return Result.error('Formato risposta non valido', null);
      }

    } catch (e, stackTrace) {
      log('[CONSOLE] [profile_repository] ❌ Error getting profile: $e');
      log('[CONSOLE] [profile_repository] ❌ Stack trace: $stackTrace');

      return Result.error(
        _handleError(e),
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Aggiorna il profilo dell'utente
  Future<Result<UserProfile>> updateUserProfile({
    required UserProfile profile,
    int? userId,
  }) async {
    try {
      log('[CONSOLE] [profile_repository] 📡 Updating profile for user ${profile.userId}');

      // Prepara i dati per l'API (solo campi che possono essere aggiornati)
      final updateData = {
        if (profile.height != null) 'height': profile.height,
        if (profile.weight != null) 'weight': profile.weight,
        if (profile.age != null) 'age': profile.age,
        if (profile.gender != null) 'gender': profile.gender,
        'experienceLevel': profile.experienceLevel,
        if (profile.fitnessGoals != null) 'fitnessGoals': profile.fitnessGoals,
        if (profile.injuries != null) 'injuries': profile.injuries,
        if (profile.preferences != null) 'preferences': profile.preferences,
        if (profile.notes != null) 'notes': profile.notes,
      };

      log('[CONSOLE] [profile_repository] 📤 Sending update data: $updateData');

      final response = await _apiClient.updateUserProfile(
        updateData,
        userId: userId,
      );

      log('[CONSOLE] [profile_repository] ✅ Update response received');

      // Il backend restituisce { message: "...", profile: {...} }
      if (response is Map<String, dynamic>) {
        if (response.containsKey('profile') && response['profile'] is Map<String, dynamic>) {
          final updatedProfile = UserProfile.fromJson(response['profile']);
          log('[CONSOLE] [profile_repository] ✅ Profile updated successfully');
          return Result.success(updatedProfile);
        } else if (response.containsKey('error')) {
          log('[CONSOLE] [profile_repository] ❌ Server error: ${response['error']}');
          return Result.error(response['error'].toString(), null);
        } else {
          log('[CONSOLE] [profile_repository] ❌ Unexpected response structure: $response');
          return Result.error('Risposta del server non valida', null);
        }
      } else {
        log('[CONSOLE] [profile_repository] ❌ Invalid response type: ${response.runtimeType}');
        return Result.error('Formato risposta non valido', null);
      }

    } catch (e, stackTrace) {
      log('[CONSOLE] [profile_repository] ❌ Error updating profile: $e');
      log('[CONSOLE] [profile_repository] ❌ Stack trace: $stackTrace');

      return Result.error(
        _handleError(e),
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Crea un profilo predefinito per un nuovo utente
  Future<Result<UserProfile>> createDefaultProfile(int userId) async {
    try {
      log('[CONSOLE] [profile_repository] 📡 Creating default profile for user $userId');

      // Crea un profilo di base
      final defaultProfile = UserProfile.empty(userId).copyWith(
        height: 175,
        weight: 70.0,
        age: 25,
        gender: 'male',
        experienceLevel: 'beginner',
        fitnessGoals: 'general_fitness',
      );

      // Usa updateUserProfile per creare il profilo
      // Il backend crea automaticamente un profilo se non esiste
      return await updateUserProfile(profile: defaultProfile, userId: userId);

    } catch (e) {
      log('[CONSOLE] [profile_repository] ❌ Error creating default profile: $e');
      return Result.error(
        'Errore nella creazione del profilo predefinito',
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Gestisce gli errori e li converte in messaggi user-friendly
  String _handleError(dynamic error) {
    log('[CONSOLE] [profile_repository] 🔍 Handling error: $error (${error.runtimeType})');

    if (error.toString().contains('SocketException') ||
        error.toString().contains('NetworkException')) {
      return 'Errore di connessione. Verifica la tua connessione internet.';
    }

    if (error.toString().contains('TimeoutException')) {
      return 'Timeout della richiesta. Riprova più tardi.';
    }

    if (error.toString().contains('FormatException')) {
      return 'Errore nel formato dei dati ricevuti dal server.';
    }

    if (error.toString().contains('401')) {
      return 'Accesso non autorizzato. Effettua nuovamente il login.';
    }

    if (error.toString().contains('403')) {
      return 'Non hai i permessi per accedere a questo profilo.';
    }

    if (error.toString().contains('404')) {
      return 'Profilo non trovato.';
    }

    if (error.toString().contains('500')) {
      return 'Errore interno del server. Riprova più tardi.';
    }

    // Messaggio generico per errori non identificati
    return 'Si è verificato un errore imprevisto. Riprova più tardi.';
  }
}