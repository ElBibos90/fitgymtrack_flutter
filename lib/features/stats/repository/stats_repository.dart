// lib/features/stats/repository/stats_repository.dart

import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/stats_models.dart';

class StatsRepository {
  final ApiClient _apiClient;

  StatsRepository(this._apiClient);

  // ============================================================================
  // 📊 USER STATS - Statistiche Generali Utente
  // ============================================================================

  /// Recupera le statistiche generali dell'utente
  Future<UserStatsResponse> getUserStats() async {
    try {
      print('🔄 Recupero statistiche utente...');

      final response = await _apiClient.getUserStats();
      final statsResponse = UserStatsResponse.fromJson(response);

      print('📊 Statistiche caricate - Premium: ${statsResponse.isPremium}');
      return statsResponse;

    } on DioException catch (e) {
      print('❌ Errore DioException nel recupero statistiche utente: ${e.message}');

      if (e.response?.statusCode == 401) {
        throw StatsException('Sessione scaduta. Effettua nuovamente il login.');
      } else if (e.response?.statusCode == 403) {
        throw StatsException('Accesso negato alle statistiche.');
      } else if (e.response?.statusCode == 500) {
        throw StatsException('Errore interno del server. Riprova più tardi.');
      }

      throw StatsException('Errore di connessione. Verifica la tua connessione internet.');

    } catch (e) {
      print('❌ Errore generico nel recupero statistiche utente: $e');
      throw StatsException('Errore imprevisto nel caricamento delle statistiche.');
    }
  }

  // ============================================================================
  // 📅 PERIOD STATS - Statistiche per Periodo
  // ============================================================================

  /// Recupera le statistiche per un periodo specifico
  Future<PeriodStatsResponse> getPeriodStats(StatsPeriod period) async {
    try {
      print('🔄 Recupero statistiche periodo: ${period.apiValue}');

      final response = await _apiClient.getPeriodStats(period.apiValue);
      final periodStatsResponse = PeriodStatsResponse.fromJson(response);

      print('📅 Statistiche periodo ${period.displayName} caricate - Premium: ${periodStatsResponse.isPremium}');
      return periodStatsResponse;

    } on DioException catch (e) {
      print('❌ Errore DioException nel recupero statistiche periodo: ${e.message}');

      if (e.response?.statusCode == 400) {
        throw StatsException('Periodo non valido: ${period.apiValue}');
      } else if (e.response?.statusCode == 401) {
        throw StatsException('Sessione scaduta. Effettua nuovamente il login.');
      } else if (e.response?.statusCode == 403) {
        throw StatsException('Accesso negato alle statistiche del periodo.');
      } else if (e.response?.statusCode == 500) {
        throw StatsException('Errore interno del server. Riprova più tardi.');
      }

      throw StatsException('Errore di connessione. Verifica la tua connessione internet.');

    } catch (e) {
      print('❌ Errore generico nel recupero statistiche periodo: $e');
      throw StatsException('Errore imprevisto nel caricamento delle statistiche del periodo.');
    }
  }

  // ============================================================================
  // 🔄 COMBINED METHODS - Metodi Combinati
  // ============================================================================

  /// Recupera sia le statistiche utente che quelle di un periodo specifico
  Future<StatsBundle> getStatsBundle(StatsPeriod initialPeriod) async {
    try {
      print('🔄 Recupero bundle statistiche completo...');

      // Esegui le chiamate in parallelo per migliori performance
      final results = await Future.wait([
        getUserStats(),
        getPeriodStats(initialPeriod),
      ]);

      final userStats = results[0] as UserStatsResponse;
      final periodStats = results[1] as PeriodStatsResponse;

      print('📊 Bundle statistiche caricato con successo');

      return StatsBundle(
        userStats: userStats,
        periodStats: periodStats,
        isPremium: userStats.isPremium,
      );

    } catch (e) {
      print('❌ Errore nel recupero bundle statistiche: $e');
      rethrow;
    }
  }

  /// Aggiorna le statistiche di un periodo specifico
  Future<PeriodStatsResponse> refreshPeriodStats(StatsPeriod period) async {
    print('🔄 Refresh statistiche periodo: ${period.displayName}');

    final stats = await getPeriodStats(period);

    print('✅ Refresh completato per periodo: ${period.displayName}');
    return stats;
  }
}

// ============================================================================
// 📊 SUPPORT CLASSES
// ============================================================================

class StatsBundle {
  final UserStatsResponse userStats;
  final PeriodStatsResponse periodStats;
  final bool isPremium;

  const StatsBundle({
    required this.userStats,
    required this.periodStats,
    required this.isPremium,
  });
}

class StatsException implements Exception {
  final String message;

  const StatsException(this.message);

  @override
  String toString() => 'StatsException: $message';
}