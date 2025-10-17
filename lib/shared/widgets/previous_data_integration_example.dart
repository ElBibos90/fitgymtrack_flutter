import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/workout_design_system.dart';
import 'exercise_card_layout_b_with_previous_data.dart';
import 'previous_data_manager.dart';
import '../../features/workouts/domain/entities/completed_series.dart';

/// 🎯 Previous Data Integration Example
/// Esempio completo di integrazione del sistema "Usa Dati Precedenti"
/// per tutte le tipologie di esercizi (singoli, superset, circuit)
class PreviousDataIntegrationExample extends StatefulWidget {
  const PreviousDataIntegrationExample({Key? key}) : super(key: key);

  @override
  _PreviousDataIntegrationExampleState createState() => _PreviousDataIntegrationExampleState();
}

class _PreviousDataIntegrationExampleState extends State<PreviousDataIntegrationExample> {
  late PreviousDataManager _manager;
  int _currentSeries = 1;
  double _currentWeight = 10.0;
  int _currentReps = 12;
  bool _usePreviousData = false;

  // Dati mock per test
  final Map<int, CompletedSeries> _mockLastWorkoutSeries = {
    1: CompletedSeries(
      id: 1,
      allenamentoId: 1375,
      schedaEsercizioId: 865,
      peso: 8.0,
      ripetizioni: 10,
      completata: true,
      tempoRecupero: 90,
      timestamp: DateTime.now().subtract(Duration(days: 1)),
      note: 'Serie 1 ultimo allenamento',
      serieNumber: 1,
      isRestPause: false,
      esercizioNome: 'Panca Piana',
    ),
    2: CompletedSeries(
      id: 2,
      allenamentoId: 1375,
      schedaEsercizioId: 865,
      peso: 8.0,
      ripetizioni: 12,
      completata: true,
      tempoRecupero: 90,
      timestamp: DateTime.now().subtract(Duration(days: 1)),
      note: 'Serie 2 ultimo allenamento',
      serieNumber: 2,
      isRestPause: false,
      esercizioNome: 'Panca Piana',
    ),
    3: CompletedSeries(
      id: 3,
      allenamentoId: 1375,
      schedaEsercizioId: 865,
      peso: 8.0,
      ripetizioni: 12,
      completata: true,
      tempoRecupero: 90,
      timestamp: DateTime.now().subtract(Duration(days: 1)),
      note: 'Serie 3 ultimo allenamento',
      serieNumber: 3,
      isRestPause: false,
      esercizioNome: 'Panca Piana',
    ),
  };

  @override
  void initState() {
    super.initState();
    _manager = PreviousDataManager();
    _loadMockData();
  }

  void _loadMockData() {
    // Simula caricamento dati precedenti
    _manager._lastWorkoutSeries = _mockLastWorkoutSeries;
    _manager.notifyListeners();
  }

  @override
  void dispose() {
    _manager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PreviousDataProvider(
      manager: _manager,
      child: Scaffold(
        backgroundColor: WorkoutDesignSystem.backgroundColor,
        appBar: AppBar(
          title: Text('Esempio Integrazione Dati Precedenti'),
          backgroundColor: WorkoutDesignSystem.surfaceColor,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              // Controlli
              _buildControls(),
              
              SizedBox(height: 24.h),
              
              // Esempio Esercizio Singolo
              _buildSingleExerciseExample(),
              
              SizedBox(height: 24.h),
              
              // Esempio Superset
              _buildSupersetExample(),
              
              SizedBox(height: 24.h),
              
              // Esempio Circuit
              _buildCircuitExample(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: WorkoutDesignSystem.surfaceColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: WorkoutDesignSystem.borderColor,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Controlli Test',
            style: WorkoutDesignSystem.heading3.copyWith(
              color: WorkoutDesignSystem.onSurfaceColor,
            ),
          ),
          SizedBox(height: 16.h),
          
          // Toggle "Usa dati precedenti"
          Row(
            children: [
              Text('Usa dati precedenti:'),
              Spacer(),
              Switch(
                value: _usePreviousData,
                onChanged: (value) {
                  setState(() {
                    _usePreviousData = value;
                    if (value) {
                      _loadPreviousDataForCurrentSeries();
                    }
                  });
                },
                activeColor: WorkoutDesignSystem.primary500,
              ),
            ],
          ),
          
          SizedBox(height: 12.h),
          
          // Serie selector
          Row(
            children: [
              Text('Serie corrente:'),
              Spacer(),
              DropdownButton<int>(
                value: _currentSeries,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _currentSeries = value;
                      if (_usePreviousData) {
                        _loadPreviousDataForCurrentSeries();
                      }
                    });
                  }
                },
                items: List.generate(5, (index) {
                  return DropdownMenuItem(
                    value: index + 1,
                    child: Text('Serie ${index + 1}'),
                  );
                }),
              ),
            ],
          ),
          
          SizedBox(height: 12.h),
          
          // Dati attuali
          Row(
            children: [
              Text('Peso: ${_currentWeight}kg'),
              SizedBox(width: 16.w),
              Text('Reps: $_currentReps'),
            ],
          ),
        ],
      ),
    );
  }

  void _loadPreviousDataForCurrentSeries() {
    final previousSeries = _mockLastWorkoutSeries[_currentSeries];
    if (previousSeries != null) {
      setState(() {
        _currentWeight = previousSeries.peso;
        _currentReps = previousSeries.ripetizioni;
      });
    }
  }

  Widget _buildSingleExerciseExample() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Esercizio Singolo',
          style: WorkoutDesignSystem.heading3.copyWith(
            color: WorkoutDesignSystem.onSurfaceColor,
          ),
        ),
        SizedBox(height: 12.h),
        
        ExerciseCardLayoutBWithPreviousData(
          exerciseName: 'Panca Piana',
          muscleGroups: ['Petto', 'Tricipiti', 'Spalle'],
          exerciseImageUrl: 'https://example.com/panca-piana.jpg',
          weight: _currentWeight,
          reps: _currentReps,
          currentSeries: _currentSeries,
          totalSeries: 3,
          restSeconds: 90,
          isCompleted: false,
          isTimerActive: false,
          onEditParameters: () {
            print('Edit parameters for single exercise');
          },
          onCompleteSeries: () {
            print('Complete series for single exercise');
          },
          userId: 1,
          exerciseId: 865,
          lastWorkoutSeries: _usePreviousData ? _mockLastWorkoutSeries : null,
          usePreviousData: _usePreviousData,
          onUsePreviousDataChanged: (value) {
            setState(() {
              _usePreviousData = value;
              if (value) {
                _loadPreviousDataForCurrentSeries();
              }
            });
          },
          onDataChanged: (data) {
            setState(() {
              _currentWeight = data['peso'] ?? _currentWeight;
              _currentReps = data['ripetizioni'] ?? _currentReps;
            });
          },
        ),
      ],
    );
  }

  Widget _buildSupersetExample() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Superset',
          style: WorkoutDesignSystem.heading3.copyWith(
            color: WorkoutDesignSystem.onSurfaceColor,
          ),
        ),
        SizedBox(height: 12.h),
        
        ExerciseCardLayoutBWithPreviousData(
          exerciseName: 'Panca Piana',
          muscleGroups: ['Petto', 'Tricipiti'],
          exerciseImageUrl: 'https://example.com/panca-piana.jpg',
          weight: _currentWeight,
          reps: _currentReps,
          currentSeries: _currentSeries,
          totalSeries: 3,
          restSeconds: 90,
          isCompleted: false,
          isTimerActive: false,
          onEditParameters: () {
            print('Edit parameters for superset');
          },
          onCompleteSeries: () {
            print('Complete series for superset');
          },
          userId: 1,
          exerciseId: 865,
          lastWorkoutSeries: _usePreviousData ? _mockLastWorkoutSeries : null,
          usePreviousData: _usePreviousData,
          onUsePreviousDataChanged: (value) {
            setState(() {
              _usePreviousData = value;
              if (value) {
                _loadPreviousDataForCurrentSeries();
              }
            });
          },
          onDataChanged: (data) {
            setState(() {
              _currentWeight = data['peso'] ?? _currentWeight;
              _currentReps = data['ripetizioni'] ?? _currentReps;
            });
          },
          // Superset specific
          groupType: 'superset',
          groupExerciseNames: ['Panca Piana', 'Dips'],
          currentExerciseIndex: 0,
          showWarning: true,
        ),
      ],
    );
  }

  Widget _buildCircuitExample() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Circuit',
          style: WorkoutDesignSystem.heading3.copyWith(
            color: WorkoutDesignSystem.onSurfaceColor,
          ),
        ),
        SizedBox(height: 12.h),
        
        ExerciseCardLayoutBWithPreviousData(
          exerciseName: 'Burpees',
          muscleGroups: ['Tutto il corpo'],
          exerciseImageUrl: 'https://example.com/burpees.jpg',
          weight: _currentWeight,
          reps: _currentReps,
          currentSeries: _currentSeries,
          totalSeries: 3,
          restSeconds: 60,
          isCompleted: false,
          isTimerActive: false,
          onEditParameters: () {
            print('Edit parameters for circuit');
          },
          onCompleteSeries: () {
            print('Complete series for circuit');
          },
          userId: 1,
          exerciseId: 866,
          lastWorkoutSeries: _usePreviousData ? _mockLastWorkoutSeries : null,
          usePreviousData: _usePreviousData,
          onUsePreviousDataChanged: (value) {
            setState(() {
              _usePreviousData = value;
              if (value) {
                _loadPreviousDataForCurrentSeries();
              }
            });
          },
          onDataChanged: (data) {
            setState(() {
              _currentWeight = data['peso'] ?? _currentWeight;
              _currentReps = data['ripetizioni'] ?? _currentReps;
            });
          },
          // Circuit specific
          groupType: 'circuit',
          groupExerciseNames: ['Burpees', 'Push-ups', 'Squats'],
          currentExerciseIndex: 0,
          showWarning: true,
        ),
      ],
    );
  }
}

/// 🎯 Widget per testare il sistema con dati reali
class PreviousDataRealTestWidget extends StatefulWidget {
  final int userId;
  final int exerciseId;
  final String exerciseName;

  const PreviousDataRealTestWidget({
    Key? key,
    required this.userId,
    required this.exerciseId,
    required this.exerciseName,
  }) : super(key: key);

  @override
  _PreviousDataRealTestWidgetState createState() => _PreviousDataRealTestWidgetState();
}

class _PreviousDataRealTestWidgetState extends State<PreviousDataRealTestWidget> {
  late PreviousDataManager _manager;
  int _currentSeries = 1;
  double _currentWeight = 10.0;
  int _currentReps = 12;
  bool _usePreviousData = false;

  @override
  void initState() {
    super.initState();
    _manager = PreviousDataManager();
    _loadRealData();
  }

  Future<void> _loadRealData() async {
    await _manager.loadPreviousData(
      exerciseId: widget.exerciseId,
      userId: widget.userId,
    );
  }

  @override
  void dispose() {
    _manager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PreviousDataProvider(
      manager: _manager,
      child: Scaffold(
        backgroundColor: WorkoutDesignSystem.backgroundColor,
        appBar: AppBar(
          title: Text('Test Dati Reali - ${widget.exerciseName}'),
          backgroundColor: WorkoutDesignSystem.surfaceColor,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              // Controlli
              _buildControls(),
              
              SizedBox(height: 24.h),
              
              // Esercizio con dati reali
              ExerciseCardLayoutBWithPreviousData(
                exerciseName: widget.exerciseName,
                muscleGroups: ['Petto', 'Tricipiti'],
                weight: _currentWeight,
                reps: _currentReps,
                currentSeries: _currentSeries,
                totalSeries: 3,
                restSeconds: 90,
                isCompleted: false,
                isTimerActive: false,
                onEditParameters: () {
                  print('Edit parameters');
                },
                onCompleteSeries: () {
                  print('Complete series');
                },
                userId: widget.userId,
                exerciseId: widget.exerciseId,
                lastWorkoutSeries: _usePreviousData ? _manager.lastWorkoutSeries : null,
                usePreviousData: _usePreviousData,
                onUsePreviousDataChanged: (value) {
                  setState(() {
                    _usePreviousData = value;
                    if (value) {
                      _loadPreviousDataForCurrentSeries();
                    }
                  });
                },
                onDataChanged: (data) {
                  setState(() {
                    _currentWeight = data['peso'] ?? _currentWeight;
                    _currentReps = data['ripetizioni'] ?? _currentReps;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: WorkoutDesignSystem.surfaceColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: WorkoutDesignSystem.borderColor,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Controlli Test Dati Reali',
            style: WorkoutDesignSystem.heading3.copyWith(
              color: WorkoutDesignSystem.onSurfaceColor,
            ),
          ),
          SizedBox(height: 16.h),
          
          // Toggle "Usa dati precedenti"
          Row(
            children: [
              Text('Usa dati precedenti:'),
              Spacer(),
              Switch(
                value: _usePreviousData,
                onChanged: (value) {
                  setState(() {
                    _usePreviousData = value;
                    if (value) {
                      _loadPreviousDataForCurrentSeries();
                    }
                  });
                },
                activeColor: WorkoutDesignSystem.primary500,
              ),
            ],
          ),
          
          SizedBox(height: 12.h),
          
          // Serie selector
          Row(
            children: [
              Text('Serie corrente:'),
              Spacer(),
              DropdownButton<int>(
                value: _currentSeries,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _currentSeries = value;
                      if (_usePreviousData) {
                        _loadPreviousDataForCurrentSeries();
                      }
                    });
                  }
                },
                items: List.generate(5, (index) {
                  return DropdownMenuItem(
                    value: index + 1,
                    child: Text('Serie ${index + 1}'),
                  );
                }),
              ),
            ],
          ),
          
          SizedBox(height: 12.h),
          
          // Dati attuali
          Row(
            children: [
              Text('Peso: ${_currentWeight}kg'),
              SizedBox(width: 16.w),
              Text('Reps: $_currentReps'),
            ],
          ),
          
          SizedBox(height: 12.h),
          
          // Pulsante ricarica
          ElevatedButton.icon(
            onPressed: _loadRealData,
            icon: Icon(Icons.refresh, size: 16.sp),
            label: Text('Ricarica Dati'),
            style: ElevatedButton.styleFrom(
              backgroundColor: WorkoutDesignSystem.primary500,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _loadPreviousDataForCurrentSeries() {
    final previousSeries = _manager.getSeriesData(_currentSeries);
    if (previousSeries != null) {
      setState(() {
        _currentWeight = previousSeries.peso;
        _currentReps = previousSeries.ripetizioni;
      });
    }
  }
}
