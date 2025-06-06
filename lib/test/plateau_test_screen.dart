// lib/test/plateau_test_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// 🎯 STEP 6: Test screen per il sistema plateau detection
import '../features/workouts/bloc/plateau_bloc.dart';
import '../features/workouts/models/plateau_models.dart';
import '../features/workouts/models/workout_plan_models.dart';
import '../shared/widgets/plateau_widgets.dart';
import '../core/di/dependency_injection_plateau.dart';

/// 🎯 STEP 6: Schermata di test per il sistema plateau detection
/// Permette di testare tutte le funzionalità del sistema plateau
class PlateauTestScreen extends StatefulWidget {
  const PlateauTestScreen({super.key});

  @override
  State<PlateauTestScreen> createState() => _PlateauTestScreenState();
}

class _PlateauTestScreenState extends State<PlateauTestScreen>
    with TickerProviderStateMixin {

  late PlateauBloc _plateauBloc;
  late TabController _tabController;

  // Test data
  final List<WorkoutExercise> _testExercises = [
    createWorkoutExercise(
      id: 1,
      schedaEsercizioId: 101,
      nome: 'Bench Press',
      gruppoMuscolare: 'Petto',
      setType: 'normal',
      peso: 80.0,
      ripetizioni: 10,
      serie: 3,
    ),
    createWorkoutExercise(
      id: 2,
      schedaEsercizioId: 102,
      nome: 'Incline Dumbbell Press',
      gruppoMuscolare: 'Petto',
      setType: 'superset',
      peso: 30.0,
      ripetizioni: 12,
      serie: 3,
      linkedToPrevious: false,
    ),
    createWorkoutExercise(
      id: 3,
      schedaEsercizioId: 103,
      nome: 'Incline Dumbbell Fly',
      gruppoMuscolare: 'Petto',
      setType: 'superset',
      peso: 20.0,
      ripetizioni: 15,
      serie: 3,
      linkedToPrevious: true,
    ),
    createWorkoutExercise(
      id: 4,
      schedaEsercizioId: 104,
      nome: 'Squat',
      gruppoMuscolare: 'Gambe',
      setType: 'normal',
      peso: 100.0,
      ripetizioni: 8,
      serie: 4,
    ),
  ];

  // Mock weights and reps
  Map<int, double> _currentWeights = {};
  Map<int, int> _currentReps = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _plateauBloc = context.read<PlateauBloc>();
    _initializeTestData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeTestData() {
    for (final exercise in _testExercises) {
      final exerciseId = exercise.schedaEsercizioId ?? exercise.id;
      _currentWeights[exerciseId] = exercise.peso;
      _currentReps[exerciseId] = exercise.ripetizioni;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎯 Plateau Detection Test'),
        backgroundColor: const Color(0xFFFF5722),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Single', icon: Icon(Icons.fitness_center, size: 16)),
            Tab(text: 'Group', icon: Icon(Icons.group_work, size: 16)),
            Tab(text: 'Results', icon: Icon(Icons.analytics, size: 16)),
            Tab(text: 'Config', icon: Icon(Icons.settings, size: 16)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSingleAnalysisTab(),
          _buildGroupAnalysisTab(),
          _buildResultsTab(),
          _buildConfigTab(),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 1: SINGLE EXERCISE ANALYSIS
  // ============================================================================

  Widget _buildSingleAnalysisTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🎯 Test Analisi Singoli Esercizi',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFF5722),
            ),
          ),

          SizedBox(height: 8.h),

          Text(
            'Testa il rilevamento plateau per singoli esercizi. Modifica i valori e avvia l\'analisi.',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
          ),

          SizedBox(height: 24.h),

          // Exercise cards
          ..._testExercises.map((exercise) => _buildExerciseTestCard(exercise)),

          SizedBox(height: 24.h),

          // System status
          _buildSystemStatusCard(),
        ],
      ),
    );
  }

  Widget _buildExerciseTestCard(WorkoutExercise exercise) {
    final exerciseId = exercise.schedaEsercizioId ?? exercise.id;
    final currentWeight = _currentWeights[exerciseId] ?? exercise.peso;
    final currentReps = _currentReps[exerciseId] ?? exercise.ripetizioni;

    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.nome,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'ID: $exerciseId | ${exercise.gruppoMuscolare} | ${exercise.setType}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (exercise.setType != 'normal')
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: exercise.setType == 'superset'
                          ? Colors.purple.withOpacity(0.2)
                          : Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      exercise.setType.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        color: exercise.setType == 'superset'
                            ? Colors.purple
                            : Colors.orange,
                      ),
                    ),
                  ),
              ],
            ),

            SizedBox(height: 16.h),

            // Current values editors
            Row(
              children: [
                // Weight
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Peso (kg)',
                        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 4.h),
                      TextFormField(
                        initialValue: currentWeight.toStringAsFixed(1),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                        ),
                        onChanged: (value) {
                          final weight = double.tryParse(value);
                          if (weight != null) {
                            setState(() {
                              _currentWeights[exerciseId] = weight;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 16.w),

                // Reps
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ripetizioni',
                        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 4.h),
                      TextFormField(
                        initialValue: currentReps.toString(),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                        ),
                        onChanged: (value) {
                          final reps = int.tryParse(value);
                          if (reps != null) {
                            setState(() {
                              _currentReps[exerciseId] = reps;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 16.w),

                // Analyze button
                ElevatedButton(
                  onPressed: () => _analyzeSingleExercise(exercise),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5722),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  ),
                  child: Text(
                    'Analizza',
                    style: TextStyle(fontSize: 12.sp),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _analyzeSingleExercise(WorkoutExercise exercise) {
    final exerciseId = exercise.schedaEsercizioId ?? exercise.id;
    final weight = _currentWeights[exerciseId] ?? exercise.peso;
    final reps = _currentReps[exerciseId] ?? exercise.ripetizioni;

    debugPrint("🎯 [TEST] Analyzing single exercise: ${exercise.nome} - ${weight}kg x $reps reps");

    _plateauBloc.analyzeExercisePlateau(exerciseId, exercise.nome, weight, reps);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🔍 Analizzando ${exercise.nome}...'),
        backgroundColor: const Color(0xFFFF5722),
      ),
    );
  }

  // ============================================================================
  // TAB 2: GROUP ANALYSIS
  // ============================================================================

  Widget _buildGroupAnalysisTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🏋️ Test Analisi Gruppi',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFF5722),
            ),
          ),

          SizedBox(height: 8.h),

          Text(
            'Testa il rilevamento plateau per gruppi di esercizi (superset/circuit).',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
          ),

          SizedBox(height: 24.h),

          // Group test buttons
          _buildGroupTestCard(
            'Normale - Bench Press',
            'Test per esercizio singolo',
            [_testExercises[0]],
            Colors.blue,
          ),

          SizedBox(height: 16.h),

          _buildGroupTestCard(
            'Superset - Petto',
            'Test per superset di 2 esercizi',
            [_testExercises[1], _testExercises[2]],
            Colors.purple,
          ),

          SizedBox(height: 16.h),

          _buildGroupTestCard(
            'Tutti gli esercizi',
            'Test completo di tutti gli esercizi',
            _testExercises,
            Colors.green,
          ),

          SizedBox(height: 24.h),

          // Quick actions
          _buildQuickActionsCard(),
        ],
      ),
    );
  }

  Widget _buildGroupTestCard(String title, String description, List<WorkoutExercise> exercises, Color color) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _analyzeGroup(title, exercises),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Analizza Gruppo'),
                ),
              ],
            ),

            SizedBox(height: 12.h),

            // Exercise list
            ...exercises.map((exercise) => Padding(
              padding: EdgeInsets.only(left: 16.w, bottom: 4.h),
              child: Row(
                children: [
                  Icon(Icons.fitness_center, size: 14.sp, color: Colors.grey[500]),
                  SizedBox(width: 8.w),
                  Text(
                    exercise.nome,
                    style: TextStyle(fontSize: 12.sp),
                  ),
                  const Spacer(),
                  Text(
                    '${_currentWeights[exercise.schedaEsercizioId ?? exercise.id]?.toStringAsFixed(1)}kg x ${_currentReps[exercise.schedaEsercizioId ?? exercise.id]}',
                    style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  void _analyzeGroup(String groupName, List<WorkoutExercise> exercises) {
    final groupType = exercises.length == 1 ? 'normal' : exercises.first.setType;

    debugPrint("🎯 [TEST] Analyzing group: $groupName ($groupType) with ${exercises.length} exercises");

    _plateauBloc.analyzeGroupPlateau(
      groupName,
      groupType,
      exercises,
      _currentWeights,
      _currentReps,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🔍 Analizzando gruppo: $groupName...'),
        backgroundColor: const Color(0xFFFF5722),
      ),
    );
  }

  // ============================================================================
  // TAB 3: RESULTS
  // ============================================================================

  Widget _buildResultsTab() {
    return BlocBuilder<PlateauBloc, PlateauState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '📊 Risultati Analisi',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFF5722),
                ),
              ),

              SizedBox(height: 8.h),

              Text(
                'Visualizza i plateau rilevati e le statistiche.',
                style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
              ),

              SizedBox(height: 24.h),

              _buildStateContent(state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStateContent(PlateauState state) {
    if (state is PlateauInitial) {
      return _buildEmptyState();
    }

    if (state is PlateauAnalyzing) {
      return _buildLoadingState(state);
    }

    if (state is PlateauDetected) {
      return _buildDetectedState(state);
    }

    if (state is PlateauError) {
      return _buildErrorState(state);
    }

    return _buildEmptyState();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.analytics,
            size: 64.sp,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16.h),
          Text(
            'Nessuna analisi eseguita',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Vai nelle altre tab per avviare l\'analisi plateau',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(PlateauAnalyzing state) {
    return Center(
      child: Column(
        children: [
          const CircularProgressIndicator(color: Color(0xFFFF5722)),
          SizedBox(height: 16.h),
          Text(
            state.message ?? 'Analizzando plateau...',
            style: TextStyle(fontSize: 14.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectedState(PlateauDetected state) {
    return Column(
      children: [
        // Statistics card
        if (state.plateaus.isNotEmpty)
          PlateauStatisticsCard(statistics: state.statistics),

        // Individual plateaus
        if (state.activePlateaus.isNotEmpty) ...[
          Text(
            'Plateau Individuali Rilevati:',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.h),
          ...state.activePlateaus.map((plateau) => PlateauIndicator(
            plateauInfo: plateau,
            onDismiss: () => _plateauBloc.dismissPlateau(plateau.exerciseId),
          )),
        ],

        // Group analyses
        if (state.significantGroupPlateaus.isNotEmpty) ...[
          SizedBox(height: 24.h),
          Text(
            'Analisi Gruppi:',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.h),
          ...state.significantGroupPlateaus.map((groupAnalysis) => Card(
            child: ListTile(
              leading: Icon(
                Icons.group_work,
                color: const Color(0xFFFF5722),
              ),
              title: Text(groupAnalysis.groupName),
              subtitle: Text(
                '${groupAnalysis.exercisesInPlateau}/${groupAnalysis.totalExercises} esercizi in plateau '
                    '(${groupAnalysis.plateauPercentage.toStringAsFixed(1)}%)',
              ),
              trailing: ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => GroupPlateauDialog(groupAnalysis: groupAnalysis),
                ),
                child: const Text('Dettagli'),
              ),
            ),
          )),
        ],

        // No plateaus detected
        if (state.activePlateaus.isEmpty && state.significantGroupPlateaus.isEmpty)
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 64.sp,
                  color: Colors.green,
                ),
                SizedBox(height: 16.h),
                Text(
                  'Nessun plateau rilevato!',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Text(
                  'Ottimo lavoro! Continua così.',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildErrorState(PlateauError state) {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.error,
            size: 64.sp,
            color: Colors.red,
          ),
          SizedBox(height: 16.h),
          Text(
            'Errore nell\'analisi',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            state.message,
            style: TextStyle(fontSize: 12.sp),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: () => _plateauBloc.resetState(),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 4: CONFIGURATION
  // ============================================================================

  Widget _buildConfigTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '⚙️ Configurazione Sistema',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFF5722),
            ),
          ),

          SizedBox(height: 8.h),

          Text(
            'Gestisci le impostazioni del sistema plateau detection.',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
          ),

          SizedBox(height: 24.h),

          // System health check
          _buildSystemHealthCard(),

          SizedBox(height: 16.h),

          // Configuration presets
          _buildConfigPresetsCard(),

          SizedBox(height: 16.h),

          // Actions
          _buildActionsCard(),
        ],
      ),
    );
  }

  Widget _buildSystemHealthCard() {
    final systemHealth = PlateauSystemChecker.checkPlateauSystemHealth();
    final systemReport = PlateauSystemChecker.getSystemReport();

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  systemHealth ? Icons.check_circle : Icons.error,
                  color: systemHealth ? Colors.green : Colors.red,
                ),
                SizedBox(width: 8.w),
                Text(
                  'Sistema Plateau',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: (systemHealth ? Colors.green : Colors.red).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    systemHealth ? 'HEALTHY' : 'ERROR',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: systemHealth ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 12.h),

            ...systemReport.entries.map((entry) => Padding(
              padding: EdgeInsets.only(bottom: 4.h),
              child: Row(
                children: [
                  Text(
                    '${entry.key}: ',
                    style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    entry.value.toString(),
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigPresetsCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configurazioni Predefinite',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 16.h),

            _buildConfigButton('Production', PlateauConfigurationHelper.productionConfig, Colors.blue),
            SizedBox(height: 8.h),
            _buildConfigButton('Development', PlateauConfigurationHelper.developmentConfig, Colors.orange),
            SizedBox(height: 8.h),
            _buildConfigButton('Debug', PlateauConfigurationHelper.debugConfig, Colors.purple),
            SizedBox(height: 8.h),
            _buildConfigButton('Disabled', PlateauConfigurationHelper.disabledConfig, Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigButton(String name, PlateauDetectionConfig config, Color color) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => _applyConfig(name, config),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
        ),
        child: Text('Applica $name Config'),
      ),
    );
  }

  void _applyConfig(String name, PlateauDetectionConfig config) {
    PlateauDependencyInjection.updatePlateauConfig(config);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Configurazione $name applicata'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Azioni Sistema',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 16.h),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _plateauBloc.resetState(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Reset Stato Plateau'),
              ),
            ),

            SizedBox(height: 8.h),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _generateTestPlateaus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5722),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Genera Plateau di Test'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _generateTestPlateaus() {
    debugPrint("🎯 [TEST] Generating test plateaus...");

    // Genera plateau simulati per tutti gli esercizi
    for (final exercise in _testExercises) {
      final exerciseId = exercise.schedaEsercizioId ?? exercise.id;
      final weight = _currentWeights[exerciseId] ?? exercise.peso;
      final reps = _currentReps[exerciseId] ?? exercise.ripetizioni;

      _plateauBloc.analyzeExercisePlateau(exerciseId, exercise.nome, weight, reps);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎯 Generando plateau di test...'),
        backgroundColor: Color(0xFFFF5722),
      ),
    );
  }

  Widget _buildSystemStatusCard() {
    return Card(
      color: Colors.grey[50],
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.info, size: 16.sp, color: Colors.blue),
                SizedBox(width: 8.w),
                Text(
                  'Stato Sistema',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),

            SizedBox(height: 8.h),

            Text(
              'Il sistema plateau detection è attivo e monitorerà automaticamente i tuoi progressi. '
                  'Modifica i valori sopra e premi "Analizza" per testare il rilevamento.',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Azioni Rapide',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 16.h),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _analyzeAllExercises,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Analizza Tutto'),
                  ),
                ),

                SizedBox(width: 8.w),

                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _plateauBloc.resetState(),
                    child: const Text('Reset'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _analyzeAllExercises() {
    debugPrint("🎯 [TEST] Analyzing all exercises...");

    _plateauBloc.analyzeWorkoutPlateaus(
      _testExercises,
      _currentWeights,
      _currentReps,
      1, // Mock user ID
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔍 Analizzando tutti gli esercizi...'),
        backgroundColor: Color(0xFFFF5722),
      ),
    );
  }
}