// lib/shared/widgets/exercise_navigation_widget.dart
// 🚀 STEP 3: Smart Exercise Navigation Widget
// ✅ Previous/Next Exercise navigation
// ✅ Tap navigation sulla lista per saltare direttamente
// ✅ Current exercise highlighting
// ✅ Auto-advance logic ready
// ✅ Visual progress indicators

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../features/workouts/models/workout_plan_models.dart';
import '../../features/workouts/models/active_workout_models.dart';

/// 🎯 STEP 3: Widget per la navigazione intelligente tra esercizi
class ExerciseNavigationWidget extends StatelessWidget {
  final List<WorkoutExercise> exercises;
  final Map<int, List<CompletedSeriesData>> completedSeries;
  final int currentExerciseIndex;
  final Function(int exerciseIndex) onExerciseSelected;
  final VoidCallback? onPreviousExercise;
  final VoidCallback? onNextExercise;
  final bool showNavigationControls;
  final bool isCompact;

  const ExerciseNavigationWidget({
    super.key,
    required this.exercises,
    required this.completedSeries,
    required this.currentExerciseIndex,
    required this.onExerciseSelected,
    this.onPreviousExercise,
    this.onNextExercise,
    this.showNavigationControls = true,
    this.isCompact = false,
  });

  /// Calcola le serie completate per un esercizio
  int _getCompletedSeriesCount(int exerciseId) {
    final series = completedSeries[exerciseId] ?? [];
    return series.length;
  }

  /// Determina se un esercizio è completato
  bool _isExerciseCompleted(WorkoutExercise exercise) {
    final exerciseId = exercise.schedaEsercizioId ?? exercise.id;
    final completedCount = _getCompletedSeriesCount(exerciseId);
    return completedCount >= exercise.serie;
  }

  /// Determina se un esercizio è disponibile per la navigazione
  bool _isExerciseAvailable(int exerciseIndex) {
    // L'esercizio corrente e quelli precedenti sono sempre disponibili
    if (exerciseIndex <= currentExerciseIndex) {
      return true;
    }

    // Gli esercizi successivi sono disponibili solo se quello corrente è completato
    return _isExerciseCompleted(exercises[currentExerciseIndex]);
  }

  /// Calcola il progresso totale dell'allenamento
  double _getWorkoutProgress() {
    if (exercises.isEmpty) return 0.0;

    int totalCompletedExercises = 0;
    for (final exercise in exercises) {
      if (_isExerciseCompleted(exercise)) {
        totalCompletedExercises++;
      }
    }

    return totalCompletedExercises / exercises.length;
  }

  /// Determina l'icona per lo stato dell'esercizio
  IconData _getExerciseIcon(WorkoutExercise exercise, int index) {
    if (_isExerciseCompleted(exercise)) {
      return Icons.check_circle;
    } else if (index == currentExerciseIndex) {
      return Icons.play_circle_filled;
    } else if (index < currentExerciseIndex) {
      return Icons.radio_button_checked;
    } else {
      return Icons.radio_button_unchecked;
    }
  }

  /// Determina il colore per lo stato dell'esercizio
  Color _getExerciseColor(WorkoutExercise exercise, int index) {
    if (_isExerciseCompleted(exercise)) {
      return Colors.green;
    } else if (index == currentExerciseIndex) {
      return Colors.blue;
    } else if (index < currentExerciseIndex) {
      return Colors.orange;
    } else {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (exercises.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        // 🎯 Progress Overview Card
        _buildProgressOverviewCard(),

        if (showNavigationControls) ...[
          SizedBox(height: 16.h),
          // 🎯 Navigation Controls
          _buildNavigationControls(),
        ],

        SizedBox(height: 16.h),

        // 🎯 Exercise List with Navigation
        _buildExerciseList(context),
      ],
    );
  }

  /// 📊 Progress Overview Card
  Widget _buildProgressOverviewCard() {
    final progress = _getWorkoutProgress();
    final completedCount = exercises.where(_isExerciseCompleted).length;
    final totalCount = exercises.length;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.blue.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '🎯 Progresso Esercizi',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade800,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.blue.shade600,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  '$completedCount/$totalCount',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
              minHeight: 8.h,
            ),
          ),

          SizedBox(height: 8.h),

          Text(
            progress == 1.0
                ? '🎉 Tutti gli esercizi completati!'
                : 'Esercizio corrente: ${exercises[currentExerciseIndex].nome}',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 🔄 Navigation Controls (Previous/Next)
  Widget _buildNavigationControls() {
    final canGoPrevious = currentExerciseIndex > 0;
    final canGoNext = currentExerciseIndex < exercises.length - 1 &&
        _isExerciseAvailable(currentExerciseIndex + 1);

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Previous Button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: canGoPrevious ? onPreviousExercise : null,
              icon: Icon(Icons.chevron_left, size: 20.sp),
              label: Text(
                'Precedente',
                style: TextStyle(fontSize: 14.sp),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: canGoPrevious ? Colors.grey.shade600 : Colors.grey.shade300,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                elevation: canGoPrevious ? 2 : 0,
              ),
            ),
          ),

          SizedBox(width: 12.w),

          // Current Exercise Indicator
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Text(
              '${currentExerciseIndex + 1}/${exercises.length}',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
          ),

          SizedBox(width: 12.w),

          // Next Button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: canGoNext ? onNextExercise : null,
              icon: Icon(Icons.chevron_right, size: 20.sp),
              label: Text(
                'Successivo',
                style: TextStyle(fontSize: 14.sp),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: canGoNext ? Colors.blue.shade600 : Colors.grey.shade300,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                elevation: canGoNext ? 2 : 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 📋 Exercise List with Tap Navigation
  Widget _buildExerciseList(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Icon(
                  Icons.list_alt,
                  color: Colors.blue.shade600,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  '📋 Lista Esercizi',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    'Tap per saltare',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.blue.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Divider(
            height: 1,
            color: Colors.grey.shade200,
            indent: 16.w,
            endIndent: 16.w,
          ),

          // Exercise Items
          ...exercises.asMap().entries.map((entry) {
            final index = entry.key;
            final exercise = entry.value;
            return _buildExerciseItem(context, exercise, index);
          }),
        ],
      ),
    );
  }

  /// 🏋️ Single Exercise Item
  Widget _buildExerciseItem(BuildContext context, WorkoutExercise exercise, int index) {
    final exerciseId = exercise.schedaEsercizioId ?? exercise.id;
    final completedCount = _getCompletedSeriesCount(exerciseId);
    final isCompleted = _isExerciseCompleted(exercise);
    final isCurrent = index == currentExerciseIndex;
    final isAvailable = _isExerciseAvailable(index);
    final exerciseColor = _getExerciseColor(exercise, index);
    final exerciseIcon = _getExerciseIcon(exercise, index);

    return InkWell(
      onTap: isAvailable ? () => onExerciseSelected(index) : null,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: isCurrent
              ? Colors.blue.shade50
              : (isCompleted ? Colors.green.shade50 : Colors.transparent),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isCurrent
                ? Colors.blue.shade300
                : (isCompleted ? Colors.green.shade300 : Colors.transparent),
            width: isCurrent ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Exercise Status Icon
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: exerciseColor.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: exerciseColor, width: 2),
              ),
              child: Icon(
                exerciseIcon,
                color: exerciseColor,
                size: 18.sp,
              ),
            ),

            SizedBox(width: 12.w),

            // Exercise Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Exercise Name
                  Text(
                    exercise.nome,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                      color: isAvailable ? Colors.grey[800] : Colors.grey[500],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: 2.h),

                  // Exercise Details
                  Row(
                    children: [
                      // Series Progress
                      Text(
                        '$completedCount/${exercise.serie} serie',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: exerciseColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      SizedBox(width: 8.w),

                      // Separator
                      Container(
                        width: 4.w,
                        height: 4.w,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),

                      SizedBox(width: 8.w),

                      // Weight & Reps
                      Text(
                        '${exercise.peso.toStringAsFixed(1)}kg × ${exercise.ripetizioni}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Status Indicators
            Column(
              children: [
                if (isCurrent) ...[
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade600,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      'ATTIVO',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ] else if (isCompleted) ...[
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: Colors.green.shade600,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      'FATTO',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ] else if (!isAvailable) ...[
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      'BLOCCATO',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],

                if (isAvailable && !isCurrent && !isCompleted) ...[
                  Icon(
                    Icons.touch_app,
                    color: Colors.blue.shade400,
                    size: 16.sp,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}