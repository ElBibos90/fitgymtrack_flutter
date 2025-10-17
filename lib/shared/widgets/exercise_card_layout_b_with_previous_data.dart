import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/workout_design_system.dart';
import 'weight_reps_card_with_history.dart';
import 'workout_history_collapsible.dart';
import 'vs_ultima_indicator.dart';
import 'use_previous_data_toggle.dart';
import '../../features/workouts/domain/entities/completed_series.dart';

/// 🏋️ EXERCISE CARD - LAYOUT B WITH PREVIOUS DATA (Side-by-side + Dati Precedenti)
/// Layout unificato per tutti gli esercizi con sistema "Usa Dati Precedenti"
/// Compatibile con superset, circuit e esercizi singoli
class ExerciseCardLayoutBWithPreviousData extends StatefulWidget {
  final String exerciseName;
  final List<String> muscleGroups;
  final String? exerciseImageUrl;
  final double weight;
  final int reps;
  final int currentSeries;
  final int totalSeries;
  final int? restSeconds;
  final bool isModified;
  final bool isCompleted;
  final bool isTimerActive;
  final VoidCallback onEditParameters;
  final VoidCallback onCompleteSeries;
  final Function(String url, dynamic error)? onImageLoadError;
  
  // Superset/Circuit specific
  final String? groupType;
  final List<String>? groupExerciseNames;
  final int? currentExerciseIndex;
  final bool showWarning;
  
  // Previous data specific
  final int userId;
  final int exerciseId;
  final Map<int, CompletedSeries>? lastWorkoutSeries; // serie_number -> CompletedSeries
  final bool usePreviousData;
  final ValueChanged<bool> onUsePreviousDataChanged;
  final ValueChanged<Map<String, dynamic>>? onDataChanged; // peso, ripetizioni

  const ExerciseCardLayoutBWithPreviousData({
    super.key,
    required this.exerciseName,
    required this.muscleGroups,
    this.exerciseImageUrl,
    required this.weight,
    required this.reps,
    required this.currentSeries,
    required this.totalSeries,
    this.restSeconds,
    required this.isModified,
    required this.isCompleted,
    required this.isTimerActive,
    required this.onEditParameters,
    required this.onCompleteSeries,
    this.onImageLoadError,
    this.groupType,
    this.groupExerciseNames,
    this.currentExerciseIndex,
    this.showWarning = false,
    required this.userId,
    required this.exerciseId,
    this.lastWorkoutSeries,
    required this.usePreviousData,
    required this.onUsePreviousDataChanged,
    this.onDataChanged,
  });

  @override
  _ExerciseCardLayoutBWithPreviousDataState createState() => _ExerciseCardLayoutBWithPreviousDataState();
}

class _ExerciseCardLayoutBWithPreviousDataState extends State<ExerciseCardLayoutBWithPreviousData> {
  bool _showHistory = false;
  double _currentWeight = 0.0;
  int _currentReps = 0;

  @override
  void initState() {
    super.initState();
    _currentWeight = widget.weight;
    _currentReps = widget.reps;
    _loadPreviousDataIfEnabled();
  }

  @override
  void didUpdateWidget(ExerciseCardLayoutBWithPreviousData oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Se il flag "usa dati precedenti" è cambiato, aggiorna i dati
    if (widget.usePreviousData != oldWidget.usePreviousData) {
      _loadPreviousDataIfEnabled();
    }
    
    // Se la serie corrente è cambiata, aggiorna i dati
    if (widget.currentSeries != oldWidget.currentSeries) {
      _loadPreviousDataIfEnabled();
    }
  }

  void _loadPreviousDataIfEnabled() {
    if (!widget.usePreviousData || widget.lastWorkoutSeries == null) {
      return;
    }

    final previousSeries = widget.lastWorkoutSeries![widget.currentSeries];
    if (previousSeries != null) {
      setState(() {
        _currentWeight = previousSeries.peso;
        _currentReps = previousSeries.ripetizioni;
      });
      
      // Notifica il parent widget del cambio dati
      if (widget.onDataChanged != null) {
        widget.onDataChanged!({
          'peso': _currentWeight,
          'ripetizioni': _currentReps,
        });
      }
    }
  }

  void _onWeightChanged(double newWeight) {
    setState(() {
      _currentWeight = newWeight);
    });
    
    if (widget.onDataChanged != null) {
      widget.onDataChanged!({
        'peso': _currentWeight,
        'ripetizioni': _currentReps,
      });
    }
  }

  void _onRepsChanged(int newReps) {
    setState(() {
      _currentReps = newReps;
    });
    
    if (widget.onDataChanged != null) {
      widget.onDataChanged!({
        'peso': _currentWeight,
        'ripetizioni': _currentReps,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Superset/Circuit indicators (se applicabile)
        if (widget.groupType != null) ...[
          _buildGroupIndicators(context),
          SizedBox(height: WorkoutDesignSystem.spacingM.h),
        ],
        
        // Warning (se superset/circuit)
        if (widget.showWarning) ...[
          _buildWarning(context),
          SizedBox(height: WorkoutDesignSystem.spacingM.h),
        ],

        // Toggle "Usa dati precedenti"
        _buildPreviousDataToggle(context),

        // Main exercise content
        _buildExerciseContent(context),
        
        // Storio collapsible
        if (_showHistory) ...[
          SizedBox(height: 16.h),
          WorkoutHistoryCollapsible(
            userId: widget.userId,
            exerciseId: widget.exerciseId,
            exerciseName: widget.exerciseName,
            exerciseImage: widget.exerciseImageUrl ?? '',
          ),
        ],
      ],
    );
  }

  /// 🔄 Toggle "Usa dati precedenti"
  Widget _buildPreviousDataToggle(BuildContext context) {
    final hasPreviousData = widget.lastWorkoutSeries != null && 
                           widget.lastWorkoutSeries!.containsKey(widget.currentSeries);
    
    return Column(
      children: [
        // Toggle switch
        UsePreviousDataToggle(
          value: widget.usePreviousData,
          onChanged: widget.onUsePreviousDataChanged,
          isEnabled: hasPreviousData && !widget.isCompleted,
        ),
        
        // Status badge se usando dati precedenti
        if (widget.usePreviousData && hasPreviousData) ...[
          SizedBox(height: 8.h),
          PreviousDataStatusBadge(
            isUsingPreviousData: widget.usePreviousData,
            hasPreviousData: hasPreviousData,
            previousDataInfo: 'Serie ${widget.currentSeries} dell\'ultimo allenamento',
          ),
        ],
        
        // Info card con dati precedenti
        if (widget.usePreviousData && hasPreviousData) ...[
          SizedBox(height: 8.h),
          PreviousDataInfoCard(
            lastWorkoutSeries: widget.lastWorkoutSeries!,
            currentSeries: widget.currentSeries,
            onViewHistory: () {
              setState(() {
                _showHistory = !_showHistory;
              });
            },
          ),
        ],
      ],
    );
  }

  /// 🔗 Group indicators (Superset/Circuit)
  Widget _buildGroupIndicators(BuildContext context) {
    final isSuperset = widget.groupType == 'superset';
    final icon = isSuperset ? '🔗' : '🔄';
    final title = isSuperset ? 'SUPERSET' : 'CIRCUIT';
    final exerciseCount = widget.groupExerciseNames?.length ?? 0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isSuperset 
              ? [WorkoutDesignSystem.supersetPurple600, WorkoutDesignSystem.supersetPurple700]
              : [WorkoutDesignSystem.circuitOrange600, WorkoutDesignSystem.circuitOrange700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: WorkoutDesignSystem.borderRadiusM,
        boxShadow: _getCardShadow(context),
      ),
      child: Padding(
        padding: EdgeInsets.all(WorkoutDesignSystem.spacingM.w),
        child: Row(
          children: [
            Text(
              icon,
              style: TextStyle(fontSize: 20.sp),
            ),
            SizedBox(width: WorkoutDesignSystem.spacingS.w),
            Text(
              title,
              style: WorkoutDesignSystem.heading3.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: WorkoutDesignSystem.spacingS.w),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: WorkoutDesignSystem.spacingS.w,
                vertical: 4.h,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                '$exerciseCount esercizi',
                style: WorkoutDesignSystem.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ⚠️ Warning per superset/circuit
  Widget _buildWarning(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(WorkoutDesignSystem.spacingM.w),
      decoration: BoxDecoration(
        color: WorkoutDesignSystem.warning50,
        borderRadius: WorkoutDesignSystem.borderRadiusM,
        border: Border.all(
          color: WorkoutDesignSystem.warning200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: WorkoutDesignSystem.warning600,
            size: 20.sp,
          ),
          SizedBox(width: WorkoutDesignSystem.spacingS.w),
          Expanded(
            child: Text(
              'Completa tutti gli esercizi del gruppo prima di passare al prossimo',
              style: WorkoutDesignSystem.caption.copyWith(
                color: WorkoutDesignSystem.warning700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🏋️ Main exercise content
  Widget _buildExerciseContent(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: WorkoutDesignSystem.surfaceColor,
        borderRadius: WorkoutDesignSystem.borderRadiusL,
        boxShadow: _getCardShadow(context),
        border: Border.all(
          color: WorkoutDesignSystem.borderColor,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header con nome esercizio e toggle storico
          _buildExerciseHeader(context),
          
          // Content principale
          Padding(
            padding: EdgeInsets.all(WorkoutDesignSystem.spacingL.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Immagine esercizio
                _buildExerciseImage(context),
                
                SizedBox(width: WorkoutDesignSystem.spacingM.w),
                
                // Informazioni esercizio
                Expanded(
                  child: _buildExerciseInfo(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 📸 Immagine esercizio
  Widget _buildExerciseImage(BuildContext context) {
    return Container(
      width: 80.w,
      height: 80.w,
      decoration: BoxDecoration(
        borderRadius: WorkoutDesignSystem.borderRadiusM,
        border: Border.all(
          color: WorkoutDesignSystem.borderColor,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: WorkoutDesignSystem.borderRadiusM,
        child: widget.exerciseImageUrl != null
            ? CachedNetworkImage(
                imageUrl: widget.exerciseImageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => _buildImagePlaceholder(),
                errorWidget: (context, url, error) {
                  if (widget.onImageLoadError != null) {
                    widget.onImageLoadError!(url, error);
                  }
                  return _buildImagePlaceholder();
                },
              )
            : _buildImagePlaceholder(),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: WorkoutDesignSystem.neutral100,
      child: Icon(
        Icons.fitness_center,
        color: WorkoutDesignSystem.neutral400,
        size: 32.sp,
      ),
    );
  }

  /// ℹ️ Informazioni esercizio
  Widget _buildExerciseInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nome esercizio
        Text(
          widget.exerciseName,
          style: WorkoutDesignSystem.heading3.copyWith(
            color: WorkoutDesignSystem.onSurfaceColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        SizedBox(height: WorkoutDesignSystem.spacingS.h),
        
        // Gruppi muscolari
        if (widget.muscleGroups.isNotEmpty) ...[
          Wrap(
            spacing: 4.w,
            runSpacing: 4.h,
            children: widget.muscleGroups.map((muscle) => _buildMuscleTag(muscle)).toList(),
          ),
          SizedBox(height: WorkoutDesignSystem.spacingM.h),
        ],
        
        // Serie progress
        _buildSeriesProgress(context),
        
        SizedBox(height: WorkoutDesignSystem.spacingM.h),
        
        // Peso e ripetizioni con storico
        _buildWeightRepsWithHistory(context),
        
        SizedBox(height: WorkoutDesignSystem.spacingM.h),
        
        // Timer info
        if (widget.restSeconds != null) ...[
          _buildRestInfo(context),
          SizedBox(height: WorkoutDesignSystem.spacingM.h),
        ],
        
        // Action buttons
        _buildActionButtons(context),
      ],
    );
  }

  /// 🏷️ Muscle tag
  Widget _buildMuscleTag(String muscle) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 8.w,
        vertical: 4.h,
      ),
      decoration: BoxDecoration(
        color: WorkoutDesignSystem.primary50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: WorkoutDesignSystem.primary200,
          width: 1,
        ),
      ),
      child: Text(
        muscle,
        style: WorkoutDesignSystem.caption.copyWith(
          color: WorkoutDesignSystem.primary700,
          fontWeight: FontWeight.w600,
          fontSize: 10.sp,
        ),
      ),
    );
  }

  /// 📊 Serie progress
  Widget _buildSeriesProgress(BuildContext context) {
    final progress = widget.currentSeries / widget.totalSeries;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Serie',
              style: WorkoutDesignSystem.caption.copyWith(
                color: WorkoutDesignSystem.onSurfaceColor.withOpacity(0.7),
              ),
            ),
            Text(
              '${widget.currentSeries}/${widget.totalSeries}',
              style: WorkoutDesignSystem.captionBold.copyWith(
                color: WorkoutDesignSystem.onSurfaceColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: WorkoutDesignSystem.neutral200,
          valueColor: AlwaysStoppedAnimation<Color>(
            widget.isCompleted 
                ? WorkoutDesignSystem.success500 
                : WorkoutDesignSystem.primary500,
          ),
        ),
      ],
    );
  }

  /// ⚖️ Peso e ripetizioni con storico
  Widget _buildWeightRepsWithHistory(BuildContext context) {
    final lastSeries = widget.lastWorkoutSeries?[widget.currentSeries];
    
    return WeightRepsCombinedWithHistory(
      peso: _currentWeight,
      ripetizioni: _currentReps,
      serieNumber: widget.currentSeries,
      lastWorkoutSeries: lastSeries,
      onPesoEdit: () {
        _showWeightEditDialog(context);
      },
      onRepsEdit: () {
        _showRepsEditDialog(context);
      },
      isEditable: !widget.isCompleted,
    );
  }

  /// ⏱️ Rest info
  Widget _buildRestInfo(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12.w,
        vertical: 8.h,
      ),
      decoration: BoxDecoration(
        color: WorkoutDesignSystem.neutral50,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: WorkoutDesignSystem.neutral200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.timer_outlined,
            size: 16.sp,
            color: WorkoutDesignSystem.neutral600,
          ),
          SizedBox(width: 8.w),
          Text(
            'Recupero: ${widget.restSeconds}s',
            style: WorkoutDesignSystem.caption.copyWith(
              color: WorkoutDesignSystem.neutral700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// 🎯 Action buttons
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        // Toggle storico
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _showHistory = !_showHistory;
              });
            },
            icon: Icon(
              _showHistory ? Icons.history : Icons.history,
              size: 16.sp,
            ),
            label: Text(
              _showHistory ? 'Nascondi Storico' : 'Mostra Storico',
              style: WorkoutDesignSystem.captionBold,
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: WorkoutDesignSystem.primary600,
              side: BorderSide(
                color: WorkoutDesignSystem.primary200,
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
        ),
        
        SizedBox(width: 12.w),
        
        // Complete series button
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: widget.isCompleted ? null : widget.onCompleteSeries,
            icon: Icon(
              widget.isCompleted ? Icons.check_circle : Icons.play_arrow,
              size: 16.sp,
            ),
            label: Text(
              widget.isCompleted ? 'Completato' : 'Completa Serie',
              style: WorkoutDesignSystem.captionBold.copyWith(
                color: widget.isCompleted 
                    ? WorkoutDesignSystem.onSurfaceColor.withOpacity(0.7)
                    : Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.isCompleted 
                  ? WorkoutDesignSystem.neutral300 
                  : WorkoutDesignSystem.primary500,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 📋 Exercise header
  Widget _buildExerciseHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(WorkoutDesignSystem.spacingM.w),
      decoration: BoxDecoration(
        color: WorkoutDesignSystem.neutral50,
        borderRadius: BorderRadius.only(
          topLeft: WorkoutDesignSystem.borderRadiusL,
          topRight: WorkoutDesignSystem.borderRadiusL,
        ),
        border: Border(
          bottom: BorderSide(
            color: WorkoutDesignSystem.borderColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.exerciseName,
              style: WorkoutDesignSystem.heading3.copyWith(
                color: WorkoutDesignSystem.onSurfaceColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (widget.isModified)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 8.w,
                vertical: 4.h,
              ),
              decoration: BoxDecoration(
                color: WorkoutDesignSystem.warning100,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: WorkoutDesignSystem.warning300,
                  width: 1,
                ),
              ),
              child: Text(
                'Modificato',
                style: WorkoutDesignSystem.caption.copyWith(
                  color: WorkoutDesignSystem.warning700,
                  fontWeight: FontWeight.w600,
                  fontSize: 10.sp,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 🎨 Card shadow
  List<BoxShadow> _getCardShadow(BuildContext context) {
    return [
      BoxShadow(
        color: WorkoutDesignSystem.neutral200.withOpacity(0.5),
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ];
  }

  /// 📝 Dialog per modificare peso
  void _showWeightEditDialog(BuildContext context) {
    final controller = TextEditingController(text: _currentWeight.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifica Peso'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Peso (kg)',
            suffixText: 'kg',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              final newWeight = double.tryParse(controller.text);
              if (newWeight != null && newWeight > 0) {
                _onWeightChanged(newWeight);
                Navigator.pop(context);
              }
            },
            child: Text('Conferma'),
          ),
        ],
      ),
    );
  }

  /// 📝 Dialog per modificare ripetizioni
  void _showRepsEditDialog(BuildContext context) {
    final controller = TextEditingController(text: _currentReps.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifica Ripetizioni'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Ripetizioni',
            suffixText: 'reps',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              final newReps = int.tryParse(controller.text);
              if (newReps != null && newReps > 0) {
                _onRepsChanged(newReps);
                Navigator.pop(context);
              }
            },
            child: Text('Conferma'),
          ),
        ],
      ),
    );
  }
}
