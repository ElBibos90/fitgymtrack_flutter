// lib/features/workouts/presentation/screens/workout_history_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../../shared/widgets/custom_snackbar.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../bloc/workout_history_bloc.dart';
import '../../repository/workout_repository.dart';
import '../../../stats/models/user_stats_models.dart';

/// 🏋️ WORKOUT HISTORY SCREEN: Gestione completa dello storico allenamenti
class WorkoutHistoryScreen extends StatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  late final WorkoutHistoryBloc _workoutHistoryBloc;
  late final SessionService _sessionService;
  
  int? _currentUserId;
  String _selectedFilter = 'Tutti'; // 'Tutti', 'Ultima settimana', 'Ultimo mese'
  
  final List<String> _filterOptions = [
    'Tutti',
    'Ultima settimana', 
    'Ultimo mese',
    'Ultimi 3 mesi'
  ];

  @override
  void initState() {
    super.initState();
    _sessionService = getIt<SessionService>();
    // Creiamo un nuovo BLoC locale invece di usare il singleton
    _workoutHistoryBloc = WorkoutHistoryBloc(
      workoutRepository: getIt<WorkoutRepository>(),
    );
    _loadUserAndHistory();
  }

  @override
  void dispose() {
    _workoutHistoryBloc.close();
    super.dispose();
  }

  Future<void> _loadUserAndHistory() async {
    try {
      final userId = await _sessionService.getCurrentUserId();
      if (userId != null && mounted) {
        setState(() {
          _currentUserId = userId;
        });
        _workoutHistoryBloc.loadWorkoutHistory(userId);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(
          context,
          message: 'Errore nel caricamento dei dati utente: $e',
          isSuccess: false,
        );
      }
    }
  }

  List<WorkoutHistory> _filterWorkouts(List<WorkoutHistory> workouts) {
    if (_selectedFilter == 'Tutti') return workouts;
    
    final now = DateTime.now();
    final filtered = workouts.where((workout) {
      final workoutDate = DateTime.parse(workout.dataAllenamento);
      final difference = now.difference(workoutDate);
      
      switch (_selectedFilter) {
        case 'Ultima settimana':
          return difference.inDays <= 7;
        case 'Ultimo mese':
          return difference.inDays <= 30;
        case 'Ultimi 3 mesi':
          return difference.inDays <= 90;
        default:
          return true;
      }
    }).toList();
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Storico Allenamenti',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              // Se non possiamo fare pop, torniamo alla dashboard
              context.go('/dashboard');
            }
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list_rounded,
              color: AppColors.indigo600,
              size: 24.sp,
            ),
            onPressed: _showFilterDialog,
            tooltip: 'Filtri',
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
              
              // Ricarica la cronologia dopo operazioni di successo
              if (_currentUserId != null) {
                _workoutHistoryBloc.refreshWorkoutHistory(_currentUserId!);
              }
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
    if (state is WorkoutHistoryInitial || state is WorkoutHistoryLoading) {
      return _buildLoadingState();
    }

    if (state is WorkoutHistoryLoaded) {
      final filteredWorkouts = _filterWorkouts(state.workoutHistory);
      return _buildWorkoutList(context, filteredWorkouts);
    }

    if (state is WorkoutHistoryError) {
      return _buildErrorState(state);
    }

    return _buildLoadingState();
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Caricamento storico allenamenti...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(WorkoutHistoryError errorState) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
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
                color: isDarkMode 
                    ? Theme.of(context).textTheme.bodyMedium?.color
                    : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: _currentUserId != null 
                  ? () => _workoutHistoryBloc.loadWorkoutHistory(_currentUserId!)
                  : null,
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

  Widget _buildWorkoutList(BuildContext context, List<WorkoutHistory> workouts) {
    if (workouts.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (_currentUserId != null) {
          _workoutHistoryBloc.refreshWorkoutHistory(_currentUserId!);
        }
      },
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: workouts.length,
        itemBuilder: (context, index) {
          final workout = workouts[index];
          return _buildWorkoutCard(context, workout);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center_outlined,
              size: 64.sp,
              color: isDarkMode 
                  ? Theme.of(context).textTheme.bodyMedium?.color
                  : Colors.grey[400],
            ),
            SizedBox(height: 16.h),
            Text(
              'Nessun allenamento trovato',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: isDarkMode 
                    ? Theme.of(context).textTheme.titleMedium?.color
                    : Colors.grey[800],
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              _selectedFilter == 'Tutti' 
                  ? 'Inizia il tuo primo allenamento!'
                  : 'Nessun allenamento nel periodo selezionato',
              style: TextStyle(
                fontSize: 14.sp,
                color: isDarkMode 
                    ? Theme.of(context).textTheme.bodyMedium?.color
                    : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (_selectedFilter != 'Tutti') ...[
              SizedBox(height: 16.h),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedFilter = 'Tutti';
                  });
                },
                child: const Text('Mostra tutti gli allenamenti'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutCard(BuildContext context, WorkoutHistory workout) {
    final workoutDate = DateTime.parse(workout.dataAllenamento);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: isDarkMode 
            ? Theme.of(context).colorScheme.surface
            : Colors.grey[50],
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
              ? Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)
              : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.r),
          onTap: () => _navigateToWorkoutDetails(workout),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con data e azioni
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatWorkoutDate(workoutDate),
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode 
                                  ? Theme.of(context).textTheme.titleMedium?.color
                                  : Colors.grey[800],
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Scheda: ${workout.schedaNome}',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: isDarkMode 
                                  ? Theme.of(context).textTheme.bodyMedium?.color
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: Theme.of(context).iconTheme.color,
                        size: 20.sp,
                      ),
                      onSelected: (value) => _handleWorkoutAction(value, workout),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'view',
                          child: Row(
                            children: [
                              Icon(Icons.visibility_rounded, size: 18),
                              SizedBox(width: 8),
                              Text('Visualizza dettagli'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_rounded, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Elimina allenamento', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                SizedBox(height: 12.h),
                
                // Statistiche rimosse - i dati sono disponibili nei dettagli
                
                if (workout.note != null && workout.note!.isNotEmpty) ...[
                  SizedBox(height: 12.h),
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: isDarkMode 
                          ? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.note_rounded,
                          size: 16.sp,
                          color: isDarkMode 
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey[600],
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            workout.note!,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: isDarkMode 
                                  ? Theme.of(context).colorScheme.onSurfaceVariant
                                  : Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Metodo _buildStatChip rimosso - non più necessario

  void _navigateToWorkoutDetails(WorkoutHistory workout) {
    context.go('/workouts/details/${workout.id}');
  }

  void _handleWorkoutAction(String action, WorkoutHistory workout) {
    switch (action) {
      case 'view':
        _navigateToWorkoutDetails(workout);
        break;
      case 'delete':
        _showDeleteWorkoutDialog(workout);
        break;
    }
  }

  void _showDeleteWorkoutDialog(WorkoutHistory workout) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina Allenamento'),
        content: Text(
          'Sei sicuro di voler eliminare l\'allenamento del '
          '${_formatWorkoutDate(DateTime.parse(workout.dataAllenamento))}?\n\n'
          'Questa azione non può essere annullata.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (_currentUserId != null) {
                _workoutHistoryBloc.deleteWorkoutFromHistory(workout.id, _currentUserId!);
              }
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

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtra Allenamenti'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _filterOptions.map((filter) {
            return RadioListTile<String>(
              title: Text(filter),
              value: filter,
              groupValue: _selectedFilter,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedFilter = value;
                  });
                  Navigator.of(context).pop();
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }

  String _formatWorkoutDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Oggi alle ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Ieri alle ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} giorni fa';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
