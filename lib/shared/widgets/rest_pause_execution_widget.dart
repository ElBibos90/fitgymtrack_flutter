// 🚀 FASE 5 - STEP 5: RestPauseExecutionWidget
// File: lib/shared/widgets/rest_pause_execution_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RestPauseExecutionWidget extends StatelessWidget {
  final String exerciseName;
  final int currentSeries;
  final int totalSeries;
  final int currentMicroSeries;
  final int totalMicroSeries;
  final int targetReps;
  final List<int> completedMicroReps;
  final int totalCompletedReps;
  final bool isInRestPause;
  final String? nextMicroRepsInfo;
  final VoidCallback onCompleteMicroSeries;
  final VoidCallback? onEditWeight;
  final VoidCallback? onEditReps;
  final double currentWeight;
  final int currentReps;

  const RestPauseExecutionWidget({
    super.key,
    required this.exerciseName,
    required this.currentSeries,
    required this.totalSeries,
    required this.currentMicroSeries,
    required this.totalMicroSeries,
    required this.targetReps,
    required this.completedMicroReps,
    required this.totalCompletedReps,
    required this.isInRestPause,
    this.nextMicroRepsInfo,
    required this.onCompleteMicroSeries,
    this.onEditWeight,
    this.onEditReps,
    required this.currentWeight,
    required this.currentReps,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header REST-PAUSE
          _buildRestPauseHeader(colorScheme),

          SizedBox(height: 24.h),

          // Nome esercizio
          Text(
            exerciseName,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: colorScheme.onBackground,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 32.h),

          // Progress indicator micro-serie
          _buildMicroSeriesProgress(colorScheme),

          SizedBox(height: 24.h),

          // Card micro-serie corrente
          _buildCurrentMicroSeriesCard(colorScheme),

          SizedBox(height: 24.h),

          // Statistiche completate
          _buildCompletedStats(colorScheme),

          SizedBox(height: 32.h),

          // Input peso e ripetizioni
          _buildInputSection(colorScheme),

          SizedBox(height: 32.h),

          // Pulsante completamento
          _buildCompletionButton(colorScheme),

          if (nextMicroRepsInfo != null) ...[
            SizedBox(height: 16.h),
            _buildNextMicroSeriesInfo(colorScheme),
          ],
        ],
      ),
    );
  }

  Widget _buildRestPauseHeader(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withOpacity(0.1),
            Colors.purple.withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bolt,
            color: Colors.purple,
            size: 20.sp,
          ),
          SizedBox(width: 8.w),
          Text(
            'REST-PAUSE ATTIVO',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: Colors.purple,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Text(
              'Serie ${currentSeries}/${totalSeries}',
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMicroSeriesProgress(ColorScheme colorScheme) {
    return Column(
      children: [
        Text(
          'Micro-serie ${currentMicroSeries + 1} di ${totalMicroSeries}',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 12.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(totalMicroSeries, (index) {
            final isCompleted = index < completedMicroReps.length;
            final isCurrent = index == currentMicroSeries;
            final isPending = index > currentMicroSeries;

            return Container(
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              width: 40.w,
              height: 8.h,
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.green
                    : isCurrent
                    ? Colors.purple
                    : Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4.r),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildCurrentMicroSeriesCard(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            'Target micro-serie',
            style: TextStyle(
              fontSize: 14.sp,
              color: colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '${targetReps} ripetizioni',
            style: TextStyle(
              fontSize: 32.sp,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          if (isInRestPause) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Text(
                '⚡ In mini-recupero',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompletedStats(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Micro-serie completate',
            '${completedMicroReps.length}',
            Colors.green,
          ),
          Container(
            width: 1,
            height: 40.h,
            color: colorScheme.outline.withOpacity(0.3),
          ),
          _buildStatItem(
            'Reps totali',
            '${totalCompletedReps}',
            Colors.blue,
          ),
          Container(
            width: 1,
            height: 40.h,
            color: colorScheme.outline.withOpacity(0.3),
          ),
          _buildStatItem(
            'Sequenza',
            completedMicroReps.isEmpty ? '-' : completedMicroReps.join('+'),
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.sp,
            color: color.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInputSection(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Peso
          Expanded(
            child: GestureDetector(
              onTap: onEditWeight,
              child: Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Peso',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${currentWeight.toStringAsFixed(1)} kg',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(width: 12.w),

          // Ripetizioni
          Expanded(
            child: GestureDetector(
              onTap: onEditReps,
              child: Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ripetizioni',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${currentReps}',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionButton(ColorScheme colorScheme) {
    final isLastMicroSeries = currentMicroSeries >= totalMicroSeries - 1;

    return SizedBox(
      width: double.infinity,
      height: 56.h,
      child: ElevatedButton(
        onPressed: isInRestPause ? null : onCompleteMicroSeries,
        style: ElevatedButton.styleFrom(
          backgroundColor: isLastMicroSeries ? Colors.green : Colors.purple,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.withOpacity(0.3),
          disabledForegroundColor: Colors.grey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: isInRestPause ? 0 : 3,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isInRestPause) ...[
              SizedBox(
                width: 20.w,
                height: 20.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Attendi mini-recupero...',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ] else ...[
              Icon(
                isLastMicroSeries ? Icons.check_circle : Icons.bolt,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                isLastMicroSeries
                    ? 'COMPLETA SERIE REST-PAUSE'
                    : 'COMPLETA MICRO-SERIE ${currentMicroSeries + 1}',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNextMicroSeriesInfo(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.blue,
            size: 16.sp,
          ),
          SizedBox(width: 8.w),
          Text(
            nextMicroRepsInfo!,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.blue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}