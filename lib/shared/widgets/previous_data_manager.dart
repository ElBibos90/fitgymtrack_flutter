import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/workout_design_system.dart';
import '../../features/workouts/domain/entities/completed_series.dart';
import '../../features/workouts/data/services/workout_history_service.dart';

/// 🎯 Previous Data Manager
/// Gestisce lo stato e la logica per il sistema "Usa Dati Precedenti"
class PreviousDataManager extends ChangeNotifier {
  bool _usePreviousData = false;
  Map<int, CompletedSeries> _lastWorkoutSeries = {};
  bool _isLoading = false;
  String? _error;

  // Getters
  bool get usePreviousData => _usePreviousData;
  Map<int, CompletedSeries> get lastWorkoutSeries => _lastWorkoutSeries;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasPreviousData => _lastWorkoutSeries.isNotEmpty;

  /// 🔄 Toggle "Usa dati precedenti"
  void toggleUsePreviousData() {
    _usePreviousData = !_usePreviousData;
    notifyListeners();
  }

  /// 🔄 Set "Usa dati precedenti"
  void setUsePreviousData(bool value) {
    _usePreviousData = value;
    notifyListeners();
  }

  /// 📊 Carica dati precedenti per un esercizio
  Future<void> loadPreviousData({
    required int exerciseId,
    required int userId,
  }) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final history = await WorkoutHistoryService.getExerciseHistory(
        exerciseId: exerciseId,
        userId: userId,
      );

      _lastWorkoutSeries = WorkoutHistoryService.mapLastWorkoutSeries(history);
      _error = null;
    } catch (e) {
      _error = 'Errore nel caricamento dati precedenti: $e';
      _lastWorkoutSeries = {};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 🎯 Ottiene i dati per una serie specifica
  CompletedSeries? getSeriesData(int serieNumber) {
    return _lastWorkoutSeries[serieNumber];
  }

  /// 📊 Ottiene i dati per la serie corrente
  CompletedSeries? getCurrentSeriesData(int currentSeries) {
    return getSeriesData(currentSeries);
  }

  /// 🔄 Carica automaticamente i dati se il flag è attivo
  Future<void> loadDataIfEnabled({
    required int exerciseId,
    required int userId,
    required int currentSeries,
  }) async {
    if (!_usePreviousData) return;

    await loadPreviousData(
      exerciseId: exerciseId,
      userId: userId,
    );
  }

  /// 🧹 Reset dello stato
  void reset() {
    _usePreviousData = false;
    _lastWorkoutSeries = {};
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  /// 📊 Statistiche sui dati precedenti
  Map<String, dynamic> getStatistics() {
    if (_lastWorkoutSeries.isEmpty) {
      return {
        'totalSeries': 0,
        'hasData': false,
        'lastWorkoutDate': null,
      };
    }

    final series = _lastWorkoutSeries.values.toList();
    final lastWorkoutDate = series.first.timestamp;
    final totalSeries = series.length;

    return {
      'totalSeries': totalSeries,
      'hasData': true,
      'lastWorkoutDate': lastWorkoutDate,
      'seriesNumbers': series.map((s) => s.serieNumber).toList(),
    };
  }
}

/// 🎯 Provider per il Previous Data Manager
class PreviousDataProvider extends InheritedWidget {
  final PreviousDataManager manager;

  const PreviousDataProvider({
    Key? key,
    required this.manager,
    required Widget child,
  }) : super(key: key, child: child);

  static PreviousDataManager of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<PreviousDataProvider>();
    if (provider == null) {
      throw Exception('PreviousDataProvider not found in widget tree');
    }
    return provider.manager;
  }

  @override
  bool updateShouldNotify(PreviousDataProvider oldWidget) {
    return manager != oldWidget.manager;
  }
}

/// 🎯 Widget per testare il Previous Data Manager
class PreviousDataTestWidget extends StatefulWidget {
  final int userId;
  final int exerciseId;
  final String exerciseName;

  const PreviousDataTestWidget({
    Key? key,
    required this.userId,
    required this.exerciseId,
    required this.exerciseName,
  }) : super(key: key);

  @override
  _PreviousDataTestWidgetState createState() => _PreviousDataTestWidgetState();
}

class _PreviousDataTestWidgetState extends State<PreviousDataTestWidget> {
  late PreviousDataManager _manager;
  int _currentSeries = 1;

  @override
  void initState() {
    super.initState();
    _manager = PreviousDataManager();
    _loadData();
  }

  Future<void> _loadData() async {
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
          title: Text('Test Previous Data Manager'),
          backgroundColor: WorkoutDesignSystem.surfaceColor,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              // Toggle switch
              _buildToggleSection(),
              
              SizedBox(height: 24.h),
              
              // Serie selector
              _buildSeriesSelector(),
              
              SizedBox(height: 24.h),
              
              // Data display
              _buildDataDisplay(),
              
              SizedBox(height: 24.h),
              
              // Statistics
              _buildStatistics(),
              
              SizedBox(height: 24.h),
              
              // Actions
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleSection() {
    return ListenableBuilder(
      listenable: _manager,
      builder: (context, child) {
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
              Row(
                children: [
                  Icon(
                    Icons.history,
                    color: WorkoutDesignSystem.primary500,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Usa Dati Precedenti',
                    style: WorkoutDesignSystem.heading3.copyWith(
                      color: WorkoutDesignSystem.onSurfaceColor,
                    ),
                  ),
                  Spacer(),
                  Switch(
                    value: _manager.usePreviousData,
                    onChanged: (value) {
                      _manager.setUsePreviousData(value);
                    },
                    activeColor: WorkoutDesignSystem.primary500,
                  ),
                ],
              ),
              
              if (_manager.error != null) ...[
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: WorkoutDesignSystem.error50,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: WorkoutDesignSystem.error200,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: WorkoutDesignSystem.error600,
                        size: 16.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          _manager.error!,
                          style: WorkoutDesignSystem.caption.copyWith(
                            color: WorkoutDesignSystem.error700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSeriesSelector() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Serie Corrente',
            style: WorkoutDesignSystem.captionBold.copyWith(
              color: WorkoutDesignSystem.onSurfaceColor,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: List.generate(5, (index) {
              final seriesNumber = index + 1;
              final isSelected = _currentSeries == seriesNumber;
              
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentSeries = seriesNumber;
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: 8.w),
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? WorkoutDesignSystem.primary500 
                          : WorkoutDesignSystem.neutral100,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: isSelected 
                            ? WorkoutDesignSystem.primary500 
                            : WorkoutDesignSystem.neutral300,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Serie $seriesNumber',
                      textAlign: TextAlign.center,
                      style: WorkoutDesignSystem.caption.copyWith(
                        color: isSelected 
                            ? Colors.white 
                            : WorkoutDesignSystem.onSurfaceColor,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDataDisplay() {
    return ListenableBuilder(
      listenable: _manager,
      builder: (context, child) {
        final seriesData = _manager.getSeriesData(_currentSeries);
        
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dati Serie $_currentSeries',
                style: WorkoutDesignSystem.captionBold.copyWith(
                  color: WorkoutDesignSystem.onSurfaceColor,
                ),
              ),
              SizedBox(height: 12.h),
              
              if (seriesData == null)
                Text(
                  'Nessun dato disponibile per la serie $_currentSeries',
                  style: WorkoutDesignSystem.caption.copyWith(
                    color: WorkoutDesignSystem.neutral500,
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: _buildDataItem(
                        'Peso',
                        '${seriesData.formattedPeso}kg',
                        Icons.fitness_center,
                      ),
                    ),
                    Expanded(
                      child: _buildDataItem(
                        'Reps',
                        seriesData.formattedRipetizioni,
                        Icons.repeat,
                      ),
                    ),
                    Expanded(
                      child: _buildDataItem(
                        'Data',
                        seriesData.formattedDate,
                        Icons.calendar_today,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDataItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 16.sp,
          color: WorkoutDesignSystem.primary500,
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: WorkoutDesignSystem.caption.copyWith(
            color: WorkoutDesignSystem.onSurfaceColor.withOpacity(0.7),
            fontSize: 10.sp,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          style: WorkoutDesignSystem.captionBold.copyWith(
            color: WorkoutDesignSystem.onSurfaceColor,
            fontSize: 12.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildStatistics() {
    return ListenableBuilder(
      listenable: _manager,
      builder: (context, child) {
        final stats = _manager.getStatistics();
        
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Statistiche',
                style: WorkoutDesignSystem.captionBold.copyWith(
                  color: WorkoutDesignSystem.onSurfaceColor,
                ),
              ),
              SizedBox(height: 12.h),
              
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Serie Totali',
                      stats['totalSeries'].toString(),
                      Icons.list,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Ha Dati',
                      stats['hasData'] ? 'Sì' : 'No',
                      Icons.check_circle,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 16.sp,
          color: WorkoutDesignSystem.primary500,
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: WorkoutDesignSystem.caption.copyWith(
            color: WorkoutDesignSystem.onSurfaceColor.withOpacity(0.7),
            fontSize: 10.sp,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          style: WorkoutDesignSystem.captionBold.copyWith(
            color: WorkoutDesignSystem.onSurfaceColor,
            fontSize: 12.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _loadData,
            icon: Icon(Icons.refresh, size: 16.sp),
            label: Text('Ricarica Dati'),
            style: ElevatedButton.styleFrom(
              backgroundColor: WorkoutDesignSystem.primary500,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              _manager.reset();
            },
            icon: Icon(Icons.clear, size: 16.sp),
            label: Text('Reset'),
            style: OutlinedButton.styleFrom(
              foregroundColor: WorkoutDesignSystem.error500,
              side: BorderSide(
                color: WorkoutDesignSystem.error300,
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
