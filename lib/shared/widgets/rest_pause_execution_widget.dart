// 🚀 STEP 2: REST-PAUSE Execution Widget
// File: lib/shared/widgets/rest_pause_execution_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'rest_pause_timer_popup.dart'; // 🚀 STEP 3: Import timer popup

/// Widget dedicato per l'esecuzione REST-PAUSE
/// Gestisce micro-serie con UI dedicata e stato interno
class RestPauseExecutionWidget extends StatefulWidget {
  final String exerciseName;
  final String restPauseSequence; // "11+4+4"
  final int restSeconds; // 21
  final double currentWeight;
  final int currentSeries; // Serie corrente (1, 2, 3...)
  final int totalSeries; // Totale serie dell'esercizio
  final VoidCallback? onCompleteAllMicroSeries;
  final Function(int microSeriesIndex, int reps)? onCompleteMicroSeries;

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
  List<int> _microSeriesSequence = []; // [11, 4, 4]
  int _currentMicroSeriesIndex = 0; // 0, 1, 2
  List<int> _completedReps = []; // Reps effettivamente completate per ogni micro-serie
  // 🚀 STEP 3: Rimosso _isInRestPause e _restTimeRemaining (gestiti dal popup)

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
    print('🔥 [REST-PAUSE WIDGET] Initializing widget for: ${widget.exerciseName}');

    _initializeAnimations();
    _parseSequence();
    _resetToFirstMicroSeries();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  // ====== INITIALIZATION METHODS ======

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

  /// 🚀 STEP 2: Parsing sicuro della sequenza REST-PAUSE
  void _parseSequence() {
    try {
      if (widget.restPauseSequence.isNotEmpty) {
        _microSeriesSequence = widget.restPauseSequence
            .split('+')
            .map((s) => int.tryParse(s.trim()) ?? 0)
            .where((reps) => reps > 0)
            .toList();

        print('🔥 [REST-PAUSE WIDGET] Parsed sequence: $_microSeriesSequence');
      } else {
        print('⚠️ [REST-PAUSE WIDGET] Empty sequence, using fallback');
        _microSeriesSequence = [10]; // Fallback sicuro
      }

      // Inizializza array per tracciare reps completate
      _completedReps = List.filled(_microSeriesSequence.length, 0);

    } catch (e) {
      print('❌ [REST-PAUSE WIDGET] Error parsing sequence: $e');
      _microSeriesSequence = [10]; // Fallback sicuro
      _completedReps = [0];
    }
  }

  void _resetToFirstMicroSeries() {
    setState(() {
      _currentMicroSeriesIndex = 0;
      _repsController.text = _microSeriesSequence.isNotEmpty
          ? _microSeriesSequence[0].toString()
          : '10';
    });
    _progressController.reset();
  }

  // ====== UI HELPER METHODS ======

  bool get _isLastMicroSeries => _currentMicroSeriesIndex >= _microSeriesSequence.length - 1;

  int get _currentTargetReps => _microSeriesSequence.isNotEmpty
      ? _microSeriesSequence[_currentMicroSeriesIndex]
      : 10;

  int get _totalMicroSeries => _microSeriesSequence.length;

  double get _overallProgress => _totalMicroSeries > 0
      ? (_currentMicroSeriesIndex + 1) / _totalMicroSeries
      : 0.0;

  // ====== ACTION METHODS ======

  void _handleCompleteMicroSeries() {
    final enteredReps = int.tryParse(_repsController.text) ?? _currentTargetReps;

    print('🔥 [REST-PAUSE WIDGET] Micro-series ${_currentMicroSeriesIndex + 1} completed: $enteredReps reps');

    // Salva reps completate
    _completedReps[_currentMicroSeriesIndex] = enteredReps;

    // Callback per informare il parent
    widget.onCompleteMicroSeries?.call(_currentMicroSeriesIndex, enteredReps);

    if (_isLastMicroSeries) {
      // Ultima micro-serie: completa tutto
      _handleCompleteAllSeries();
    } else {
      // Inizia mini-recupero per prossima micro-serie
      _startMiniRecovery();
    }
  }

  void _startMiniRecovery() {
    setState(() {
      _currentMicroSeriesIndex++;
    });

    print('🔥 [REST-PAUSE WIDGET] Starting mini-recovery: ${widget.restSeconds}s');

    // 🚀 STEP 3: Usa il nuovo timer popup dedicato
    _showRestPauseTimer();
  }

  /// 🚀 STEP 3: Mostra il timer popup dedicato
  void _showRestPauseTimer() {
    // Import necessario sarà aggiunto al file
    RestPauseTimerHelper.showRestPauseTimer(
      context: context,
      seconds: widget.restSeconds,
      exerciseName: widget.exerciseName,
      currentMicroSeries: _currentMicroSeriesIndex + 1,
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

    print('🔥 [REST-PAUSE WIDGET] Mini-recovery ended, ready for micro-series ${_currentMicroSeriesIndex + 1}');
  }

  void _handleCompleteAllSeries() {
    print('🔥 [REST-PAUSE WIDGET] All micro-series completed! Total reps: ${_completedReps.fold(0, (a, b) => a + b)}');

    _progressController.forward();
    widget.onCompleteAllMicroSeries?.call();
  }

  // ====== UI BUILD METHODS ======

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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

          // 🚀 STEP 3: Solo UI micro-serie (timer è popup dedicato)
          _buildMicroSeriesUI(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: Colors.deepPurple.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(
            Icons.flash_on,
            color: Colors.deepPurple,
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
                  color: Colors.deepPurple,
                ),
              ),
              Text(
                'Serie ${widget.currentSeries}/${widget.totalSeries}',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.deepPurple.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Micro-serie ${_currentMicroSeriesIndex + 1}/$_totalMicroSeries',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.deepPurple,
              ),
            ),
            Text(
              'Target: $_currentTargetReps reps',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.deepPurple.withOpacity(0.8),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        LinearProgressIndicator(
          value: _overallProgress,
          backgroundColor: Colors.deepPurple.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
          minHeight: 6.h,
        ),
      ],
    );
  }

  Widget _buildMicroSeriesUI() {
    return Column(
      children: [
        // Input ripetizioni
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
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
                    color: Colors.deepPurple,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Ripetizioni eseguite',
                    border: InputBorder.none,
                    labelStyle: TextStyle(
                      color: Colors.deepPurple.withOpacity(0.7),
                    ),
                  ),
                ),
              ),
              Text(
                '${widget.currentWeight.toStringAsFixed(1)} kg',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.deepPurple.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 20.h),

        // Pulsante completa micro-serie
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
            'Prossima: ${_microSeriesSequence[_currentMicroSeriesIndex + 1]} reps',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.deepPurple.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// 🚀 STEP 2: Helper per test isolato del widget
class RestPauseTestScreen extends StatelessWidget {
  const RestPauseTestScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('REST-PAUSE Widget Test'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            Text(
              'Test del Widget REST-PAUSE isolato',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20.h),
            RestPauseExecutionWidget(
              exerciseName: 'Dips assistiti',
              restPauseSequence: '11+4+4',
              restSeconds: 21,
              currentWeight: 66.0,
              currentSeries: 1,
              totalSeries: 5,
              onCompleteAllMicroSeries: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Serie REST-PAUSE completata!')),
                );
              },
              onCompleteMicroSeries: (index, reps) {
                print('Micro-serie ${index + 1} completata: $reps reps');
              },
            ),
          ],
        ),
      ),
    );
  }
}