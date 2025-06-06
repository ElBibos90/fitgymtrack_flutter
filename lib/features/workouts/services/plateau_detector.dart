// lib/features/workouts/services/plateau_detector.dart
import 'dart:developer';
import '../models/plateau_models.dart';
import '../models/active_workout_models.dart';
import '../models/workout_plan_models.dart';
import '../models/workout_response_types.dart';

/// 🎯 STEP 6: Servizio per il rilevamento plateau
/// Traduzione Dart della logica Kotlin esistente
class PlateauDetector {
  final PlateauDetectionConfig config;

  const PlateauDetector({required this.config});

  /// Rileva plateau per un singolo esercizio
  Future<PlateauInfo?> detectPlateau({
    required int exerciseId,
    required String exerciseName,
    required double currentWeight,
    required int currentReps,
    required Map<int, List<CompletedSeriesData>> historicData,
  }) async {
    log('=== ANALISI PLATEAU ESERCIZIO $exerciseId ($exerciseName) ===');
    log('Peso corrente: $currentWeight, Reps correnti: $currentReps');
    log('Dati storici disponibili: ${historicData[exerciseId]?.length ?? 0} serie');

    final exerciseHistory = historicData[exerciseId];

    // Se non ci sono dati storici, prova plateau simulato per test
    if (exerciseHistory == null || exerciseHistory.isEmpty) {
      log('Nessun dato storico - controllo plateau simulato');
      return _checkSimulatedPlateau(exerciseId, exerciseName, currentWeight, currentReps);
    }

    // Raggruppa le serie per sessione di allenamento
    final sessionGroups = _groupSeriesBySession(exerciseHistory);
    log('Sessioni raggruppate: ${sessionGroups.length}');

    if (sessionGroups.length < config.minSessionsForPlateau) {
      log('Sessioni insufficienti: ${sessionGroups.length} < ${config.minSessionsForPlateau}');
      return _tryDetectWithLimitedData(exerciseId, exerciseName, currentWeight, currentReps, exerciseHistory);
    }

    // Prendi le ultime N sessioni per confronto serie per serie
    final recentSessions = sessionGroups.take(config.minSessionsForPlateau).toList();
    log('Analizzando le ultime ${config.minSessionsForPlateau} sessioni per confronto serie per serie');

    return _detectPlateauSeriesBySeries(
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      currentWeight: currentWeight,
      currentReps: currentReps,
      recentSessions: recentSessions,
      sessionsCount: config.minSessionsForPlateau,
    );
  }

  /// Rileva plateau per un gruppo di esercizi (superset/circuit)
  Future<GroupPlateauAnalysis> detectGroupPlateau({
    required String groupName,
    required String groupType,
    required List<WorkoutExercise> exercises,
    required Map<int, double> currentWeights,
    required Map<int, int> currentReps,
    required Map<int, List<CompletedSeriesData>> historicData,
  }) async {
    log('🔍 ANALISI PLATEAU GRUPPO: $groupName ($groupType)');

    final List<PlateauInfo> groupPlateaus = [];

    for (final exercise in exercises) {
      final exerciseId = exercise.schedaEsercizioId ?? exercise.id;
      final weight = currentWeights[exerciseId] ?? exercise.peso;
      final reps = currentReps[exerciseId] ?? exercise.ripetizioni;

      log('Analizzando esercizio: ${exercise.nome} (ID: $exerciseId)');

      final plateau = await detectPlateau(
        exerciseId: exerciseId,
        exerciseName: exercise.nome,
        currentWeight: weight,
        currentReps: reps,
        historicData: historicData,
      );

      if (plateau != null) {
        groupPlateaus.add(plateau);
        log('🚨 Plateau rilevato per ${exercise.nome}');
      }
    }

    final analysis = GroupPlateauAnalysis(
      groupName: groupName,
      groupType: groupType,
      plateauList: groupPlateaus,
      totalExercises: exercises.length,
      analyzedAt: DateTime.now(),
    );

    log('📊 RISULTATO GRUPPO: ${analysis.exercisesInPlateau}/${analysis.totalExercises} esercizi in plateau (${analysis.plateauPercentage.toStringAsFixed(1)}%)');

    return analysis;
  }

  /// 🆕 NUOVO: Confronto serie per serie per rilevamento plateau
  PlateauInfo? _detectPlateauSeriesBySeries({
    required int exerciseId,
    required String exerciseName,
    required double currentWeight,
    required int currentReps,
    required List<List<CompletedSeriesData>> recentSessions,
    required int sessionsCount,
  }) {
    log('🔍 CONFRONTO SERIE PER SERIE');

    // Organizza le serie per numero di serie
    final Map<int, List<CompletedSeriesData>> seriesByNumber = {};

    for (int sessionIndex = 0; sessionIndex < recentSessions.length; sessionIndex++) {
      final session = recentSessions[sessionIndex];
      log('📅 Sessione $sessionIndex: ${session.length} serie');

      for (final series in session) {
        final serieNumber = series.serieNumber ?? 1;
        seriesByNumber.putIfAbsent(serieNumber, () => []);
        seriesByNumber[serieNumber]!.add(series);
        log('   Serie $serieNumber: ${series.peso}kg x ${series.ripetizioni}');
      }
    }

    log('📊 Organizzazione per numero di serie:');
    seriesByNumber.forEach((serieNumber, seriesList) {
      log('Serie $serieNumber: ${seriesList.length} occorrenze nelle sessioni');
    });

    // Controlla ogni serie per plateau
    int plateauDetectedCount = 0;
    final int totalSeriesChecked = seriesByNumber.length;

    for (final entry in seriesByNumber.entries) {
      final serieNumber = entry.key;
      final seriesList = entry.value;

      // Verifica se questa serie appare in tutte le sessioni
      if (seriesList.length >= sessionsCount) {
        log('🔍 Controllo plateau Serie $serieNumber:');

        // Prendi le ultime N occorrenze (una per sessione)
        final recentSeries = seriesList.take(sessionsCount).toList();

        for (int index = 0; index < recentSeries.length; index++) {
          final series = recentSeries[index];
          log('   Sessione $index: ${series.peso}kg x ${series.ripetizioni}');
        }

        // Verifica se peso e ripetizioni sono rimasti costanti
        final firstSeries = recentSeries.first;
        final isWeightConstant = recentSeries.every((series) =>
        (series.peso - firstSeries.peso).abs() <= config.weightTolerance);
        final areRepsConstant = recentSeries.every((series) =>
        (series.ripetizioni - firstSeries.ripetizioni).abs() <= config.repsTolerance);

        log('   Serie $serieNumber: peso costante=$isWeightConstant, reps costanti=$areRepsConstant');

        // Se è la prima serie, controlla anche i valori correnti
        if (serieNumber == 1) {
          final currentMatchesPattern =
              (currentWeight - firstSeries.peso).abs() <= config.weightTolerance &&
                  (currentReps - firstSeries.ripetizioni).abs() <= config.repsTolerance;

          log('   Serie $serieNumber (corrente): valori corrispondono=$currentMatchesPattern');

          if (isWeightConstant && areRepsConstant && currentMatchesPattern) {
            plateauDetectedCount++;
            log('🚨 PLATEAU rilevato per Serie $serieNumber!');
          }
        } else {
          if (isWeightConstant && areRepsConstant) {
            plateauDetectedCount++;
            log('🚨 PLATEAU rilevato per Serie $serieNumber!');
          }
        }
      } else {
        log('⏭️ Serie $serieNumber: insufficienti dati (${seriesList.length}/$sessionsCount sessioni)');
      }
    }

    log('📈 RISULTATO: $plateauDetectedCount/$totalSeriesChecked serie in plateau');

    // Considera plateau se almeno il 50% delle serie sono in plateau
    final plateauThreshold = (totalSeriesChecked / 2).ceil().clamp(1, totalSeriesChecked);

    if (plateauDetectedCount >= plateauThreshold) {
      log('🚨 PLATEAU CONFERMATO per esercizio $exerciseId ($exerciseName)!');
      log('   Serie in plateau: $plateauDetectedCount/$totalSeriesChecked (soglia: $plateauThreshold)');

      // Usa i valori della serie più rappresentativa (tipicamente la prima)
      final representativeSeries = seriesByNumber[1]?.last ?? seriesByNumber.values.first.last;

      return PlateauInfo(
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        plateauType: _determinePlateauType(representativeSeries.peso, representativeSeries.ripetizioni),
        sessionsInPlateau: sessionsCount,
        currentWeight: representativeSeries.peso,
        currentReps: representativeSeries.ripetizioni,
        detectedAt: DateTime.now(),
        suggestions: _generateProgressionSuggestions(
          currentWeight: representativeSeries.peso,
          currentReps: representativeSeries.ripetizioni,
          exerciseHistory: recentSessions.expand((x) => x).toList(),
        ),
      );
    }

    log('✅ Nessun plateau significativo rilevato');
    return null;
  }

  /// Prova a rilevare plateau con dati limitati
  PlateauInfo? _tryDetectWithLimitedData(
      int exerciseId,
      String exerciseName,
      double currentWeight,
      int currentReps,
      List<CompletedSeriesData> exerciseHistory,
      ) {
    log('Tentativo rilevamento con dati limitati');

    // Se abbiamo almeno una serie storica, confrontala con i valori correnti
    if (exerciseHistory.isNotEmpty) {
      final lastSeries = exerciseHistory.last;
      final weightMatch = (currentWeight - lastSeries.peso).abs() <= config.weightTolerance;
      final repsMatch = (currentReps - lastSeries.ripetizioni).abs() <= config.repsTolerance;

      log('Confronto con ultima serie: peso match=$weightMatch, reps match=$repsMatch');

      if (weightMatch && repsMatch) {
        log('🚨 PLATEAU LIMITATO rilevato per esercizio $exerciseId ($exerciseName)!');

        return PlateauInfo(
          exerciseId: exerciseId,
          exerciseName: exerciseName,
          plateauType: _determinePlateauType(currentWeight, currentReps),
          sessionsInPlateau: 1,
          currentWeight: currentWeight,
          currentReps: currentReps,
          detectedAt: DateTime.now(),
          suggestions: _generateProgressionSuggestions(
            currentWeight: currentWeight,
            currentReps: currentReps,
            exerciseHistory: exerciseHistory,
          ),
        );
      }
    }

    return null;
  }

  /// Rileva plateau "simulato" per testing quando non ci sono dati storici
  PlateauInfo? _checkSimulatedPlateau(
      int exerciseId,
      String exerciseName,
      double currentWeight,
      int currentReps,
      ) {
    if (!config.enableSimulatedPlateau) return null;

    // Per testing: considera plateau se il peso è un valore "tipico" di plateau
    final isTypicalPlateauWeight = currentWeight > 0 && (
        currentWeight % 5 == 0 || // Pesi multipli di 5
            currentWeight % 2.5 == 0   // Pesi multipli di 2.5
    );

    final isTypicalePlateauReps = currentReps >= 6 && currentReps <= 15; // Range tipico di plateau

    log('Test plateau simulato: peso tipico=$isTypicalPlateauWeight, reps tipiche=$isTypicalePlateauReps');

    // AUMENTATO PER TESTING: rileva plateau simulato su più esercizi
    if (isTypicalPlateauWeight && isTypicalePlateauReps && exerciseId % 2 == 0) {
      log('🚨 PLATEAU SIMULATO rilevato per esercizio $exerciseId ($exerciseName) (per testing)!');

      return PlateauInfo(
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        plateauType: _determinePlateauType(currentWeight, currentReps),
        sessionsInPlateau: 2,
        currentWeight: currentWeight,
        currentReps: currentReps,
        detectedAt: DateTime.now(),
        suggestions: _generateProgressionSuggestions(
          currentWeight: currentWeight,
          currentReps: currentReps,
          exerciseHistory: [],
        ),
      );
    }

    // NUOVO: Plateau specifico per superset/circuit (per testing)
    final supersetKeywords = ['chest', 'press', 'fly', 'curl', 'extension', 'raise', 'squat', 'lunge'];
    final exerciseNameLower = exerciseName.toLowerCase();
    final hasKeyword = supersetKeywords.any((keyword) => exerciseNameLower.contains(keyword));

    if (hasKeyword && currentWeight >= 10 && exerciseId % 3 == 1) {
      log('🚨 PLATEAU SIMULATO SUPERSET rilevato per $exerciseId ($exerciseName) (per testing superset/circuit)!');

      return PlateauInfo(
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        plateauType: _determinePlateauType(currentWeight, currentReps),
        sessionsInPlateau: 3,
        currentWeight: currentWeight,
        currentReps: currentReps,
        detectedAt: DateTime.now(),
        suggestions: _generateProgressionSuggestions(
          currentWeight: currentWeight,
          currentReps: currentReps,
          exerciseHistory: [],
        ),
      );
    }

    return null;
  }

  /// Raggruppa le serie per sessione di allenamento
  List<List<CompletedSeriesData>> _groupSeriesBySession(List<CompletedSeriesData> series) {
    log('Raggruppamento ${series.length} serie per sessione...');

    // Prima prova a raggruppare per data (primi 10 caratteri del timestamp)
    final Map<String, List<CompletedSeriesData>> groupedByDate = {};

    for (final serie in series) {
      final timestamp = serie.timestamp;
      // Prendi i primi 10 caratteri se disponibili, altrimenti usa tutto il timestamp
      final dateKey = timestamp.length >= 10 ? timestamp.substring(0, 10) : timestamp;

      groupedByDate.putIfAbsent(dateKey, () => []);
      groupedByDate[dateKey]!.add(serie);
    }

    final sessionGroups = groupedByDate.values.toList()
      ..sort((a, b) => a.first.timestamp.compareTo(b.first.timestamp));

    log('Raggruppamento per data: ${sessionGroups.length} sessioni');
    for (int index = 0; index < sessionGroups.length; index++) {
      final session = sessionGroups[index];
      final date = session.first.timestamp.substring(0, 10.clamp(0, session.first.timestamp.length));
      log('Sessione $index ($date): ${session.length} serie');
    }

    // Se abbiamo solo una sessione ma molte serie, prova un raggruppamento alternativo
    if (sessionGroups.length == 1 && series.length >= 6) {
      log('Tentativo raggruppamento alternativo per serie multiple...');

      final List<List<CompletedSeriesData>> alternativeGroups = [];
      const seriesPerSession = 3;

      for (int i = 0; i < series.length; i += seriesPerSession) {
        final sessionEnd = (i + seriesPerSession).clamp(0, series.length);
        final sessionSeries = series.sublist(i, sessionEnd);
        if (sessionSeries.isNotEmpty) {
          alternativeGroups.add(sessionSeries);
        }
      }

      log('Raggruppamento alternativo: ${alternativeGroups.length} sessioni simulate');
      return alternativeGroups;
    }

    return sessionGroups;
  }

  /// Determina il tipo di plateau
  PlateauType _determinePlateauType(double weight, int reps) {
    if (weight < 10) return PlateauType.lightWeight;
    if (weight > 100) return PlateauType.heavyWeight;
    if (reps < 5) return PlateauType.lowReps;
    if (reps > 15) return PlateauType.highReps;
    return PlateauType.moderate;
  }

  /// Genera suggerimenti per la progressione
  List<ProgressionSuggestion> _generateProgressionSuggestions({
    required double currentWeight,
    required int currentReps,
    required List<CompletedSeriesData> exerciseHistory,
  }) {
    final List<ProgressionSuggestion> suggestions = [];

    // Suggerisci aumento di peso
    final double weightIncrement;
    if (currentWeight < 10) {
      weightIncrement = 0.5;
    } else if (currentWeight < 50) {
      weightIncrement = 1.25;
    } else if (currentWeight < 100) {
      weightIncrement = 2.5;
    } else {
      weightIncrement = 5.0;
    }

    suggestions.add(
      ProgressionSuggestion(
        type: SuggestionType.increaseWeight,
        description: 'Prova ad aumentare il peso a ${(currentWeight + weightIncrement).toStringAsFixed(1)} kg',
        newWeight: currentWeight + weightIncrement,
        newReps: currentReps,
        confidence: _calculateWeightIncreaseConfidence(currentWeight, exerciseHistory),
      ),
    );

    // Suggerisci aumento ripetizioni
    final int repsIncrement;
    if (currentReps < 8) {
      repsIncrement = 1;
    } else if (currentReps < 12) {
      repsIncrement = 2;
    } else {
      repsIncrement = 3;
    }

    suggestions.add(
      ProgressionSuggestion(
        type: SuggestionType.increaseReps,
        description: 'Prova ad aumentare le ripetizioni a ${currentReps + repsIncrement}',
        newWeight: currentWeight,
        newReps: currentReps + repsIncrement,
        confidence: _calculateRepsIncreaseConfidence(currentReps, exerciseHistory),
      ),
    );

    // Suggerisci tecniche avanzate per casi specifici
    if (currentWeight > 50 && currentReps > 10) {
      suggestions.add(
        ProgressionSuggestion(
          type: SuggestionType.advancedTechnique,
          description: 'Considera tecniche avanzate come drop set o rest-pause',
          newWeight: currentWeight,
          newReps: currentReps,
          confidence: 0.7,
        ),
      );
    }

    return suggestions..sort((a, b) => b.confidence.compareTo(a.confidence));
  }

  /// Calcola la confidenza per l'aumento di peso
  double _calculateWeightIncreaseConfidence(
      double currentWeight,
      List<CompletedSeriesData> history,
      ) {
    // Logica semplificata: più alto è il peso attuale rispetto alla storia,
    // meno confidenza abbiamo nell'aumentare ulteriormente
    if (history.isEmpty) return 0.6;

    final maxHistoricWeight = history.map((s) => s.peso).reduce((a, b) => a > b ? a : b);

    if (currentWeight <= maxHistoricWeight * 0.8) return 0.9;
    if (currentWeight <= maxHistoricWeight * 0.95) return 0.7;
    if (currentWeight >= maxHistoricWeight) return 0.5;
    return 0.6;
  }

  /// Calcola la confidenza per l'aumento delle ripetizioni
  double _calculateRepsIncreaseConfidence(
      int currentReps,
      List<CompletedSeriesData> history,
      ) {
    if (history.isEmpty) return 0.5;

    final maxHistoricReps = history.map((s) => s.ripetizioni).reduce((a, b) => a > b ? a : b);

    if (currentReps <= maxHistoricReps * 0.8) return 0.8;
    if (currentReps <= maxHistoricReps) return 0.6;
    if (currentReps > maxHistoricReps) return 0.4;
    return 0.5;
  }

  /// Calcola statistiche aggregate sui plateau
  PlateauStatistics calculateStatistics(List<PlateauInfo> allPlateaus) {
    if (allPlateaus.isEmpty) return createEmptyStatistics();

    final Map<PlateauType, int> plateauByType = {};
    final Map<SuggestionType, int> suggestionsByType = {};

    double totalSessions = 0;

    for (final plateau in allPlateaus) {
      // Conta per tipo di plateau
      plateauByType[plateau.plateauType] = (plateauByType[plateau.plateauType] ?? 0) + 1;

      // Conta sessioni
      totalSessions += plateau.sessionsInPlateau;

      // Conta suggerimenti
      for (final suggestion in plateau.suggestions) {
        suggestionsByType[suggestion.type] = (suggestionsByType[suggestion.type] ?? 0) + 1;
      }
    }

    return PlateauStatistics(
      totalExercisesAnalyzed: allPlateaus.length, // Nota: questo dovrebbe essere il totale degli esercizi analizzati, non solo quelli in plateau
      totalPlateauDetected: allPlateaus.length,
      plateauByType: plateauByType,
      suggestionsByType: suggestionsByType,
      lastAnalysisAt: DateTime.now(),
      averageSessionsInPlateau: totalSessions / allPlateaus.length,
    );
  }
}

/// Helper per il formatting dei pesi
class WeightFormatter {
  static String formatWeight(double weight) {
    if (weight == weight.toInt()) {
      return weight.toInt().toString();
    }
    return weight.toStringAsFixed(1);
  }
}