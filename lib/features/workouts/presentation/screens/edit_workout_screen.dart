// lib/features/workouts/presentation/screens/edit_workout_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/dependency_injection.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../../shared/widgets/custom_snackbar.dart';
import '../../../../shared/widgets/workout_exercise_editor.dart';
import '../../../../shared/widgets/exercise_selection_dialog.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/session_service.dart';
import '../../../exercises/models/exercises_response.dart';
import '../../bloc/workout_bloc.dart';
import '../../models/workout_plan_models.dart';

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
  late final WorkoutBloc _workoutBloc;
  late final SessionService _sessionService;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = true;
  bool _hasChanges = false;

  WorkoutPlan? _originalWorkoutPlan;
  List<WorkoutExercise> _exercises = [];
  List<WorkoutExercise> _removedExercises = [];

  // Stati per la selezione esercizi (NUOVO)
  List<ExerciseItem> _availableExercises = [];
  bool _showExerciseDialog = false;
  bool _isLoadingAvailableExercises = false;

  @override
  void initState() {
    super.initState();
    _workoutBloc = getIt<WorkoutBloc>();
    _sessionService = getIt<SessionService>();
    _loadWorkoutDetails();
    _loadAvailableExercises(); // NUOVO: Carica esercizi disponibili
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _loadWorkoutDetails() {
    print('[CONSOLE] [edit_workout_screen]🔄 Loading workout details for ID: ${widget.workoutId}');

    final currentState = _workoutBloc.state;
    if (currentState is WorkoutPlansLoaded) {
      try {
        final existingPlan = currentState.workoutPlans.firstWhere(
              (plan) => plan.id == widget.workoutId,
        );

        print('[CONSOLE] [edit_workout_screen]✅ Found plan in loaded plans: ${existingPlan.nome}');

        if (existingPlan.esercizi.isNotEmpty) {
          _resetState(existingPlan, existingPlan.esercizi);
          return;
        } else {
          _workoutBloc.loadWorkoutPlanWithData(existingPlan);
          return;
        }
      } catch (e) {
        print('[CONSOLE] [edit_workout_screen]⚠️ Plan not found in current plans, loading details...');
      }
    }

    setState(() {
      _isLoading = true;
    });
    _workoutBloc.loadWorkoutPlanDetails(widget.workoutId);
  }

  // NUOVO: Carica esercizi disponibili per il dialog di selezione
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

  // NUOVO: Gestisce la selezione di un esercizio dal dialog
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

      final exerciseWithOrder = exercise.safeCopy(ordine: index);

      print('[CONSOLE] [edit_workout_screen]Converting exercise: ${exercise.nome}');
      print('[CONSOLE] [edit_workout_screen]  - isRestPauseInt: ${exercise.isRestPauseInt}');
      print('[CONSOLE] [edit_workout_screen]  - restPauseReps: "${exercise.restPauseReps}"');
      print('[CONSOLE] [edit_workout_screen]  - restPauseRestSeconds: ${exercise.restPauseRestSeconds}');

      return WorkoutExerciseRequest.fromWorkoutExercise(exerciseWithOrder);
    }).toList();

    for (int i = 0; i < exerciseRequests.length; i++) {
      final req = exerciseRequests[i];
      print('[CONSOLE] [edit_workout_screen]ExerciseRequest $i:');
      print('[CONSOLE] [edit_workout_screen]  - isRestPauseInt: ${req.isRestPauseInt}');
      print('[CONSOLE] [edit_workout_screen]  - restPauseReps: "${req.restPauseReps}"');
      print('[CONSOLE] [edit_workout_screen]  - restPauseRestSeconds: ${req.restPauseRestSeconds}');
    }

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

    print('[CONSOLE] [edit_workout_screen]✅ State reset complete. Name: "${_nameController.text}", Exercises: ${_exercises.length}');
  }

  // ✅ FIX: Gestione del back navigation come nel create_workout_screen
  void _handleBackNavigation() async {
    print('[CONSOLE] [edit_workout_screen]🔄 Handling back navigation');

    // Se c'è un loading in corso, non permettere la navigazione
    if (_isLoading) {
      return;
    }

    // Se ci sono modifiche non salvate, chiedi conferma
    if (_hasChanges) {
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

      if (shouldDiscard != true) {
        return; // Non uscire se l'utente ha annullato
      }
    }

    // ✅ STESSO APPROCCIO DEL CREATE: Gestione stati del bloc
    final currentState = _workoutBloc.state;
    final userId = await _sessionService.getCurrentUserId();

    if (currentState is AvailableExercisesLoaded && userId != null) {
      // Se siamo in stato di esercizi disponibili, torna alle schede
      _workoutBloc.loadWorkoutPlans(userId);
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    } else if (currentState is! WorkoutPlansLoaded && userId != null) {
      // Se non abbiamo le schede, ricaricale
      _workoutBloc.loadWorkoutPlans(userId);
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    } else {
      // Se tutto è ok, torna indietro immediatamente
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Impedisce il pop automatico
      onPopInvoked: (didPop) {
        if (!didPop) {
          _handleBackNavigation(); // ✅ Usa la stessa logica del create
        }
      },
      child: BlocProvider.value(
        value: _workoutBloc,
        child: Stack(
          children: [
            Scaffold(
              appBar: CustomAppBar(
                title: 'Modifica Scheda',
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _handleBackNavigation, // ✅ Usa il metodo custom
                ),
                actions: [
                  if (_hasChanges && !_isLoading)
                    TextButton(
                      onPressed: _saveWorkout,
                      child: Text(
                        'Salva',
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF90CAF9)
                              : AppColors.indigo600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              body: BlocConsumer<WorkoutBloc, WorkoutState>(
                listener: (context, state) {
                  if (state is WorkoutPlanDetailsLoaded) {
                    _resetState(state.workoutPlan, state.exercises);
                  } else if (state is WorkoutPlanUpdated) {
                    CustomSnackbar.show(
                      context,
                      message: 'Scheda aggiornata con successo!',
                      isSuccess: true,
                    );
                    if (mounted) {
                      context.pop();
                    }
                  } else if (state is WorkoutError) {
                    CustomSnackbar.show(
                      context,
                      message: state.message,
                      isSuccess: false,
                    );
                  } else if (state is AvailableExercisesLoaded) { // NUOVO: Gestione esercizi disponibili
                    setState(() {
                      _availableExercises = state.availableExercises;
                      _isLoadingAvailableExercises = false;
                    });
                  }
                },
                builder: (context, state) {
                  return LoadingOverlay(
                    isLoading: state is WorkoutLoading,
                    child: _buildBody(context, state),
                  );
                },
              ),
            ),

            // NUOVO: Dialog per selezione esercizi
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
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WorkoutState state) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state is WorkoutError) {
      return _buildErrorState(state);
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBasicInfoSection(),
            SizedBox(height: 24.h),
            _buildExercisesSection(), // MODIFICATO: Ora include il pulsante Aggiungi
            SizedBox(height: 32.h),
            _buildActionButtons(),
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informazioni Base',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 16.h),

        CustomTextField(
          controller: _nameController,
          label: 'Nome Scheda',
          hint: 'es. Push Day, Gambe, Full Body...',
          prefixIcon: Icons.fitness_center,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Inserisci il nome della scheda';
            }
            if (value.trim().length < 3) {
              return 'Il nome deve essere almeno 3 caratteri';
            }
            return null;
          },
          onChanged: (value) => _markAsChanged(),
        ),

        SizedBox(height: 16.h),

        CustomTextField(
          controller: _descriptionController,
          label: 'Descrizione (opzionale)',
          hint: 'Aggiungi una descrizione per la tua scheda...',
          prefixIcon: Icons.description,
          maxLines: 3,
          onChanged: (value) => _markAsChanged(),
        ),
      ],
    );
  }

  Widget _buildExercisesSection() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // NUOVO: Header con pulsante Aggiungi Esercizio
        Row(
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
                // NUOVO: Apre dialog selezione esercizi
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConfig.radiusM),
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: 16.h),

        if (_exercises.isEmpty)
          _buildEmptyExercisesState()
        else
          _buildExercisesList(),
      ],
    );
  }

  Widget _buildExercisesList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _exercises.length,
      itemBuilder: (context, index) {
        return WorkoutExerciseEditor(
          key: ValueKey('exercise_${_exercises[index].id}_$index'),
          exercise: _exercises[index],
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

  Widget _buildEmptyExercisesState() {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 64.sp,
            color: colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          SizedBox(height: AppConfig.spacingL.h),
          Text(
            'Nessun esercizio nella scheda',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: AppConfig.spacingS.h),
          Text(
            'Usa il pulsante "Aggiungi" sopra per aggiungere esercizi',
            style: TextStyle(
              fontSize: 14.sp,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50.h,
          child: ElevatedButton(
            onPressed: _saveWorkout,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF90CAF9) : AppColors.indigo600,
              foregroundColor: isDark ? AppColors.backgroundDark : Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConfig.radiusM),
              ),
            ),
            child: Text(
              'Aggiorna Scheda',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SizedBox(height: 12.h),
        SizedBox(
          width: double.infinity,
          height: 50.h,
          child: OutlinedButton(
            onPressed: _handleBackNavigation, // ✅ Usa il metodo custom
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.onSurface.withValues(alpha: 0.6),
              side: BorderSide(color: colorScheme.outline),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConfig.radiusM),
              ),
            ),
            child: Text(
              'Annulla',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(WorkoutError state) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64.sp,
            color: AppColors.error,
          ),
          SizedBox(height: AppConfig.spacingL.h),
          Text(
            'Errore nel caricamento',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.error,
            ),
          ),
          SizedBox(height: AppConfig.spacingS.h),
          Text(
            state.message,
            style: TextStyle(
              fontSize: 16.sp,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppConfig.spacingXL.h),
          CustomButton(
            text: 'Riprova',
            onPressed: _loadWorkoutDetails,
            type: ButtonType.primary,
          ),
        ],
      ),
    );
  }
}