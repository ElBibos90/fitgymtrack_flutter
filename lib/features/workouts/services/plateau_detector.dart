// lib/features/workouts/services/plateau_detector.dart

import '../models/plateau_models.dart';
import '../models/active_workout_models.dart';
import '../models/workout_plan_models.dart';

/// 🎯 STEP 6: Servizio per il rilevamento plateau
/// 🔧 FIX CRITICO: Logica serie-per-serie ESATTA + confronto IDENTICO (tolleranza ZERO)
/// 🔧 FIX 2: Evita trigger multipli con cache intelligente
/// 🔧 FIX 3: SEMPRE confronto serie-per-serie, anche con dati limitati
class PlateauDetector {
  final PlateauDetectionConfig config;

  // 🔧 FIX 2: Cache per evitare analisi multiple
  final Map<String, PlateauInfo?> _analysisCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  // 🔧 FIX 2: Durata cache (5 minuti)
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  PlateauDetector({required this.config});

  /// 🔧 FIX 2: Genera chiave cache per esercizio
  String _getCacheKey(int exerciseId, double weight, int reps) {
    return '${exerciseId}_${weight.toStringAsFixed(1)}_$reps';
  }

  /// 🔧 FIX 2: Controlla se cache è valida
  bool _isCacheValid(String cacheKey) {
    final timestamp = _cacheTimestamps[cacheKey];
    if (timestamp == null) return false;

    final age = DateTime.now().difference(timestamp);
    return age < _cacheValidDuration;
  }

  /// 🔧 FIX 2: Salva risultato in cache
  void _cacheResult(String cacheKey, PlateauInfo? result) {
    _analysisCache[cacheKey] = result;
    _cacheTimestamps[cacheKey] = DateTime.now();
    //print('[CONSOLE] [plateau_detector]🔧 [CACHE] Cached result for $cacheKey: ${result != null ? 'PLATEAU' : 'NO_PLATEAU'}');
  }

  /// Rileva plateau per un singolo esercizio CON CACHE ANTI-SPAM
  Future<PlateauInfo?> detectPlateau({
    required int exerciseId,
    required String exerciseName,
    required double currentWeight,
    required int currentReps,
    required Map<int, List<CompletedSeriesData>> historicData,
  }) async {
    //print('[CONSOLE] [plateau_detector]=== 🎯 ANALISI PLATEAU ESERCIZIO $exerciseId ($exerciseName) ===');

    // 🔧 FIX 2: Controlla cache prima di analizzare
    final cacheKey = _getCacheKey(exerciseId, currentWeight, currentReps);
    if (_isCacheValid(cacheKey)) {
      final cachedResult = _analysisCache[cacheKey];
      //print('[CONSOLE] [plateau_detector]🔧 [CACHE HIT] Using cached result for $cacheKey');
      return cachedResult;
    }

    //print('[CONSOLE] [plateau_detector]🔧 [CACHE MISS] Proceeding with fresh analysis for $cacheKey');
    //print('[CONSOLE] [plateau_detector]Peso corrente: $currentWeight, Reps correnti: $currentReps');
    //print('[CONSOLE] [plateau_detector]Dati storici disponibili: ${historicData[exerciseId]?.length ?? 0} serie');

    final exerciseHistory = historicData[exerciseId];

    // Se non ci sono dati storici, prova plateau simulato per test
    if (exerciseHistory == null || exerciseHistory.isEmpty) {
      //print('[CONSOLE] [plateau_detector]⚠️ Nessun dato storico - controllo plateau simulato');
      final result = _checkSimulatedPlateau(exerciseId, exerciseName, currentWeight, currentReps);
      _cacheResult(cacheKey, result);
      return result;
    }

    // 🔧 FIX CRITICO: Raggruppa le serie per sessione di allenamento (per timestamp/data)
    final sessionGroups = _groupSeriesBySession(exerciseHistory);
    //print('[CONSOLE] [plateau_detector]📅 Sessioni raggruppate: ${sessionGroups.length}');

    // 🔧 FIX CRITICO: SEMPRE confronto serie-per-serie, anche con dati limitati
    if (sessionGroups.length < config.minSessionsForPlateau) {
      //print('[CONSOLE] [plateau_detector]⚠️ Sessioni insufficienti: ${sessionGroups.length} < ${config.minSessionsForPlateau}');
      final result = _tryDetectWithLimitedDataSeriesBySeries(
          exerciseId,
          exerciseName,
          currentWeight,
          currentReps,
          sessionGroups
      );
      _cacheResult(cacheKey, result);
      return result;
    }

    // 🔧 FIX: Prendi le ultime N sessioni per confronto serie per serie
    final recentSessions = sessionGroups.take(config.minSessionsForPlateau).toList();
    //print('[CONSOLE] [plateau_detector]🔍 Analizzando le ultime ${config.minSessionsForPlateau} sessioni per confronto serie per serie');

    // 📊 DEBUG: Log dettagliato delle sessioni
    for (int i = 0; i < recentSessions.length; i++) {
      final session = recentSessions[i];
      //print('[CONSOLE] [plateau_detector]📅 Sessione $i (${session.length} serie):');
      for (final series in session) {
        //print('[CONSOLE] [plateau_detector]   Serie ${series.serieNumber ?? "?"}: ${series.peso}kg x ${series.ripetizioni} (timestamp: ${series.timestamp})');
      }
    }

    final result = _detectPlateauSeriesBySeries(
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      currentWeight: currentWeight,
      currentReps: currentReps,
      recentSessions: recentSessions,
      sessionsCount: config.minSessionsForPlateau,
    );

    // 🔧 FIX 2: Salva risultato in cache
    _cacheResult(cacheKey, result);
    return result;
  }

  /// 🔧 FIX CRITICO: Rilevamento con dati limitati MA SEMPRE serie-per-serie
  PlateauInfo? _tryDetectWithLimitedDataSeriesBySeries(
      int exerciseId,
      String exerciseName,
      double currentWeight,
      int currentReps,
      List<List<CompletedSeriesData>> sessionGroups,
      ) {
    //print('[CONSOLE] [plateau_detector]⚠️ === RILEVAMENTO CON DATI LIMITATI MA SERIE-PER-SERIE ===');

    if (sessionGroups.isEmpty) {
      //print('[CONSOLE] [plateau_detector]❌ Nessuna sessione disponibile');
      return null;
    }

    // 🔧 FIX CRITICO: Organizza le serie per numero anche con dati limitati
    final Map<int, List<CompletedSeriesData>> seriesByNumber = {};

    for (int sessionIndex = 0; sessionIndex < sessionGroups.length; sessionIndex++) {
      final session = sessionGroups[sessionIndex];
      //print('[CONSOLE] [plateau_detector]📅 Processando Sessione $sessionIndex: ${session.length} serie');

      for (final series in session) {
        final serieNumber = series.serieNumber ?? 1;
        seriesByNumber.putIfAbsent(serieNumber, () => []);
        seriesByNumber[serieNumber]!.add(series);
        //print('[CONSOLE] [plateau_detector]   ➕ Serie $serieNumber: ${series.peso}kg x ${series.ripetizioni} → aggiunta al gruppo');
      }
    }

    //print('[CONSOLE] [plateau_detector]📊 Organizzazione finale per numero di serie (dati limitati):');
    seriesByNumber.forEach((serieNumber, seriesList) {
      //print('[CONSOLE] [plateau_detector]📍 Serie $serieNumber: ${seriesList.length} occorrenze nelle sessioni');
    });

    // 🔧 FIX CRITICO: Controlla se almeno la serie 1 ha valori identici
    final serie1List = seriesByNumber[1];
    if (serie1List != null && serie1List.isNotEmpty) {
      final firstSeries = serie1List.first;

      // 🔧 FIX CRITICO: Confronto ESATTO (tolleranza ZERO)
      final weightMatch = (currentWeight - firstSeries.peso).abs() <= config.weightTolerance;
      final repsMatch = (currentReps - firstSeries.ripetizioni).abs() <= config.repsTolerance;

      //print('[CONSOLE] [plateau_detector]🔍 Confronto serie 1 con valori correnti:');
      //print('[CONSOLE] [plateau_detector]   Corrente: ${currentWeight}kg x $currentReps');
      //print('[CONSOLE] [plateau_detector]   Storico: ${firstSeries.peso}kg x ${firstSeries.ripetizioni}');
      //print('[CONSOLE] [plateau_detector]   Peso identico: $weightMatch, Reps identiche: $repsMatch');
      //print('[CONSOLE] [plateau_detector]   Tolleranze: peso=${config.weightTolerance}, reps=${config.repsTolerance}');

      if (weightMatch && repsMatch) {
        //print('[CONSOLE] [plateau_detector]🚨 PLATEAU LIMITATO rilevato per esercizio $exerciseId ($exerciseName)!');

        return PlateauInfo(
          exerciseId: exerciseId,
          exerciseName: exerciseName,
          plateauType: _determinePlateauType(currentWeight, currentReps),
          sessionsInPlateau: sessionGroups.length,
          currentWeight: currentWeight,
          currentReps: currentReps,
          detectedAt: DateTime.now(),
          suggestions: _generateProgressionSuggestions(
            currentWeight: currentWeight,
            currentReps: currentReps,
            exerciseHistory: sessionGroups.expand((x) => x).toList(),
          ),
        );
      }
    }

    //print('[CONSOLE] [plateau_detector]✅ Nessun plateau rilevato con dati limitati (serie-per-serie)');
    return null;
  }

  /// 🔧 FIX: Confronto serie per serie PERFEZIONATO + ESATTO
  PlateauInfo? _detectPlateauSeriesBySeries({
    required int exerciseId,
    required String exerciseName,
    required double currentWeight,
    required int currentReps,
    required List<List<CompletedSeriesData>> recentSessions,
    required int sessionsCount,
  }) {
    //print('[CONSOLE] [plateau_detector]🔍 === CONFRONTO SERIE PER SERIE ESATTO ===');

    // 🔧 FIX CRITICO: Organizza le serie per numero di serie (1, 2, 3, ecc.)
    final Map<int, List<CompletedSeriesData>> seriesByNumber = {};

    for (int sessionIndex = 0; sessionIndex < recentSessions.length; sessionIndex++) {
      final session = recentSessions[sessionIndex];
      //print('[CONSOLE] [plateau_detector]📅 Processando Sessione $sessionIndex: ${session.length} serie');

      for (final series in session) {
        final serieNumber = series.serieNumber ?? 1;
        seriesByNumber.putIfAbsent(serieNumber, () => []);
        seriesByNumber[serieNumber]!.add(series);
        //print('[CONSOLE] [plateau_detector]   ➕ Serie $serieNumber: ${series.peso}kg x ${series.ripetizioni} → aggiunta al gruppo');
      }
    }

    //print('[CONSOLE] [plateau_detector]📊 Organizzazione finale per numero di serie:');
    seriesByNumber.forEach((serieNumber, seriesList) {
      //print('[CONSOLE] [plateau_detector]📍 Serie $serieNumber: ${seriesList.length} occorrenze nelle sessioni');
      for (int i = 0; i < seriesList.length; i++) {
        final series = seriesList[i];
        //print('[CONSOLE] [plateau_detector]    Occorrenza $i: ${series.peso}kg x ${series.ripetizioni}');
      }
    });

    // 🔧 FIX CRITICO: Controlla plateau per ogni numero di serie
    int plateauDetectedCount = 0;
    final List<int> plateauSeriesNumbers = [];
    final int totalSeriesChecked = seriesByNumber.length;

    for (final entry in seriesByNumber.entries) {
      final serieNumber = entry.key;
      final seriesList = entry.value;

      //print('[CONSOLE] [plateau_detector]🔍 === CONTROLLO PLATEAU SERIE $serieNumber ===');

      // ✅ LOGICA CORRETTA: Verifica se questa serie appare in tutte le sessioni richieste
      if (seriesList.length >= sessionsCount) {
        // 🔧 FIX: Prendi le ultime N occorrenze (ordinate per sessione più recente)
        final recentSeriesForThisNumber = seriesList.take(sessionsCount).toList();

        //print('[CONSOLE] [plateau_detector]📋 Serie $serieNumber - Controllo ${recentSeriesForThisNumber.length} occorrenze:');
        for (int index = 0; index < recentSeriesForThisNumber.length; index++) {
          final series = recentSeriesForThisNumber[index];
          //print('[CONSOLE] [plateau_detector]   Sessione $index: ${series.peso}kg x ${series.ripetizioni}');
        }

        // ✅ LOGICA PLATEAU ESATTA: Verifica se peso e ripetizioni sono IDENTICI
        final firstSeries = recentSeriesForThisNumber.first;
        final isWeightConstant = recentSeriesForThisNumber.every((series) =>
        (series.peso - firstSeries.peso).abs() <= config.weightTolerance);
        final areRepsConstant = recentSeriesForThisNumber.every((series) =>
        (series.ripetizioni - firstSeries.ripetizioni).abs() <= config.repsTolerance);

        //print('[CONSOLE] [plateau_detector]   🔍 Serie $serieNumber: peso identico=$isWeightConstant, reps identiche=$areRepsConstant');
        //print('[CONSOLE] [plateau_detector]   🔍 Tolleranze applicate: peso=${config.weightTolerance}, reps=${config.repsTolerance}');

        // 🔧 FIX CRITICO: Per la serie 1, controlla anche i valori correnti dell'allenamento attivo
        bool currentMatchesPattern = true;
        if (serieNumber == 1) {
          currentMatchesPattern =
              (currentWeight - firstSeries.peso).abs() <= config.weightTolerance &&
                  (currentReps - firstSeries.ripetizioni).abs() <= config.repsTolerance;

          //print('[CONSOLE] [plateau_detector]   🎯 Serie $serieNumber (CORRENTE): valori attuali corrispondono=$currentMatchesPattern');
          //print('[CONSOLE] [plateau_detector]       Peso attuale: $currentWeight vs storico: ${firstSeries.peso} (diff: ${(currentWeight - firstSeries.peso).abs()})');
          //print('[CONSOLE] [plateau_detector]       Reps attuali: $currentReps vs storico: ${firstSeries.ripetizioni} (diff: ${(currentReps - firstSeries.ripetizioni).abs()})');
        }

        // ✅ PLATEAU RILEVATO se tutti i criteri sono soddisfatti
        final isPlateauForThisSeries = isWeightConstant && areRepsConstant &&
            (serieNumber == 1 ? currentMatchesPattern : true);

        if (isPlateauForThisSeries) {
          plateauDetectedCount++;
          plateauSeriesNumbers.add(serieNumber);
          //print('[CONSOLE] [plateau_detector]🚨 PLATEAU CONFERMATO per Serie $serieNumber!');
        } else {
          //print('[CONSOLE] [plateau_detector]✅ Serie $serieNumber: NO plateau (criteri non soddisfatti)');
        }
      } else {
        //print('[CONSOLE] [plateau_detector]⏭️ Serie $serieNumber: dati insufficienti (${seriesList.length}/$sessionsCount sessioni)');
      }
    }

    //print('[CONSOLE] [plateau_detector]📈 === RISULTATO FINALE ESATTO ===');
    //print('[CONSOLE] [plateau_detector]Serie in plateau: $plateauDetectedCount/$totalSeriesChecked');
    //print('[CONSOLE] [plateau_detector]Serie con plateau: $plateauSeriesNumbers');

    // 🔧 FIX: Soglia plateau dinamica più intelligente
    int plateauThreshold;
    if (totalSeriesChecked == 1) {
      plateauThreshold = 1; // Se c'è solo 1 serie, deve essere in plateau
    } else if (totalSeriesChecked <= 3) {
      plateauThreshold = (totalSeriesChecked / 2).ceil(); // 50% per 2-3 serie
    } else {
      plateauThreshold = (totalSeriesChecked * 0.6).ceil(); // 60% per 4+ serie
    }

    //print('[CONSOLE] [plateau_detector]🎯 Soglia plateau dinamica: $plateauThreshold serie (su $totalSeriesChecked)');

    if (plateauDetectedCount >= plateauThreshold) {
      //print('[CONSOLE] [plateau_detector]🚨 === PLATEAU CONFERMATO PER ESERCIZIO $exerciseId ($exerciseName) ===');
      //print('[CONSOLE] [plateau_detector]   Serie in plateau: $plateauDetectedCount/$totalSeriesChecked (soglia: $plateauThreshold)');

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

    //print('[CONSOLE] [plateau_detector]✅ Nessun plateau significativo rilevato per $exerciseName');
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
    //print('[CONSOLE] [plateau_detector]🔍 === ANALISI PLATEAU GRUPPO: $groupName ($groupType) ===');

    final List<PlateauInfo> groupPlateaus = [];

    for (final exercise in exercises) {
      final exerciseId = exercise.schedaEsercizioId ?? exercise.id;
      final weight = currentWeights[exerciseId] ?? exercise.peso;
      final reps = currentReps[exerciseId] ?? exercise.ripetizioni;

      //print('[CONSOLE] [plateau_detector]🔍 Analizzando esercizio: ${exercise.nome} (ID: $exerciseId)');

      final plateau = await detectPlateau(
        exerciseId: exerciseId,
        exerciseName: exercise.nome,
        currentWeight: weight,
        currentReps: reps,
        historicData: historicData,
      );

      if (plateau != null) {
        groupPlateaus.add(plateau);
        //print('[CONSOLE] [plateau_detector]🚨 Plateau rilevato per ${exercise.nome}');
      } else {
        //print('[CONSOLE] [plateau_detector]✅ Nessun plateau per ${exercise.nome}');
      }
    }

    final analysis = GroupPlateauAnalysis(
      groupName: groupName,
      groupType: groupType,
      plateauList: groupPlateaus,
      totalExercises: exercises.length,
      analyzedAt: DateTime.now(),
    );

    //print('[CONSOLE] [plateau_detector]📊 RISULTATO GRUPPO: ${analysis.exercisesInPlateau}/${analysis.totalExercises} esercizi in plateau (${analysis.plateauPercentage.toStringAsFixed(1)}%)');

    return analysis;
  }

  /// 🔧 FIX: Raggruppa le serie per sessione di allenamento più intelligente + MIGLIORATO
  List<List<CompletedSeriesData>> _groupSeriesBySession(List<CompletedSeriesData> series) {
    //print('[CONSOLE] [plateau_detector]📅 === RAGGRUPPAMENTO SERIE PER SESSIONE MIGLIORATO ===');
    //print('[CONSOLE] [plateau_detector]Raggruppamento ${series.length} serie per sessione...');

    if (series.isEmpty) return [];

    // 🔧 FIX: Ordina le serie per timestamp (più recente prima)
    final sortedSeries = List<CompletedSeriesData>.from(series);
    sortedSeries.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    //print('[CONSOLE] [plateau_detector]📊 Serie ordinate per timestamp (più recente prima):');
    for (int i = 0; i < sortedSeries.length && i < 10; i++) {  // Log solo prime 10 per performance
      final s = sortedSeries[i];
      //print('[CONSOLE] [plateau_detector]   $i: Serie ${s.serieNumber ?? "?"} - ${s.peso}kg x ${s.ripetizioni} (${s.timestamp})');
    }

    // 🔧 FIX MIGLIORATO: Raggruppa per data (primi 10 caratteri del timestamp)
    final Map<String, List<CompletedSeriesData>> groupedByDate = {};

    for (final serie in sortedSeries) {
      final timestamp = serie.timestamp;
      // Prendi i primi 10 caratteri se disponibili (YYYY-MM-DD), altrimenti usa tutto
      final dateKey = timestamp.length >= 10 ? timestamp.substring(0, 10) : timestamp;

      groupedByDate.putIfAbsent(dateKey, () => []);
      groupedByDate[dateKey]!.add(serie);
    }

    // 🔧 FIX MIGLIORATO: Converti in lista ordinata per data (più recente prima)
    final sortedDates = groupedByDate.keys.toList()..sort((a, b) => b.compareTo(a));
    final sessions = sortedDates.map((date) => groupedByDate[date]!).toList();

    //print('[CONSOLE] [plateau_detector]📅 Raggruppamento finale: ${sessions.length} sessioni');
    for (int i = 0; i < sessions.length && i < 5; i++) {  // Log solo prime 5 sessioni
      final session = sessions[i];
      final date = sortedDates[i];
      //print('[CONSOLE] [plateau_detector]   Sessione $i ($date): ${session.length} serie');
    }

    return sessions;
  }

  /// Rileva plateau "simulato" per testing quando non ci sono dati storici + MIGLIORATO
  PlateauInfo? _checkSimulatedPlateau(
      int exerciseId,
      String exerciseName,
      double currentWeight,
      int currentReps,
      ) {
    if (!config.enableSimulatedPlateau) {
      //print('[CONSOLE] [plateau_detector]🚫 Plateau simulato disabilitato in configurazione');
      return null;
    }

    //print('[CONSOLE] [plateau_detector]🧪 === TEST PLATEAU SIMULATO MIGLIORATO ===');

    // 🔧 FIX MIGLIORATO: Logica più realistica per plateau simulato
    final isTypicalPlateauWeight = currentWeight > 0 && (
        currentWeight % 5 == 0 || // Pesi multipli di 5
            currentWeight % 2.5 == 0   // Pesi multipli di 2.5
    );

    final isTypicalePlateauReps = currentReps >= 6 && currentReps <= 15; // Range tipico

    // 🔧 MIGLIORAMENTO: Pattern più realistici
    final hasRealisticValues = currentWeight >= 5.0 && currentWeight <= 200.0 &&
        currentReps >= 3 && currentReps <= 20;

    //print('[CONSOLE] [plateau_detector]Test plateau simulato migliorato:');
    //print('[CONSOLE] [plateau_detector]   Peso tipico: $isTypicalPlateauWeight (${currentWeight}kg)');
    //print('[CONSOLE] [plateau_detector]   Reps tipiche: $isTypicalePlateauReps ($currentReps reps)');
    //print('[CONSOLE] [plateau_detector]   Valori realistici: $hasRealisticValues');
    //print('[CONSOLE] [plateau_detector]   ID check: ${exerciseId % 3 == 0}'); // Cambiato da % 2 a % 3

    // 🔧 FIX MIGLIORATO: Plateau simulato su esercizi con ID multiplo di 3 (meno frequente)
    if (isTypicalPlateauWeight && isTypicalePlateauReps && hasRealisticValues && exerciseId % 3 == 0) {
      //print('[CONSOLE] [plateau_detector]🚨 PLATEAU SIMULATO rilevato per esercizio $exerciseId ($exerciseName) (per testing)!');

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

    // 🔧 FIX MIGLIORATO: Plateau specifico per superset/circuit (testing avanzato) - meno aggressivo
    final supersetKeywords = ['chest', 'press', 'fly', 'curl', 'extension', 'raise', 'squat', 'lunge'];
    final exerciseNameLower = exerciseName.toLowerCase();
    final hasKeyword = supersetKeywords.any((keyword) => exerciseNameLower.contains(keyword));

    if (hasKeyword && currentWeight >= 10 && exerciseId % 5 == 1) { // Cambiato da % 3 a % 5
      //print('[CONSOLE] [plateau_detector]🚨 PLATEAU SIMULATO SUPERSET rilevato per $exerciseId ($exerciseName) (per testing superset/circuit)!');

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

    //print('[CONSOLE] [plateau_detector]✅ Nessun plateau simulato per questo esercizio');
    return null;
  }

  /// Determina il tipo di plateau (unchanged)
  PlateauType _determinePlateauType(double weight, int reps) {
    if (weight < 10) return PlateauType.lightWeight;
    if (weight > 100) return PlateauType.heavyWeight;
    if (reps < 5) return PlateauType.lowReps;
    if (reps > 15) return PlateauType.highReps;
    return PlateauType.moderate;
  }

  /// Genera suggerimenti per la progressione (unchanged)
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

    // Suggerisci tecniche avanzate se appropriato
    if (currentWeight > 20 && currentReps >= 8) {
      suggestions.add(
        ProgressionSuggestion(
          type: SuggestionType.advancedTechnique,
          description: 'Considera tecniche avanzate come drop set, rest-pause o super set',
          newWeight: currentWeight,
          newReps: currentReps,
          confidence: 0.6,
        ),
      );
    }

    // Ordina per confidenza decrescente
    suggestions.sort((a, b) => b.confidence.compareTo(a.confidence));
    return suggestions;
  }

  /// Calcola la confidenza per l'aumento di peso
  double _calculateWeightIncreaseConfidence(double currentWeight, List<CompletedSeriesData> history) {
    if (history.isEmpty) return 0.7;

    // Controlla se negli ultimi allenamenti c'è stata progressione di peso
    final recentWeights = history.take(5).map((s) => s.peso).toList();
    if (recentWeights.length >= 2) {
      final hasProgression = recentWeights.first > recentWeights.last;
      return hasProgression ? 0.8 : 0.6;
    }

    return currentWeight < 50 ? 0.8 : 0.6; // Più fiducia per pesi leggeri
  }

  /// Calcola la confidenza per l'aumento di ripetizioni
  double _calculateRepsIncreaseConfidence(int currentReps, List<CompletedSeriesData> history) {
    if (history.isEmpty) return 0.6;

    // Preferisci aumento reps se siamo in range medio
    if (currentReps >= 8 && currentReps <= 12) return 0.8;
    if (currentReps < 5) return 0.4; // Bassa confidenza per poche reps
    if (currentReps > 15) return 0.3; // Bassa confidenza per molte reps

    return 0.6;
  }

  /// Calcola statistiche sui plateau rilevati
  PlateauStatistics calculateStatistics(List<PlateauInfo> plateaus) {
    if (plateaus.isEmpty) {
      return PlateauStatistics(
        totalExercisesAnalyzed: 0,
        totalPlateauDetected: 0,
        plateauByType: {},
        suggestionsByType: {},
        lastAnalysisAt: DateTime.now(),
        averageSessionsInPlateau: 0.0,
      );
    }

    // Raggruppa per tipo
    final Map<PlateauType, int> plateauByType = {};
    final Map<SuggestionType, int> suggestionsByType = {};

    for (final plateau in plateaus) {
      plateauByType[plateau.plateauType] = (plateauByType[plateau.plateauType] ?? 0) + 1;

      for (final suggestion in plateau.suggestions) {
        suggestionsByType[suggestion.type] = (suggestionsByType[suggestion.type] ?? 0) + 1;
      }
    }

    // Calcola media sessioni in plateau
    final avgSessions = plateaus.map((p) => p.sessionsInPlateau).reduce((a, b) => a + b) / plateaus.length;

    return PlateauStatistics(
      totalExercisesAnalyzed: plateaus.length,
      totalPlateauDetected: plateaus.length,
      plateauByType: plateauByType,
      suggestionsByType: suggestionsByType,
      lastAnalysisAt: DateTime.now(),
      averageSessionsInPlateau: avgSessions,
    );
  }
}