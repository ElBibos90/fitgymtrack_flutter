// lib/features/workouts/services/plateau_detector.dart

import '../models/plateau_models.dart';
import '../models/active_workout_models.dart';
import '../models/workout_plan_models.dart';
import '../models/workout_response_types.dart';

/// 🎯 STEP 6: Servizio per il rilevamento plateau
/// 🔧 FIX: Logica serie-per-serie corretta + debug intensivo
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
    print('[CONSOLE]=== 🎯 ANALISI PLATEAU ESERCIZIO $exerciseId ($exerciseName) ===');
    print('[CONSOLE]Peso corrente: $currentWeight, Reps correnti: $currentReps');
    print('[CONSOLE]Dati storici disponibili: ${historicData[exerciseId]?.length ?? 0} serie');

    final exerciseHistory = historicData[exerciseId];

    // Se non ci sono dati storici, prova plateau simulato per test
    if (exerciseHistory == null || exerciseHistory.isEmpty) {
      print('[CONSOLE]⚠️ Nessun dato storico - controllo plateau simulato');
      return _checkSimulatedPlateau(exerciseId, exerciseName, currentWeight, currentReps);
    }

    // 🔧 FIX: Raggruppa le serie per sessione di allenamento (per timestamp/data)
    final sessionGroups = _groupSeriesBySession(exerciseHistory);
    print('[CONSOLE]📅 Sessioni raggruppate: ${sessionGroups.length}');

    if (sessionGroups.length < config.minSessionsForPlateau) {
      print('[CONSOLE]⚠️ Sessioni insufficienti: ${sessionGroups.length} < ${config.minSessionsForPlateau}');
      return _tryDetectWithLimitedData(exerciseId, exerciseName, currentWeight, currentReps, exerciseHistory);
    }

    // 🔧 FIX: Prendi le ultime N sessioni per confronto serie per serie
    final recentSessions = sessionGroups.take(config.minSessionsForPlateau).toList();
    print('[CONSOLE]🔍 Analizzando le ultime ${config.minSessionsForPlateau} sessioni per confronto serie per serie');

    // 📊 DEBUG: Log dettagliato delle sessioni
    for (int i = 0; i < recentSessions.length; i++) {
      final session = recentSessions[i];
      print('[CONSOLE]📅 Sessione $i (${session.length} serie):');
      for (final series in session) {
        print('[CONSOLE]   Serie ${series.serieNumber ?? "?"}: ${series.peso}kg x ${series.ripetizioni} (timestamp: ${series.timestamp})');
      }
    }

    return _detectPlateauSeriesBySeries(
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      currentWeight: currentWeight,
      currentReps: currentReps,
      recentSessions: recentSessions,
      sessionsCount: config.minSessionsForPlateau,
    );
  }

  /// 🔧 FIX: Confronto serie per serie PERFEZIONATO
  PlateauInfo? _detectPlateauSeriesBySeries({
    required int exerciseId,
    required String exerciseName,
    required double currentWeight,
    required int currentReps,
    required List<List<CompletedSeriesData>> recentSessions,
    required int sessionsCount,
  }) {
    print('[CONSOLE]🔍 === CONFRONTO SERIE PER SERIE PERFEZIONATO ===');

    // 🔧 FIX: Organizza le serie per numero di serie (1, 2, 3, ecc.)
    final Map<int, List<CompletedSeriesData>> seriesByNumber = {};

    for (int sessionIndex = 0; sessionIndex < recentSessions.length; sessionIndex++) {
      final session = recentSessions[sessionIndex];
      print('[CONSOLE]📅 Processando Sessione $sessionIndex: ${session.length} serie');

      for (final series in session) {
        final serieNumber = series.serieNumber ?? 1;
        seriesByNumber.putIfAbsent(serieNumber, () => []);
        seriesByNumber[serieNumber]!.add(series);
        print('[CONSOLE]   ➕ Serie $serieNumber: ${series.peso}kg x ${series.ripetizioni} → aggiunta al gruppo');
      }
    }

    print('[CONSOLE]📊 Organizzazione finale per numero di serie:');
    seriesByNumber.forEach((serieNumber, seriesList) {
      print('[CONSOLE]📍 Serie $serieNumber: ${seriesList.length} occorrenze nelle sessioni');
      for (int i = 0; i < seriesList.length; i++) {
        final series = seriesList[i];
        print('[CONSOLE]    Occorrenza $i: ${series.peso}kg x ${series.ripetizioni}');
      }
    });

    // 🔧 FIX: Controlla plateau per ogni numero di serie
    int plateauDetectedCount = 0;
    final List<int> plateauSeriesNumbers = [];
    final int totalSeriesChecked = seriesByNumber.length;

    for (final entry in seriesByNumber.entries) {
      final serieNumber = entry.key;
      final seriesList = entry.value;

      print('[CONSOLE]🔍 === CONTROLLO PLATEAU SERIE $serieNumber ===');

      // ✅ LOGICA CORRETTA: Verifica se questa serie appare in tutte le sessioni richieste
      if (seriesList.length >= sessionsCount) {
        // 🔧 FIX: Prendi le ultime N occorrenze (ordinate per sessione più recente)
        final recentSeriesForThisNumber = seriesList.take(sessionsCount).toList();

        print('[CONSOLE]📋 Serie $serieNumber - Controllo ${recentSeriesForThisNumber.length} occorrenze:');
        for (int index = 0; index < recentSeriesForThisNumber.length; index++) {
          final series = recentSeriesForThisNumber[index];
          print('[CONSOLE]   Sessione $index: ${series.peso}kg x ${series.ripetizioni}');
        }

        // ✅ LOGICA PLATEAU: Verifica se peso e ripetizioni sono rimasti costanti
        final firstSeries = recentSeriesForThisNumber.first;
        final isWeightConstant = recentSeriesForThisNumber.every((series) =>
        (series.peso - firstSeries.peso).abs() <= config.weightTolerance);
        final areRepsConstant = recentSeriesForThisNumber.every((series) =>
        (series.ripetizioni - firstSeries.ripetizioni).abs() <= config.repsTolerance);

        print('[CONSOLE]   🔍 Serie $serieNumber: peso costante=$isWeightConstant, reps costanti=$areRepsConstant');

        // 🔧 FIX: Per la serie 1, controlla anche i valori correnti dell'allenamento attivo
        bool currentMatchesPattern = true;
        if (serieNumber == 1) {
          currentMatchesPattern =
              (currentWeight - firstSeries.peso).abs() <= config.weightTolerance &&
                  (currentReps - firstSeries.ripetizioni).abs() <= config.repsTolerance;

          print('[CONSOLE]   🎯 Serie $serieNumber (CORRENTE): valori attuali corrispondono=$currentMatchesPattern');
          print('[CONSOLE]       Peso attuale: $currentWeight vs storico: ${firstSeries.peso}');
          print('[CONSOLE]       Reps attuali: $currentReps vs storico: ${firstSeries.ripetizioni}');
        }

        // ✅ PLATEAU RILEVATO se tutti i criteri sono soddisfatti
        final isPlateauForThisSeries = isWeightConstant && areRepsConstant &&
            (serieNumber == 1 ? currentMatchesPattern : true);

        if (isPlateauForThisSeries) {
          plateauDetectedCount++;
          plateauSeriesNumbers.add(serieNumber);
          print('[CONSOLE]🚨 PLATEAU CONFERMATO per Serie $serieNumber!');
        } else {
          print('[CONSOLE]✅ Serie $serieNumber: NO plateau (criteri non soddisfatti)');
        }
      } else {
        print('[CONSOLE]⏭️ Serie $serieNumber: dati insufficienti (${seriesList.length}/$sessionsCount sessioni)');
      }
    }

    print('[CONSOLE]📈 === RISULTATO FINALE ===');
    print('[CONSOLE]Serie in plateau: $plateauDetectedCount/$totalSeriesChecked');
    print('[CONSOLE]Serie con plateau: $plateauSeriesNumbers');

    // 🔧 FIX: Considera plateau se almeno il 50% delle serie sono in plateau (minimo 1)
    final plateauThreshold = (totalSeriesChecked / 2).ceil().clamp(1, totalSeriesChecked);
    print('[CONSOLE]🎯 Soglia plateau: $plateauThreshold serie');

    if (plateauDetectedCount >= plateauThreshold) {
      print('[CONSOLE]🚨 === PLATEAU CONFERMATO PER ESERCIZIO $exerciseId ($exerciseName) ===');
      print('[CONSOLE]   Serie in plateau: $plateauDetectedCount/$totalSeriesChecked (soglia: $plateauThreshold)');

      // 🔧 FIX: Usa i valori della serie 1 come rappresentativi (o la prima serie disponibile)
      final representativeSeries = seriesByNumber[1]?.first ?? seriesByNumber.values.first.first;

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

    print('[CONSOLE]✅ Nessun plateau significativo rilevato per $exerciseName');
    return null;
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
    print('[CONSOLE]🔍 === ANALISI PLATEAU GRUPPO: $groupName ($groupType) ===');

    final List<PlateauInfo> groupPlateaus = [];

    for (final exercise in exercises) {
      final exerciseId = exercise.schedaEsercizioId ?? exercise.id;
      final weight = currentWeights[exerciseId] ?? exercise.peso;
      final reps = currentReps[exerciseId] ?? exercise.ripetizioni;

      print('[CONSOLE]🔍 Analizzando esercizio: ${exercise.nome} (ID: $exerciseId)');

      final plateau = await detectPlateau(
        exerciseId: exerciseId,
        exerciseName: exercise.nome,
        currentWeight: weight,
        currentReps: reps,
        historicData: historicData,
      );

      if (plateau != null) {
        groupPlateaus.add(plateau);
        print('[CONSOLE]🚨 Plateau rilevato per ${exercise.nome}');
      } else {
        print('[CONSOLE]✅ Nessun plateau per ${exercise.nome}');
      }
    }

    final analysis = GroupPlateauAnalysis(
      groupName: groupName,
      groupType: groupType,
      plateauList: groupPlateaus,
      totalExercises: exercises.length,
      analyzedAt: DateTime.now(),
    );

    print('[CONSOLE]📊 RISULTATO GRUPPO: ${analysis.exercisesInPlateau}/${analysis.totalExercises} esercizi in plateau (${analysis.plateauPercentage.toStringAsFixed(1)}%)');

    return analysis;
  }

  /// 🔧 FIX: Raggruppa le serie per sessione di allenamento più intelligente
  List<List<CompletedSeriesData>> _groupSeriesBySession(List<CompletedSeriesData> series) {
    print('[CONSOLE]📅 === RAGGRUPPAMENTO SERIE PER SESSIONE ===');
    print('[CONSOLE]Raggruppamento ${series.length} serie per sessione...');

    if (series.isEmpty) return [];

    // 🔧 FIX: Ordina le serie per timestamp (più recente prima)
    final sortedSeries = List<CompletedSeriesData>.from(series);
    sortedSeries.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    print('[CONSOLE]📊 Serie ordinate per timestamp (più recente prima):');
    for (int i = 0; i < sortedSeries.length && i < 10; i++) {  // Log solo prime 10 per performance
      final s = sortedSeries[i];
      print('[CONSOLE]   $i: Serie ${s.serieNumber ?? "?"} - ${s.peso}kg x ${s.ripetizioni} (${s.timestamp})');
    }

    // 🔧 FIX: Raggruppa per data (primi 10 caratteri del timestamp)
    final Map<String, List<CompletedSeriesData>> groupedByDate = {};

    for (final serie in sortedSeries) {
      final timestamp = serie.timestamp;
      // Prendi i primi 10 caratteri se disponibili (YYYY-MM-DD), altrimenti usa tutto
      final dateKey = timestamp.length >= 10 ? timestamp.substring(0, 10) : timestamp;

      groupedByDate.putIfAbsent(dateKey, () => []);
      groupedByDate[dateKey]!.add(serie);
    }

    // 🔧 FIX: Converti in lista e ordina per data (più recente prima)
    final sessionGroups = groupedByDate.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));  // Più recente prima

    final orderedSessionGroups = sessionGroups.map((entry) => entry.value).toList();

    print('[CONSOLE]📅 Raggruppamento finale: ${orderedSessionGroups.length} sessioni');
    for (int index = 0; index < orderedSessionGroups.length; index++) {
      final session = orderedSessionGroups[index];
      final dateKey = sessionGroups[index].key;
      print('[CONSOLE]   Sessione $index ($dateKey): ${session.length} serie');
    }

    // 🔧 FIX: Se abbiamo solo una sessione ma molte serie, prova un raggruppamento alternativo
    if (orderedSessionGroups.length == 1 && series.length >= 6) {
      print('[CONSOLE]⚠️ Tentativo raggruppamento alternativo per serie multiple...');

      final List<List<CompletedSeriesData>> alternativeGroups = [];
      const seriesPerSession = 3;

      for (int i = 0; i < sortedSeries.length; i += seriesPerSession) {
        final sessionEnd = (i + seriesPerSession).clamp(0, sortedSeries.length);
        final sessionSeries = sortedSeries.sublist(i, sessionEnd);
        if (sessionSeries.isNotEmpty) {
          alternativeGroups.add(sessionSeries);
        }
      }

      print('[CONSOLE]📅 Raggruppamento alternativo: ${alternativeGroups.length} sessioni simulate');
      return alternativeGroups;
    }

    return orderedSessionGroups;
  }

  /// Prova a rilevare plateau con dati limitati
  PlateauInfo? _tryDetectWithLimitedData(
      int exerciseId,
      String exerciseName,
      double currentWeight,
      int currentReps,
      List<CompletedSeriesData> exerciseHistory,
      ) {
    print('[CONSOLE]⚠️ === RILEVAMENTO CON DATI LIMITATI ===');

    // Se abbiamo almeno una serie storica, confrontala con i valori correnti
    if (exerciseHistory.isNotEmpty) {
      final lastSeries = exerciseHistory.last;
      final weightMatch = (currentWeight - lastSeries.peso).abs() <= config.weightTolerance;
      final repsMatch = (currentReps - lastSeries.ripetizioni).abs() <= config.repsTolerance;

      print('[CONSOLE]Confronto con ultima serie: peso match=$weightMatch, reps match=$repsMatch');
      print('[CONSOLE]   Corrente: ${currentWeight}kg x $currentReps');
      print('[CONSOLE]   Storico: ${lastSeries.peso}kg x ${lastSeries.ripetizioni}');

      if (weightMatch && repsMatch) {
        print('[CONSOLE]🚨 PLATEAU LIMITATO rilevato per esercizio $exerciseId ($exerciseName)!');

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

    print('[CONSOLE]✅ Nessun plateau rilevato con dati limitati');
    return null;
  }

  /// Rileva plateau "simulato" per testing quando non ci sono dati storici
  PlateauInfo? _checkSimulatedPlateau(
      int exerciseId,
      String exerciseName,
      double currentWeight,
      int currentReps,
      ) {
    if (!config.enableSimulatedPlateau) {
      print('[CONSOLE]🚫 Plateau simulato disabilitato in configurazione');
      return null;
    }

    print('[CONSOLE]🧪 === TEST PLATEAU SIMULATO ===');

    // 🔧 FIX: Logica migliorata per plateau simulato
    final isTypicalPlateauWeight = currentWeight > 0 && (
        currentWeight % 5 == 0 || // Pesi multipli di 5
            currentWeight % 2.5 == 0   // Pesi multipli di 2.5
    );

    final isTypicalePlateauReps = currentReps >= 6 && currentReps <= 15; // Range tipico

    print('[CONSOLE]Test plateau simulato:');
    print('[CONSOLE]   Peso tipico: $isTypicalPlateauWeight (${currentWeight}kg)');
    print('[CONSOLE]   Reps tipiche: $isTypicalePlateauReps ($currentReps reps)');
    print('[CONSOLE]   ID pari: ${exerciseId % 2 == 0}');

    // 🔧 FIX: Plateau simulato su esercizi con ID pari
    if (isTypicalPlateauWeight && isTypicalePlateauReps && exerciseId % 2 == 0) {
      print('[CONSOLE]🚨 PLATEAU SIMULATO rilevato per esercizio $exerciseId ($exerciseName) (per testing)!');

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

    // 🔧 FIX: Plateau specifico per superset/circuit (testing avanzato)
    final supersetKeywords = ['chest', 'press', 'fly', 'curl', 'extension', 'raise', 'squat', 'lunge'];
    final exerciseNameLower = exerciseName.toLowerCase();
    final hasKeyword = supersetKeywords.any((keyword) => exerciseNameLower.contains(keyword));

    if (hasKeyword && currentWeight >= 10 && exerciseId % 3 == 1) {
      print('[CONSOLE]🚨 PLATEAU SIMULATO SUPERSET rilevato per $exerciseId ($exerciseName) (per testing superset/circuit)!');

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

    print('[CONSOLE]✅ Nessun plateau simulato per questo esercizio');
    return null;
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
      totalExercisesAnalyzed: allPlateaus.length,
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