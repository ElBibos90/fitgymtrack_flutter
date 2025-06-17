// 🚀 STEP 4: REST-PAUSE Widget MINIMALISTA - Self-contained
// File: lib/shared/widgets/rest_pause_execution_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'rest_pause_timer_popup.dart';

/// Simple REST-PAUSE data class (inline, no external dependencies)
class SimpleRestPauseData {
  final String exerciseName;
  final double weight;
  final int serieNumber;
  final String originalSequence;
  final int restSeconds;
  final List<int> targetSequence;
  final List<int> completedReps;

  SimpleRestPauseData({
    required this.exerciseName,
    required this.weight,
    required this.serieNumber,
    required this.originalSequence,
    required this.restSeconds,
    required this.targetSequence,
    this.completedReps = const [],
  });

  int get currentMicroSeriesIndex => completedReps.length;
  bool get hasMoreMicroSeries => currentMicroSeriesIndex < targetSequence.length;
  int? get nextTargetReps => hasMoreMicroSeries ? targetSequence[currentMicroSeriesIndex] : null;
  int get totalActualReps => completedReps.fold(0, (sum, reps) => sum + reps);
  String get actualSequence => completedReps.join('+');
  double get completionPercentage => targetSequence.isNotEmpty
      ? (currentMicroSeriesIndex / targetSequence.length)
      : 0.0;
  bool get isCompleted => currentMicroSeriesIndex >= targetSequence.length;

  SimpleRestPauseData addMicroSeries(int reps) {
    return SimpleRestPauseData(
      exerciseName: exerciseName,
      weight: weight,
      serieNumber: serieNumber,
      originalSequence: originalSequence,
      restSeconds: restSeconds,
      targetSequence: targetSequence,
      completedReps: [...completedReps, reps],
    );
  }
}

/// Widget dedicato per l'esecuzione REST-PAUSE - Versione MINIMALISTA
class RestPauseExecutionWidget extends StatefulWidget {
  final String exerciseName;
  final String restPauseSequence;
  final int restSeconds;
  final double currentWeight;
  final int currentSeries;
  final int totalSeries;
  final Function(SimpleRestPauseData)? onCompleteAllMicroSeries;
  final Function(SimpleRestPauseData, int, int)? onCompleteMicroSeries;

  const RestPauseExecutionWidget({
    Key? key,
    required this.exerciseName,
    required this.restPauseSequence,
    required this.restSeconds,
    required this.currentWeight,
    required this.currentSeries,
    required this.totalSeries,
    this.onCompleteAllMicroSeries,
    this.onCompleteMicroSeries,
  }) : super(key: key);

  @override
  State<RestPauseExecutionWidget> createState() => _RestPauseExecutionWidgetState();
}

class _RestPauseExecutionWidgetState extends State<RestPauseExecutionWidget>
    with TickerProviderStateMixin {

  // ====== STATE VARIABLES ======
  late SimpleRestPauseData _data;

  // ====== ANIMATION CONTROLLERS ======
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _progressAnimation;

  // ====== TEXT CONTROLLERS ======
  final TextEditingController _repsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    print('🔥 [REST-PAUSE WIDGET] Initializing: ${widget.exerciseName}');

    _initializeAnimations();
    _initializeData();
    _resetToFirstMicroSeries();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  // ====== INITIALIZATION ======

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);
  }

  void _initializeData() {
    try {
      final sequence = _parseSequence(widget.restPauseSequence);
      _data = SimpleRestPauseData(
        exerciseName: widget.exerciseName,
        weight: widget.currentWeight,
        serieNumber: widget.currentSeries,
        originalSequence: widget.restPauseSequence,
        restSeconds: widget.restSeconds,
        targetSequence: sequence,
      );

      print('🔥 [REST-PAUSE WIDGET] Parsed sequence: $sequence');
    } catch (e) {
      print('❌ [REST-PAUSE WIDGET] Error: $e');
      _data = SimpleRestPauseData(
        exerciseName: widget.exerciseName,
        weight: widget.currentWeight,
        serieNumber: widget.currentSeries,
        originalSequence: "10",
        restSeconds: 15,
        targetSequence: [10],
      );
    }
  }

  List<int> _parseSequence(String sequence) {
    if (sequence.isEmpty) return [10];

    return sequence
        .split('+')
        .map((s) => int.tryParse(s.trim()) ?? 0)
        .where((reps) => reps > 0)
        .toList();
  }

  void _resetToFirstMicroSeries() {
    setState(() {
      _repsController.text = _data.nextTargetReps?.toString() ?? '10';
    });
    _progressController.reset();
  }

  // ====== UI HELPERS ======

  bool get _isLastMicroSeries => !_data.hasMoreMicroSeries;
  int get _currentTargetReps => _data.nextTargetReps ?? 10;
  int get _totalMicroSeries => _data.targetSequence.length;
  double get _overallProgress => _data.completionPercentage;

  // ====== ACTIONS ======

  void _handleCompleteMicroSeries() {
    final enteredReps = int.tryParse(_repsController.text) ?? _currentTargetReps;
    final currentIndex = _data.currentMicroSeriesIndex;

    print('🔥 [REST-PAUSE WIDGET] Micro-series ${currentIndex + 1} completed: $enteredReps reps');

    setState(() {
      _data = _data.addMicroSeries(enteredReps);
    });

    widget.onCompleteMicroSeries?.call(_data, currentIndex, enteredReps);

    if (_isLastMicroSeries) {
      _handleCompleteAllSeries();
    } else {
      _startMiniRecovery();
    }
  }

  void _startMiniRecovery() {
    print('🔥 [REST-PAUSE WIDGET] Starting mini-recovery: ${widget.restSeconds}s');
    _showRestPauseTimer();
  }

  void _showRestPauseTimer() {
    RestPauseTimerHelper.showRestPauseTimer(
      context: context,
      seconds: widget.restSeconds,
      exerciseName: widget.exerciseName,
      currentMicroSeries: _data.currentMicroSeriesIndex + 1,
      totalMicroSeries: _totalMicroSeries,
      nextTargetReps: _currentTargetReps,
      onComplete: _endMiniRecovery,
      onSkip: _endMiniRecovery,
    );
  }

  void _endMiniRecovery() {
    setState(() {
      _repsController.text = _currentTargetReps.toString();
    });

    print('🔥 [REST-PAUSE WIDGET] Mini-recovery ended, ready for micro-series ${_data.currentMicroSeriesIndex + 1}');
  }

  void _handleCompleteAllSeries() {
    print('🔥 [REST-PAUSE WIDGET] All micro-series completed!');
    print('🔥 [REST-PAUSE WIDGET] Final: ${_data.actualSequence} (${_data.totalActualReps} reps)');

    _progressController.forward();
    widget.onCompleteAllMicroSeries?.call(_data);
  }

  // ====== UI BUILD ======

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.deepPurple.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: 20.h),
          _buildProgressIndicator(),
          SizedBox(height: 24.h),
          _buildMicroSeriesUI(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.deepPurple.withOpacity(0.3)
                : Colors.deepPurple.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(
            Icons.flash_on,
            color: isDark ? Colors.deepPurple.shade200 : Colors.deepPurple,
            size: 20.sp,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'REST-PAUSE ATTIVO',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.deepPurple.shade200 : Colors.deepPurple,
                ),
              ),
              Text(
                'Serie ${widget.currentSeries}/${widget.totalSeries}',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: isDark
                      ? Colors.deepPurple.shade300
                      : Colors.deepPurple.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Micro-serie ${_data.currentMicroSeriesIndex + 1}/$_totalMicroSeries',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.deepPurple.shade200 : Colors.deepPurple,
              ),
            ),
            Text(
              'Target: $_currentTargetReps reps',
              style: TextStyle(
                fontSize: 12.sp,
                color: isDark
                    ? Colors.deepPurple.shade300
                    : Colors.deepPurple.withOpacity(0.8),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        LinearProgressIndicator(
          value: _overallProgress,
          backgroundColor: isDark
              ? Colors.deepPurple.withOpacity(0.3)
              : Colors.deepPurple.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(
              isDark ? Colors.deepPurple.shade300 : Colors.deepPurple
          ),
          minHeight: 6.h,
        ),
        if (_data.completedReps.isNotEmpty) ...[
          SizedBox(height: 8.h),
          Text(
            'Completate: ${_data.actualSequence} (${_data.totalActualReps} reps)',
            style: TextStyle(
              fontSize: 10.sp,
              color: isDark
                  ? Colors.deepPurple.shade400
                  : Colors.deepPurple.withOpacity(0.6),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMicroSeriesUI() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: isDark
                ? colorScheme.surface
                : Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: Colors.deepPurple.withOpacity(isDark ? 0.6 : 0.3),
              width: isDark ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _repsController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.deepPurple,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Ripetizioni eseguite',
                    border: InputBorder.none,
                    labelStyle: TextStyle(
                      color: isDark
                          ? Colors.deepPurple.withOpacity(0.8)
                          : Colors.deepPurple.withOpacity(0.7),
                    ),
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  '${widget.currentWeight.toStringAsFixed(1)} kg',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.deepPurple.shade200 : Colors.deepPurple,
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 20.h),

        SizedBox(
          width: double.infinity,
          height: 50.h,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: ElevatedButton(
                  onPressed: _handleCompleteMicroSeries,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 4,
                  ),
                  child: Text(
                    _isLastMicroSeries
                        ? 'COMPLETA SERIE REST-PAUSE'
                        : 'COMPLETA MICRO-SERIE',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        if (!_isLastMicroSeries) ...[
          SizedBox(height: 12.h),
          Text(
            'Prossima: ${_data.nextTargetReps} reps',
            style: TextStyle(
              fontSize: 12.sp,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.deepPurple.shade400
                  : Colors.deepPurple.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}