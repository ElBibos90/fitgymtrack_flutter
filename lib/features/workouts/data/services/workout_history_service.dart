import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config/app_config.dart';
import '../../../../core/entities/user.dart';
import '../entities/completed_series.dart';

/// 🏋️ Workout History Service
/// Servizio per gestire i dati storici degli allenamenti
class WorkoutHistoryService {
  static const String _baseUrl = AppConfig.baseUrl;
  
  /// 📊 Ottiene lo storico per un esercizio specifico
  /// Utilizza l'API esistente: GET /api/serie_completate.php?esercizio_id={exerciseId}
  static Future<List<CompletedSeries>> getExerciseHistory({
    required int exerciseId,
    required int userId,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/api/serie_completate.php?esercizio_id=$exerciseId');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => CompletedSeries.fromJson(json)).toList();
      } else {
        throw Exception('Errore nel caricamento storico: ${response.statusCode}');
      }
    } catch (e) {
      print('Errore WorkoutHistoryService.getExerciseHistory: $e');
      rethrow;
    }
  }

  /// 📈 Ottiene i dati di progressione per un esercizio
  /// Utilizza l'API esistente: GET /api/serie_completate.php?progress=true
  static Future<List<Map<String, dynamic>>> getProgressData({
    required int userId,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/api/serie_completate.php?progress=true');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Errore nel caricamento progressione: ${response.statusCode}');
      }
    } catch (e) {
      print('Errore WorkoutHistoryService.getProgressData: $e');
      rethrow;
    }
  }

  /// 🎯 Mappa le serie dell'ultimo allenamento per serie_number
  /// Restituisce una mappa: serie_number -> CompletedSeries
  static Map<int, CompletedSeries> mapLastWorkoutSeries(List<CompletedSeries> history) {
    final Map<int, CompletedSeries> seriesMap = {};
    
    if (history.isEmpty) return seriesMap;
    
    // Trova l'ultimo allenamento (primo elemento della lista ordinata per timestamp DESC)
    final lastWorkoutId = history.first.allenamentoId;
    
    // Mappa tutte le serie dell'ultimo allenamento per serie_number
    for (final series in history) {
      if (series.allenamentoId == lastWorkoutId) {
        seriesMap[series.serieNumber] = series;
      }
    }
    
    return seriesMap;
  }

  /// 📊 Calcola le statistiche di progressione
  static Map<String, dynamic> calculateProgressStats(List<CompletedSeries> history) {
    if (history.isEmpty) {
      return {
        'totalWorkouts': 0,
        'averageWeight': 0.0,
        'maxWeight': 0.0,
        'averageReps': 0.0,
        'maxReps': 0,
        'lastWorkoutDate': null,
        'improvementTrend': 'neutral',
      };
    }

    // Statistiche generali
    final totalWorkouts = history.map((s) => s.allenamentoId).toSet().length;
    final averageWeight = history.map((s) => s.peso).reduce((a, b) => a + b) / history.length;
    final maxWeight = history.map((s) => s.peso).reduce((a, b) => a > b ? a : b);
    final averageReps = history.map((s) => s.ripetizioni).reduce((a, b) => a + b) / history.length;
    final maxReps = history.map((s) => s.ripetizioni).reduce((a, b) => a > b ? a : b);
    final lastWorkoutDate = history.first.timestamp;

    // Calcola trend di miglioramento (ultimi 3 vs precedenti 3)
    String improvementTrend = 'neutral';
    if (history.length >= 6) {
      final recent = history.take(3).toList();
      final previous = history.skip(3).take(3).toList();
      
      final recentAvgWeight = recent.map((s) => s.peso).reduce((a, b) => a + b) / recent.length;
      final previousAvgWeight = previous.map((s) => s.peso).reduce((a, b) => a + b) / previous.length;
      
      if (recentAvgWeight > previousAvgWeight) {
        improvementTrend = 'improving';
      } else if (recentAvgWeight < previousAvgWeight) {
        improvementTrend = 'declining';
      }
    }

    return {
      'totalWorkouts': totalWorkouts,
      'averageWeight': averageWeight,
      'maxWeight': maxWeight,
      'averageReps': averageReps,
      'maxReps': maxReps,
      'lastWorkoutDate': lastWorkoutDate,
      'improvementTrend': improvementTrend,
    };
  }

  /// 🎯 Ottiene i dati per il sistema "vs ultima"
  static Map<int, CompletedSeries> getVsUltimaData({
    required int exerciseId,
    required int userId,
  }) async {
    try {
      final history = await getExerciseHistory(
        exerciseId: exerciseId,
        userId: userId,
      );
      
      return mapLastWorkoutSeries(history);
    } catch (e) {
      print('Errore WorkoutHistoryService.getVsUltimaData: $e');
      return {};
    }
  }
}
