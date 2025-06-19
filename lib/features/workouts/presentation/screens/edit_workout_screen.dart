// lib/features/workouts/presentation/screens/edit_workout_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../../shared/widgets/custom_snackbar.dart';
import '../../../../shared/widgets/exercise_selection_dialog.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/di/dependency_injection.dart';

import '../../bloc/workout_bloc.dart';
import '../../models/workout_plan_models.dart';
import '../../../exercises/models/exercises_response.dart';
import '../../../../shared/widgets/workout_exercise_editor.dart';

class EditWorkoutScreen extends StatefulWidget {
  final int workoutId;

  const EditWorkoutScreen({
    super.key,
    required this.workoutId,
  });

  @override
  State<EditWorkoutScreen> createState() => _EditWorkoutScreenState();
}

class _EditWorkoutScreenState extends State<EditWorkoutScreen> {
  late WorkoutBloc _workoutBloc;
  late SessionService _sessionService;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  WorkoutPlan? _originalWorkoutPlan;
  List<WorkoutExercise> _exercises = [];
  List<WorkoutExercise> _removedExercises = [];
  bool _hasChanges = false;
  bool _isLoading = false;

  // ✅ NUOVO: Stati per la selezione esercizi (copiati da create_workout_screen)
  List<ExerciseItem> _availableExercises = [];
  bool _showExerciseDialog = false;
  bool _isLoadingAvailableExercises = false;

  // ✅ NUOVO: Loading state locale per distinguere dal BLoC
  bool _isLocalLoading = false;

  @override
  void initState() {
    super.initState();
    _workoutBloc = context.read<WorkoutBloc>();
    _sessionService = getIt<SessionService>();
    _loadWorkoutDetails();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();

    // ✅ CLEANUP: Reset loading states quando si esce dalla schermata
    print('[CONSOLE] [edit_workout_screen]🧹 Disposing - cleaning up loading states');

    // ✅ RESET tutti i loading states
    if (mounted) {
      setState(() {
        _isLoading = false;
        _isLoadingAvailableExercises = false;
        _isLocalLoading = false; // ✅ RESET anche local loading
      });
    }

    super.dispose();
  }

  void _loadWorkoutDetails() {
    print('[CONSOLE] [edit_workout_screen]🔄 Loading workout details for ID: ${widget.workoutId}');

    // Controlla se i dati sono già disponibili nel BLoC
    final currentState = _workoutBloc.state;

    if (currentState is WorkoutPlanDetailsLoaded &&
        currentState.workoutPlan.id == widget.workoutId) {
      // ✅ Dati già disponibili, usali direttamente
      print('[CONSOLE] [edit_workout_screen]✅ Using existing loaded data');
      _resetState(currentState.workoutPlan, currentState.exercises);
      return;
    }

    if (currentState is WorkoutPlansLoaded) {
      // Controlla se la scheda è nella lista
      try {
        final existingPlan = currentState.workoutPlans.firstWhere(
              (plan) => plan.id == widget.workoutId,
        );
        print('[CONSOLE] [edit_workout_screen]✅ Found plan in loaded plans: ${existingPlan.nome}');

        // Se ha già gli esercizi, usa quelli
        if (existingPlan.esercizi.isNotEmpty) {
          _resetState(existingPlan, existingPlan.esercizi);
          return;
        } else {
          // Carica solo gli esercizi
          _workoutBloc.loadWorkoutPlanWithData(existingPlan);
          return;
        }
      } catch (e) {
        print('[CONSOLE] [edit_workout_screen]⚠️ Plan not found in current plans, loading details...');
      }
    }

    // ✅ Fallback: Carica i dettagli dal server
    setState(() {
      _isLoading = true;
    });
    _workoutBloc.loadWorkoutPlanDetails(widget.workoutId);
  }

  // ✅ NUOVO: Carica esercizi disponibili per il dialog di selezione
  void _loadAvailableExercises() async {
    final userId = await _sessionService.getCurrentUserId();
    if (userId != null) {
      print('[CONSOLE] [edit_workout_screen]Loading available exercises for user: $userId');
      setState(() {
        _isLoadingAvailableExercises = true;
      });
      _workoutBloc.loadAvailableExercises(userId);
    }
  }

  // ✅ NUOVO: Gestisce la selezione di un esercizio dal dialog
  void _onExerciseSelected(ExerciseItem exerciseItem) {
    print('[CONSOLE] [edit_workout_screen]Adding exercise from dialog: ${exerciseItem.nome}');

    // Converte ExerciseItem a WorkoutExercise
    final workoutExercise = WorkoutExercise(
      id: exerciseItem.id,
      schedaEsercizioId: null, // Nuovo esercizio
      nome: exerciseItem.nome,
      gruppoMuscolare: exerciseItem.gruppoMuscolare,
      attrezzatura: exerciseItem.attrezzatura,
      descrizione: exerciseItem.descrizione,
      serie: exerciseItem.serieDefault ?? 3,
      ripetizioni: exerciseItem.ripetizioniDefault ?? 10,
      peso: exerciseItem.pesoDefault ?? 20.0,
      ordine: _exercises.length + 1,
      tempoRecupero: 90,
      note: null,
      setType: 'normal',
      linkedToPreviousInt: 0,
      isIsometricInt: exerciseItem.isIsometric ? 1 : 0,
    );

    setState(() {
      _exercises.add(workoutExercise);
      _showExerciseDialog = false;
      _markAsChanged();
    });
  }

  void _markAsChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  Future<void> _saveWorkout() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = await _sessionService.getCurrentUserId();
    if (userId == null) {
      CustomSnackbar.show(
        context,
        message: 'Errore: utente non autenticato',
        isSuccess: false,
      );
      return;
    }

    final exerciseRequests = _exercises.asMap().entries.map((entry) {
      final index = entry.key;
      final exercise = entry.value;
      final exerciseWithOrder = exercise.safeCopy(ordine: index + 1);
      return WorkoutExerciseRequest.fromWorkoutExercise(exerciseWithOrder);
    }).toList();

    List<WorkoutExerciseToRemove>? exercisesToRemove;
    if (_removedExercises.isNotEmpty) {
      exercisesToRemove = _removedExercises.map((exercise) {
        return WorkoutExerciseToRemove(
          id: exercise.id,
        );
      }).toList();

      print('[CONSOLE] [edit_workout_screen]Esercizi da rimuovere: ${exercisesToRemove.length}');
      for (final toRemove in exercisesToRemove) {
        print('[CONSOLE] [edit_workout_screen]🗑️ Rimuovi esercizio_id: ${toRemove.id}');
      }
    }

    final request = UpdateWorkoutPlanRequest(
      schedaId: widget.workoutId,
      userId: userId,
      nome: _nameController.text.trim(),
      descrizione: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      esercizi: exerciseRequests,
      rimuovi: exercisesToRemove,
    );

    _workoutBloc.updateWorkout(request);
  }

  void _updateExercise(int index, WorkoutExercise updatedExercise) {
    setState(() {
      _exercises[index] = updatedExercise;
      _markAsChanged();
    });
  }

  void _removeExercise(int index) {
    final exerciseToRemove = _exercises[index];

    setState(() {
      _exercises.removeAt(index);
      _removedExercises.add(exerciseToRemove);

      print('[CONSOLE] [edit_workout_screen]🔍 ESERCIZIO RIMOSSO:');
      print('[CONSOLE] [edit_workout_screen]- Nome: ${exerciseToRemove.nome}');
      print('[CONSOLE] [edit_workout_screen]- esercizio_id (exercise.id): ${exerciseToRemove.id}');
      print('[CONSOLE] [edit_workout_screen]- Totale esercizi rimossi: ${_removedExercises.length}');
      print('[CONSOLE] [edit_workout_screen]- Esercizi rimanenti: ${_exercises.length}');

      _markAsChanged();
    });

    CustomSnackbar.show(
      context,
      message: 'Esercizio rimosso - Salva per confermare',
      isSuccess: true,
    );
  }

  void _moveExerciseUp(int index) {
    if (index > 0) {
      setState(() {
        final exercise = _exercises.removeAt(index);
        _exercises.insert(index - 1, exercise);

        // Aggiorna gli ordini
        for (int i = 0; i < _exercises.length; i++) {
          _exercises[i] = _exercises[i].safeCopy(ordine: i + 1);
        }

        _markAsChanged();
      });
    }
  }

  void _moveExerciseDown(int index) {
    if (index < _exercises.length - 1) {
      setState(() {
        final exercise = _exercises.removeAt(index);
        _exercises.insert(index + 1, exercise);

        // Aggiorna gli ordini
        for (int i = 0; i < _exercises.length; i++) {
          _exercises[i] = _exercises[i].safeCopy(ordine: i + 1);
        }

        _markAsChanged();
      });
    }
  }

  void _resetState(WorkoutPlan workoutPlan, List<WorkoutExercise> exercises) {
    print('[CONSOLE] [edit_workout_screen]🔄 Resetting state with: ${workoutPlan.nome}');

    _originalWorkoutPlan = workoutPlan;
    _exercises = List.from(exercises);
    _removedExercises = [];
    _nameController.text = workoutPlan.nome;
    _descriptionController.text = workoutPlan.descrizione ?? '';

    setState(() {
      _hasChanges = false;
      _isLoading = false;
    });

    // ✅ NUOVO: Carica gli esercizi disponibili quando il workout è caricato
    _loadAvailableExercises();

    print('[CONSOLE] [edit_workout_screen]✅ State reset complete. Name: "${_nameController.text}", Exercises: ${_exercises.length}');
  }

  Future<bool> _onWillPop() async {
    if (_isLoading) {
      return false;
    }

    if (!_hasChanges) return true;

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifiche non salvate'),
        content: const Text(
          'Hai delle modifiche non salvate. Vuoi uscire senza salvare?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Esci senza salvare'),
          ),
        ],
      ),
    );

    return shouldDiscard ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            context.pop();
          }
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            BlocConsumer<WorkoutBloc, WorkoutState>(
              listener: (context, state) {
                if (state is WorkoutPlanUpdated) {
                  CustomSnackbar.show(
                    context,
                    message: 'Scheda aggiornata con successo!',
                    isSuccess: true,
                  );
                  context.pop();
                } else if (state is WorkoutPlanDetailsLoaded) {
                  _resetState(state.workoutPlan, state.exercises);
                } else if (state is WorkoutPlansLoaded) {
                  // Gestione aggiornamento stato dopo caricamento workout plans
                  try {
                    final existingPlan = state.workoutPlans.firstWhere(
                          (plan) => plan.id == widget.workoutId,
                    );
                    if (existingPlan.esercizi.isNotEmpty) {
                      _resetState(existingPlan, existingPlan.esercizi);
                    }
                  } catch (e) {
                    // Piano non trovato, continua con il caricamento dettagli
                  }
                } else if (state is AvailableExercisesLoaded) {
                  // ✅ NUOVO: Gestisce il caricamento degli esercizi disponibili
                  print('[CONSOLE] [edit_workout_screen]✅ Available exercises loaded: ${state.availableExercises.length}');
                  setState(() {
                    _availableExercises = state.availableExercises;
                    _isLoadingAvailableExercises = false;
                  });
                } else if (state is AvailableExercisesLoaded) {
                  // ✅ NUOVO: Gestisce il caricamento degli esercizi disponibili
                  print('[CONSOLE] [edit_workout_screen]✅ Available exercises loaded: ${state.availableExercises.length}');
                  setState(() {
                    _availableExercises = state.availableExercises;
                    _isLoadingAvailableExercises = false;
                  });
                } else if (state is WorkoutError) {
                  CustomSnackbar.show(
                    context,
                    message: state.message,
                    isSuccess: false,
                  );
                  setState(() {
                    _isLoading = false;
                    _isLoadingAvailableExercises = false; // ✅ Reset anche questo loading
                  });
                }
              },
              builder: (context, state) {
                return LoadingOverlay(
                  isLoading: state is WorkoutLoading || state is WorkoutLoadingWithMessage || _isLoading,
                  message: state is WorkoutLoadingWithMessage ? state.message : null,
                  child: _buildScaffold(context, state),
                );
              },
            ),

            // ✅ NUOVO: Dialog per selezione esercizi
            if (_showExerciseDialog)
              ExerciseSelectionDialog(
                exercises: _availableExercises,
                selectedExerciseIds: _exercises.map((e) => e.id).toList(),
                isLoading: _isLoadingAvailableExercises,
                onExerciseSelected: _onExerciseSelected,
                onDismissRequest: () {
                  setState(() {
                    _showExerciseDialog = false;
                  });
                },
                // ✅ NUOVO: Callback per la creazione di esercizi personalizzati
                onCreateExercise: () {
                  // Questo verrà gestito direttamente dal dialog aggiornato
                },
                // ✅ NUOVO: Callback per aggiornare la lista dopo la creazione di un esercizio
                onExercisesRefresh: () {
                  // Ricarica gli esercizi disponibili
                  _loadAvailableExercises();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context, WorkoutState state) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Modifica Scheda',
        actions: [
          if (_hasChanges && !_isLoading)
            TextButton(
              onPressed: _saveWorkout,
              child: Text(
                'Salva',
                style: TextStyle(
                  color: isDark ? const Color(0xFF90CAF9) : AppColors.indigo600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Form con nome e descrizione
          Container(
            padding: EdgeInsets.all(AppConfig.spacingM.w),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outline.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nome Scheda',
                      hintText: 'es. Push Day, Gambe, Full Body...',
                      hintStyle: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.5),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: colorScheme.outline,
                        ),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: isDark ? const Color(0xFF90CAF9) : AppColors.indigo600,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Inserisci il nome della scheda';
                      }
                      if (value.trim().length < 3) {
                        return 'Il nome deve essere almeno 3 caratteri';
                      }
                      return null;
                    },
                    onChanged: (_) => _markAsChanged(),
                  ),
                  SizedBox(height: AppConfig.spacingM.h),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Descrizione (opzionale)',
                      hintText: 'Aggiungi una descrizione per la tua scheda...',
                      hintStyle: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.5),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: colorScheme.outline,
                        ),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: isDark ? const Color(0xFF90CAF9) : AppColors.indigo600,
                        ),
                      ),
                    ),
                    maxLines: 2,
                    onChanged: (_) => _markAsChanged(),
                  ),
                ],
              ),
            ),
          ),

          // ✅ NUOVO: Sezione esercizi con pulsante aggiungi
          _buildExercisesSection(),

          // Lista esercizi
          Expanded(
            child: _exercises.isEmpty
                ? _buildEmptyExercisesState()
                : _buildExercisesList(),
          ),

          // Pulsante salva fisso in basso
          if (_hasChanges && !_isLoading)
            Container(
              padding: EdgeInsets.all(AppConfig.spacingM.w),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outline.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.1),
                    blurRadius: AppConfig.elevationM,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: CustomButton(
                text: 'Salva Modifiche',
                onPressed: _saveWorkout,
                type: ButtonType.primary,
                isFullWidth: true,
              ),
            ),
        ],
      ),
    );
  }

  // ✅ NUOVO: Sezione esercizi con pulsante aggiungi (copiata da create_workout_screen)
  Widget _buildExercisesSection() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Esercizi',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              // Apre dialog selezione esercizi
              if (_availableExercises.isNotEmpty) {
                setState(() {
                  _showExerciseDialog = true;
                });
              } else if (!_isLoadingAvailableExercises) {
                // Se non abbiamo esercizi e non stiamo caricando, riprova a caricare
                _loadAvailableExercises();
              }
            },
            icon: _isLoadingAvailableExercises
                ? SizedBox(
              width: 20.w,
              height: 20.w,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: isDark ? AppColors.backgroundDark : Colors.white,
              ),
            )
                : const Icon(Icons.add, size: 20),
            label: Text(_isLoadingAvailableExercises ? 'Caricamento...' : 'Aggiungi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF90CAF9) : AppColors.indigo600,
              foregroundColor: isDark ? AppColors.backgroundDark : Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConfig.radiusM),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyExercisesState() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center_outlined,
            size: 64.sp,
            color: colorScheme.onSurface.withOpacity(0.4),
          ),
          SizedBox(height: 16.h),
          Text(
            'Nessun esercizio',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Aggiungi degli esercizi per completare la tua scheda',
            style: TextStyle(
              fontSize: 14.sp,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          // ✅ NUOVO: Pulsante aggiungi esercizi anche nello stato vuoto
          ElevatedButton.icon(
            onPressed: () {
              if (_availableExercises.isNotEmpty) {
                setState(() {
                  _showExerciseDialog = true;
                });
              } else if (!_isLoadingAvailableExercises) {
                _loadAvailableExercises();
              }
            },
            icon: _isLoadingAvailableExercises
                ? SizedBox(
              width: 20.w,
              height: 20.w,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: isDark ? AppColors.backgroundDark : Colors.white,
              ),
            )
                : const Icon(Icons.add, size: 20),
            label: Text(_isLoadingAvailableExercises ? 'Caricamento...' : 'Aggiungi Esercizi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF90CAF9) : AppColors.indigo600,
              foregroundColor: isDark ? AppColors.backgroundDark : Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConfig.radiusM),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExercisesList() {
    return ListView.builder(
      padding: EdgeInsets.all(AppConfig.spacingM.w),
      itemCount: _exercises.length,
      itemBuilder: (context, index) {
        final exercise = _exercises[index];

        return WorkoutExerciseEditor(
          key: ValueKey('exercise_${exercise.id}_$index'),
          exercise: exercise,
          onUpdate: (updatedExercise) => _updateExercise(index, updatedExercise),
          onDelete: () => _removeExercise(index),
          onMoveUp: index > 0 ? () => _moveExerciseUp(index) : null,
          onMoveDown: index < _exercises.length - 1 ? () => _moveExerciseDown(index) : null,
          isFirst: index == 0,
          isLast: index == _exercises.length - 1,
        );
      },
    );
  }
}