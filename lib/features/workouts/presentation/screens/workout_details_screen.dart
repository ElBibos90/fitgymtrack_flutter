// lib/features/workouts/presentation/screens/workout_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../../shared/widgets/custom_snackbar.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../bloc/workout_history_bloc.dart';
import '../../models/active_workout_models.dart';
import '../../repository/workout_repository.dart';
import 'edit_series_dialog.dart';

/// 🏋️ WORKOUT DETAILS SCREEN: Dettagli completi di un allenamento con gestione serie
class WorkoutDetailsScreen extends StatefulWidget {
  final int workoutId;
  final String workoutName;
  final DateTime workoutDate;

  const WorkoutDetailsScreen({
    super.key,
    required this.workoutId,
    required this.workoutName,
    required this.workoutDate,
  });

  @override
  State<WorkoutDetailsScreen> createState() => _WorkoutDetailsScreenState();
}

class _WorkoutDetailsScreenState extends State<WorkoutDetailsScreen> {
  late final WorkoutHistoryBloc _workoutHistoryBloc;

  @override
  void initState() {
    super.initState();
    // Creiamo un nuovo BLoC locale invece di usare il singleton
    _workoutHistoryBloc = WorkoutHistoryBloc(
      workoutRepository: getIt<WorkoutRepository>(),
    );
    //print('[DEBUG] [workout_details_screen] BLoC instance: ${_workoutHistoryBloc.hashCode}');
    _workoutHistoryBloc.loadWorkoutSeriesDetail(widget.workoutId);
  }

  @override
  void dispose() {
    // Chiudiamo il BLoC locale
    _workoutHistoryBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: widget.workoutName,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              // Se non possiamo fare pop, torniamo allo storico allenamenti
              context.go('/workouts/history');
            }
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: AppColors.indigo600,
              size: 24.sp,
            ),
            onPressed: () => _workoutHistoryBloc.loadWorkoutSeriesDetail(widget.workoutId),
            tooltip: 'Aggiorna',
          ),
        ],
      ),
      body: BlocProvider<WorkoutHistoryBloc>(
        create: (context) => _workoutHistoryBloc,
        child: BlocListener<WorkoutHistoryBloc, WorkoutHistoryState>(
          listener: (context, state) {
            if (state is WorkoutHistoryOperationSuccess) {
              CustomSnackbar.show(
                context,
                message: state.message,
                isSuccess: true,
              );
              
              // Ricarica i dettagli dopo operazioni di successo
              _workoutHistoryBloc.loadWorkoutSeriesDetail(widget.workoutId);
            } else if (state is WorkoutHistoryError) {
              CustomSnackbar.show(
                context,
                message: state.message,
                isSuccess: false,
              );
            }
          },
          child: BlocBuilder<WorkoutHistoryBloc, WorkoutHistoryState>(
            builder: (context, state) {
              //print('[DEBUG] [workout_details_screen] Current state: ${state.runtimeType}');
              if (state is WorkoutSeriesDetailLoaded) {
                //print('[DEBUG] [workout_details_screen] Received WorkoutSeriesDetailLoaded with ${state.seriesDetails.length} series');
              }
              return LoadingOverlay(
                isLoading: state is WorkoutHistoryLoading,
                child: _buildBody(context, state),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WorkoutHistoryState state) {
    //print('[DEBUG] [workout_details_screen] _buildBody called with state: ${state.runtimeType}');
    
    if (state is WorkoutHistoryLoading) {
      //print('[DEBUG] [workout_details_screen] Showing loading state');
      return _buildLoadingState();
    }

    if (state is WorkoutSeriesDetailLoaded) {
      //print('[DEBUG] [workout_details_screen] Showing series list with ${state.seriesDetails.length} series');
      return _buildSeriesList(context, state.seriesDetails);
    }

    if (state is WorkoutHistoryError) {
      //print('[DEBUG] [workout_details_screen] Showing error state: ${state.message}');
      return _buildErrorState(state);
    }

    // Se lo stato è iniziale, mostriamo il loading con un timeout
    //print('[DEBUG] [workout_details_screen] Showing loading state with timeout');
    return _buildLoadingStateWithTimeout();
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Caricamento dettagli allenamento...'),
        ],
      ),
    );
  }

  Widget _buildLoadingStateWithTimeout() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          const Text('Caricamento dettagli allenamento...'),
          const SizedBox(height: 8),
          Text(
            'Se il caricamento è lento, controlla la connessione',
            style: TextStyle(
              fontSize: 12.sp,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => _workoutHistoryBloc.loadWorkoutSeriesDetail(widget.workoutId),
            child: const Text('Riprova'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(WorkoutHistoryError errorState) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64.sp,
              color: AppColors.error,
            ),
            SizedBox(height: 16.h),
            Text(
              errorState.message,
              style: TextStyle(
                fontSize: 16.sp,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: () => _workoutHistoryBloc.loadWorkoutSeriesDetail(widget.workoutId),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Riprova'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.indigo600,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeriesList(BuildContext context, List<CompletedSeriesData> seriesDetails) {
    if (seriesDetails.isEmpty) {
      return _buildEmptyState();
    }

    // Raggruppa le serie per esercizio
    final Map<String, List<CompletedSeriesData>> groupedSeries = {};
    for (final series in seriesDetails) {
      final exerciseName = series.esercizioNome ?? 'Esercizio sconosciuto';
      if (!groupedSeries.containsKey(exerciseName)) {
        groupedSeries[exerciseName] = [];
      }
      groupedSeries[exerciseName]!.add(series);
    }

    return RefreshIndicator(
        onRefresh: () async {
          _workoutHistoryBloc.loadWorkoutSeriesDetail(widget.workoutId);
        },
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: groupedSeries.length,
        itemBuilder: (context, index) {
          final exerciseName = groupedSeries.keys.elementAt(index);
          final exerciseSeries = groupedSeries[exerciseName]!;
          
          return _buildExerciseGroup(context, exerciseName, exerciseSeries);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center_outlined,
              size: 64.sp,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 16.h),
            Text(
              'Nessuna serie trovata',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Questo allenamento non contiene serie completate.',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseGroup(BuildContext context, String exerciseName, List<CompletedSeriesData> series) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: isDarkMode 
            ? AppColors.surfaceDark.withValues(alpha: 0.8)
            : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isDarkMode 
              ? AppColors.border.withValues(alpha: 0.2)
              : AppColors.border.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header esercizio
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: isDarkMode 
                  ? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                  : Colors.grey[100],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12.r),
                topRight: Radius.circular(12.r),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.fitness_center_rounded,
                  color: isDarkMode 
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey[600],
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    exerciseName,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode 
                          ? Theme.of(context).textTheme.titleMedium?.color
                          : Colors.grey[800],
                    ),
                  ),
                ),
                Text(
                  '${series.length} serie',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isDarkMode 
                        ? Theme.of(context).textTheme.bodyMedium?.color
                        : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Lista serie
          ...series.asMap().entries.map((entry) {
            final index = entry.key;
            final seriesData = entry.value;
            final isLast = index == series.length - 1;
            
            return _buildSeriesItem(context, seriesData, isLast);
          }),
        ],
      ),
    );
  }

  Widget _buildSeriesItem(BuildContext context, CompletedSeriesData series, bool isLast) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        border: isLast ? null : Border(
          bottom: BorderSide(
            color: isDarkMode 
                ? AppColors.border.withValues(alpha: 0.1)
                : AppColors.border.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showEditSeriesDialog(series),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                // Numero serie
                Container(
                  width: 32.w,
                  height: 32.w,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Center(
                    child: Text(
                      '${series.serieNumber ?? 1}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
                
                SizedBox(width: 12.w),
                
                // Dettagli serie
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildSeriesStat(
                            icon: Icons.scale_rounded,
                            label: 'Peso',
                            value: '${series.peso} kg',
                          ),
                          SizedBox(width: 16.w),
                          _buildSeriesStat(
                            icon: Icons.repeat_rounded,
                            label: 'Ripetizioni',
                            value: '${series.ripetizioni}',
                          ),
                        ],
                      ),
                      
                      if (series.tempoRecupero != null && series.tempoRecupero! > 0) ...[
                        SizedBox(height: 4.h),
                        _buildSeriesStat(
                          icon: Icons.timer_rounded,
                          label: 'Recupero',
                          value: '${series.tempoRecupero}s',
                        ),
                      ],
                      
                      if (series.note != null && series.note!.isNotEmpty) ...[
                        SizedBox(height: 4.h),
                        Row(
                          children: [
                            Icon(
                              Icons.note_rounded,
                              size: 12.sp,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            SizedBox(width: 4.w),
                            Expanded(
                              child: Text(
                                series.note!,
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Menu azioni
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: AppColors.textSecondary,
                    size: 20.sp,
                  ),
                  onSelected: (value) => _handleSeriesAction(value, series),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Modifica'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_rounded, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Elimina', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeriesStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12.sp,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        SizedBox(width: 4.w),
        Text(
          '$label: $value',
          style: TextStyle(
            fontSize: 12.sp,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _showEditSeriesDialog(CompletedSeriesData series) {
    showDialog(
      context: context,
      builder: (context) => EditSeriesDialog(
        series: series,
        onSave: (weight, reps, recoveryTime, notes) {
          _workoutHistoryBloc.updateCompletedSeries(
            series.id,
            weight,
            reps,
            widget.workoutId,
            recoveryTime: recoveryTime,
            notes: notes,
          );
        },
      ),
    );
  }

  void _handleSeriesAction(String action, CompletedSeriesData series) {
    switch (action) {
      case 'edit':
        _showEditSeriesDialog(series);
        break;
      case 'delete':
        _showDeleteSeriesDialog(series);
        break;
    }
  }

  void _showDeleteSeriesDialog(CompletedSeriesData series) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina Serie'),
        content: Text(
          'Sei sicuro di voler eliminare questa serie?\n\n'
          'Peso: ${series.peso} kg\n'
          'Ripetizioni: ${series.ripetizioni}\n\n'
          'Questa azione non può essere annullata.',
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () {
              context.pop();
              _workoutHistoryBloc.deleteCompletedSeries(series.id, widget.workoutId);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }

}