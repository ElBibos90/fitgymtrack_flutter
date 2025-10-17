import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/workout_design_system.dart';
import '../../features/workouts/domain/entities/exercise.dart';
import '../../features/workouts/domain/entities/completed_series.dart';

class WorkoutHistoryCollapsible extends StatefulWidget {
  final int userId;
  final int exerciseId;
  final String exerciseName;
  final String exerciseImage;
  final VoidCallback? onHistoryTapped;

  const WorkoutHistoryCollapsible({
    Key? key,
    required this.userId,
    required this.exerciseId,
    required this.exerciseName,
    required this.exerciseImage,
    this.onHistoryTapped,
  }) : super(key: key);

  @override
  _WorkoutHistoryCollapsibleState createState() => _WorkoutHistoryCollapsibleState();
}

class _WorkoutHistoryCollapsibleState extends State<WorkoutHistoryCollapsible>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  bool _isLoading = false;
  List<CompletedSeries> _workoutHistory = [];
  Map<int, CompletedSeries> _lastWorkoutSeries = {}; // serie_number -> CompletedSeries
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _loadWorkoutHistory();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkoutHistory() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Simuliamo chiamata API esistente
      // GET /api/serie_completate.php?esercizio_id={exerciseId}
      final history = await _fetchWorkoutHistory();
      
      if (mounted) {
        setState(() {
          _workoutHistory = history;
          _mapLastWorkoutSeries();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      print('Error loading workout history: $e');
    }
  }

  Future<List<CompletedSeries>> _fetchWorkoutHistory() async {
    // TODO: Implementare chiamata API reale
    // Per ora simuliamo dati
    await Future.delayed(Duration(milliseconds: 500));
    
    return [
      CompletedSeries(
        id: 1,
        allenamentoId: 1375,
        schedaEsercizioId: widget.exerciseId,
        peso: 10.0,
        ripetizioni: 12,
        completata: true,
        tempoRecupero: 90,
        timestamp: DateTime.now().subtract(Duration(days: 1)),
        note: 'Ultimo allenamento',
        serieNumber: 1,
        isRestPause: false,
        restPauseReps: null,
        restPauseRestSeconds: null,
        esercizioNome: widget.exerciseName,
      ),
      CompletedSeries(
        id: 2,
        allenamentoId: 1375,
        schedaEsercizioId: widget.exerciseId,
        peso: 10.0,
        ripetizioni: 12,
        completata: true,
        tempoRecupero: 90,
        timestamp: DateTime.now().subtract(Duration(days: 1)),
        note: 'Ultimo allenamento',
        serieNumber: 2,
        isRestPause: false,
        restPauseReps: null,
        restPauseRestSeconds: null,
        esercizioNome: widget.exerciseName,
      ),
      CompletedSeries(
        id: 3,
        allenamentoId: 1375,
        schedaEsercizioId: widget.exerciseId,
        peso: 10.0,
        ripetizioni: 12,
        completata: true,
        tempoRecupero: 90,
        timestamp: DateTime.now().subtract(Duration(days: 1)),
        note: 'Ultimo allenamento',
        serieNumber: 3,
        isRestPause: false,
        restPauseReps: null,
        restPauseRestSeconds: null,
        esercizioNome: widget.exerciseName,
      ),
    ];
  }

  void _mapLastWorkoutSeries() {
    _lastWorkoutSeries.clear();
    
    // Trova l'ultimo allenamento (primo elemento della lista ordinata per timestamp DESC)
    if (_workoutHistory.isNotEmpty) {
      final lastWorkoutId = _workoutHistory.first.allenamentoId;
      
      // Mappa tutte le serie dell'ultimo allenamento per serie_number
      for (final series in _workoutHistory) {
        if (series.allenamentoId == lastWorkoutId) {
          _lastWorkoutSeries[series.serieNumber] = series;
        }
      }
    }
  }

  CompletedSeries? _getLastWorkoutSeries(int serieNumber) {
    return _lastWorkoutSeries[serieNumber];
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: WorkoutDesignSystem.surfaceColor,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [WorkoutDesignSystem.cardShadow],
        border: Border.all(
          color: WorkoutDesignSystem.borderColor,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          if (_isExpanded) _buildContent(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return GestureDetector(
      onTap: _toggleExpanded,
      child: Container(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            // Icona storico
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: WorkoutDesignSystem.primary50,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Icons.history,
                color: WorkoutDesignSystem.primary500,
                size: 20.sp,
              ),
            ),
            
            SizedBox(width: 12.w),
            
            // Titolo e info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Storico Allenamenti',
                    style: WorkoutDesignSystem.heading3.copyWith(
                      color: WorkoutDesignSystem.onSurfaceColor,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${_workoutHistory.length} allenamenti completati',
                    style: WorkoutDesignSystem.caption.copyWith(
                      color: WorkoutDesignSystem.onSurfaceColor.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            
            // Indicatore espansione
            AnimatedRotation(
              turns: _isExpanded ? 0.5 : 0.0,
              duration: Duration(milliseconds: 300),
              child: Icon(
                Icons.expand_more,
                color: WorkoutDesignSystem.onSurfaceColor.withOpacity(0.6),
                size: 24.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        return SizeTransition(
          sizeFactor: _expandAnimation,
          child: Container(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
            child: _isLoading ? _buildLoadingState() : _buildHistoryContent(),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 100.h,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: WorkoutDesignSystem.primary500,
              strokeWidth: 2,
            ),
            SizedBox(height: 12.h),
            Text(
              'Caricamento storico...',
              style: WorkoutDesignSystem.caption.copyWith(
                color: WorkoutDesignSystem.onSurfaceColor.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryContent() {
    if (_workoutHistory.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Mini grafico progresso
        _buildProgressChart(),
        
        SizedBox(height: 16.h),
        
        // Lista ultimi allenamenti
        _buildWorkoutList(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 120.h,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 32.sp,
              color: WorkoutDesignSystem.onSurfaceColor.withOpacity(0.4),
            ),
            SizedBox(height: 8.h),
            Text(
              'Nessun allenamento precedente',
              style: WorkoutDesignSystem.body2.copyWith(
                color: WorkoutDesignSystem.onSurfaceColor.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressChart() {
    return Container(
      height: 80.h,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: WorkoutDesignSystem.primary50,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: WorkoutDesignSystem.primary200,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up,
                size: 16.sp,
                color: WorkoutDesignSystem.primary600,
              ),
              SizedBox(width: 8.w),
              Text(
                'Progresso Peso',
                style: WorkoutDesignSystem.captionBold.copyWith(
                  color: WorkoutDesignSystem.primary700,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          // Mini grafico semplificato
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _buildChartBars(),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildChartBars() {
    if (_workoutHistory.isEmpty) return [];
    
    // Prendi gli ultimi 5 allenamenti per il grafico
    final recentWorkouts = _workoutHistory.take(5).toList();
    final maxWeight = recentWorkouts.map((w) => w.peso).reduce((a, b) => a > b ? a : b);
    
    return recentWorkouts.map((workout) {
      final height = (workout.peso / maxWeight) * 30.h;
      return Container(
        width: 8.w,
        height: height,
        decoration: BoxDecoration(
          color: WorkoutDesignSystem.primary500,
          borderRadius: BorderRadius.circular(4.r),
        ),
      );
    }).toList();
  }

  Widget _buildWorkoutList() {
    return Column(
      children: [
        // Header lista
        Row(
          children: [
            Text(
              'Ultimi Allenamenti',
              style: WorkoutDesignSystem.captionBold.copyWith(
                color: WorkoutDesignSystem.onSurfaceColor,
              ),
            ),
            Spacer(),
            Text(
              'Peso x Ripetizioni',
              style: WorkoutDesignSystem.caption.copyWith(
                color: WorkoutDesignSystem.onSurfaceColor.withOpacity(0.7),
              ),
            ),
          ],
        ),
        
        SizedBox(height: 8.h),
        
        // Lista allenamenti
        ...(_workoutHistory.take(5).map((workout) => _buildWorkoutItem(workout))),
      ],
    );
  }

  Widget _buildWorkoutItem(CompletedSeries workout) {
    final isLastWorkout = workout == _workoutHistory.first;
    
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isLastWorkout 
            ? WorkoutDesignSystem.primary50 
            : WorkoutDesignSystem.surfaceColor,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: isLastWorkout 
              ? WorkoutDesignSystem.primary200 
              : WorkoutDesignSystem.borderColor,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Data
          Container(
            width: 40.w,
            child: Column(
              children: [
                Text(
                  '${workout.timestamp.day}',
                  style: WorkoutDesignSystem.captionBold.copyWith(
                    color: WorkoutDesignSystem.onSurfaceColor,
                  ),
                ),
                Text(
                  '${_getMonthName(workout.timestamp.month)}',
                  style: WorkoutDesignSystem.caption.copyWith(
                    color: WorkoutDesignSystem.onSurfaceColor.withOpacity(0.7),
                    fontSize: 10.sp,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(width: 12.w),
          
          // Info esercizio
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Serie ${workout.serieNumber}',
                  style: WorkoutDesignSystem.captionBold.copyWith(
                    color: WorkoutDesignSystem.onSurfaceColor,
                  ),
                ),
                if (isLastWorkout)
                  Text(
                    'Ultimo allenamento',
                    style: WorkoutDesignSystem.caption.copyWith(
                      color: WorkoutDesignSystem.primary600,
                      fontSize: 10.sp,
                    ),
                  ),
              ],
            ),
          ),
          
          // Peso x Ripetizioni
          Text(
            '${workout.peso}kg x ${workout.ripetizioni}',
            style: WorkoutDesignSystem.captionBold.copyWith(
              color: WorkoutDesignSystem.onSurfaceColor,
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Gen', 'Feb', 'Mar', 'Apr', 'Mag', 'Giu',
      'Lug', 'Ago', 'Set', 'Ott', 'Nov', 'Dic'
    ];
    return months[month - 1];
  }
}

// Classe per rappresentare i dati delle serie completate
class CompletedSeries {
  final int id;
  final int allenamentoId;
  final int schedaEsercizioId;
  final double peso;
  final int ripetizioni;
  final bool completata;
  final int tempoRecupero;
  final DateTime timestamp;
  final String note;
  final int serieNumber;
  final bool isRestPause;
  final int? restPauseReps;
  final int? restPauseRestSeconds;
  final String esercizioNome;

  CompletedSeries({
    required this.id,
    required this.allenamentoId,
    required this.schedaEsercizioId,
    required this.peso,
    required this.ripetizioni,
    required this.completata,
    required this.tempoRecupero,
    required this.timestamp,
    required this.note,
    required this.serieNumber,
    required this.isRestPause,
    this.restPauseReps,
    this.restPauseRestSeconds,
    required this.esercizioNome,
  });
}
