import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/workout_design_system.dart';
import 'exercise_card_layout_b_with_history.dart';
import '../../features/workouts/data/services/workout_history_service.dart';
import '../../features/workouts/domain/entities/completed_series.dart';

/// 🏋️ Workout History Integration Example
/// Esempio di come integrare il sistema storico nel layout principale
class WorkoutHistoryIntegrationExample extends StatefulWidget {
  final int userId;
  final int exerciseId;
  final String exerciseName;
  final String? exerciseImageUrl;
  final List<String> muscleGroups;
  final double weight;
  final int reps;
  final int currentSeries;
  final int totalSeries;
  final int? restSeconds;
  final bool isCompleted;
  final bool isTimerActive;
  final VoidCallback onEditParameters;
  final VoidCallback onCompleteSeries;

  const WorkoutHistoryIntegrationExample({
    Key? key,
    required this.userId,
    required this.exerciseId,
    required this.exerciseName,
    this.exerciseImageUrl,
    required this.muscleGroups,
    required this.weight,
    required this.reps,
    required this.currentSeries,
    required this.totalSeries,
    this.restSeconds,
    required this.isCompleted,
    required this.isTimerActive,
    required this.onEditParameters,
    required this.onCompleteSeries,
  }) : super(key: key);

  @override
  _WorkoutHistoryIntegrationExampleState createState() => _WorkoutHistoryIntegrationExampleState();
}

class _WorkoutHistoryIntegrationExampleState extends State<WorkoutHistoryIntegrationExample> {
  Map<int, CompletedSeries> _lastWorkoutSeries = {};
  bool _isLoadingHistory = false;

  @override
  void initState() {
    super.initState();
    _loadWorkoutHistory();
  }

  Future<void> _loadWorkoutHistory() async {
    setState(() => _isLoadingHistory = true);
    
    try {
      final history = await WorkoutHistoryService.getExerciseHistory(
        exerciseId: widget.exerciseId,
        userId: widget.userId,
      );
      
      final lastWorkoutSeries = WorkoutHistoryService.mapLastWorkoutSeries(history);
      
      if (mounted) {
        setState(() {
          _lastWorkoutSeries = lastWorkoutSeries;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
      print('Errore caricamento storico: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WorkoutDesignSystem.backgroundColor,
      appBar: AppBar(
        title: Text('Esempio Integrazione Storico'),
        backgroundColor: WorkoutDesignSystem.surfaceColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            // Esempio con storico integrato
            ExerciseCardLayoutBWithHistory(
              exerciseName: widget.exerciseName,
              muscleGroups: widget.muscleGroups,
              exerciseImageUrl: widget.exerciseImageUrl,
              weight: widget.weight,
              reps: widget.reps,
              currentSeries: widget.currentSeries,
              totalSeries: widget.totalSeries,
              restSeconds: widget.restSeconds,
              isCompleted: widget.isCompleted,
              isTimerActive: widget.isTimerActive,
              onEditParameters: widget.onEditParameters,
              onCompleteSeries: widget.onCompleteSeries,
              userId: widget.userId,
              exerciseId: widget.exerciseId,
              lastWorkoutSeries: _lastWorkoutSeries,
            ),
            
            SizedBox(height: 24.h),
            
            // Informazioni debug
            _buildDebugInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugInfo() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: WorkoutDesignSystem.neutral50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: WorkoutDesignSystem.neutral200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Debug Info',
            style: WorkoutDesignSystem.heading3.copyWith(
              color: WorkoutDesignSystem.onSurfaceColor,
            ),
          ),
          SizedBox(height: 12.h),
          
          Text(
            'Exercise ID: ${widget.exerciseId}',
            style: WorkoutDesignSystem.caption.copyWith(
              color: WorkoutDesignSystem.onSurfaceColor.withOpacity(0.7),
            ),
          ),
          
          Text(
            'User ID: ${widget.userId}',
            style: WorkoutDesignSystem.caption.copyWith(
              color: WorkoutDesignSystem.onSurfaceColor.withOpacity(0.7),
            ),
          ),
          
          Text(
            'Current Series: ${widget.currentSeries}',
            style: WorkoutDesignSystem.caption.copyWith(
              color: WorkoutDesignSystem.onSurfaceColor.withOpacity(0.7),
            ),
          ),
          
          SizedBox(height: 8.h),
          
          Text(
            'Last Workout Series:',
            style: WorkoutDesignSystem.captionBold.copyWith(
              color: WorkoutDesignSystem.onSurfaceColor,
            ),
          ),
          
          if (_lastWorkoutSeries.isEmpty)
            Text(
              'Nessun dato storico disponibile',
              style: WorkoutDesignSystem.caption.copyWith(
                color: WorkoutDesignSystem.neutral500,
              ),
            )
          else
            ..._lastWorkoutSeries.entries.map((entry) {
              final series = entry.value;
              return Padding(
                padding: EdgeInsets.only(left: 8.w, top: 4.h),
                child: Text(
                  'Serie ${entry.key}: ${series.formattedPeso}kg x ${series.formattedRipetizioni} (${series.formattedTimestamp})',
                  style: WorkoutDesignSystem.caption.copyWith(
                    color: WorkoutDesignSystem.onSurfaceColor.withOpacity(0.7),
                    fontSize: 10.sp,
                  ),
                ),
              );
            }).toList(),
          
          SizedBox(height: 12.h),
          
          // Pulsante per ricaricare
          ElevatedButton(
            onPressed: _isLoadingHistory ? null : _loadWorkoutHistory,
            child: _isLoadingHistory
                ? SizedBox(
                    width: 16.w,
                    height: 16.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text('Ricarica Storico'),
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
}

/// 🎯 Widget per testare l'integrazione
class WorkoutHistoryTestWidget extends StatelessWidget {
  const WorkoutHistoryTestWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WorkoutHistoryIntegrationExample(
      userId: 1, // ID utente di test
      exerciseId: 865, // ID esercizio di test (dal tuo esempio)
      exerciseName: 'Panca Piana',
      exerciseImageUrl: 'https://example.com/exercise.jpg',
      muscleGroups: ['Petto', 'Tricipiti', 'Spalle'],
      weight: 10.0,
      reps: 12,
      currentSeries: 1,
      totalSeries: 3,
      restSeconds: 90,
      isCompleted: false,
      isTimerActive: false,
      onEditParameters: () {
        print('Edit parameters tapped');
      },
      onCompleteSeries: () {
        print('Complete series tapped');
      },
    );
  }
}
