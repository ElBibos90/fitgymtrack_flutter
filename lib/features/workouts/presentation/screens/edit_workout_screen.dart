// lib/features/workouts/presentation/screens/edit_workout_screen.dart
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../../shared/widgets/custom_snackbar.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/di/dependency_injection.dart';

import '../../bloc/workout_bloc.dart';
import '../../models/workout_plan_models.dart';
import '../widgets/workout_widgets.dart';

class EditWorkoutScreen extends StatefulWidget {
  final int workoutId;

  const EditWorkoutScreen({
    super.key,
    required this.workoutId,
  });

  @override
  State<EditWorkoutScreen> createState() => _EditWorkoutScreenState();
}

// lib/features/workouts/presentation/screens/edit_workout_screen.dart

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
  bool _isLoading = false; // ✅ NUOVO: Traccia loading locale

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
    super.dispose();
  }

  // ✅ AGGIORNATO: Gestione caricamento più robusta
  void _loadWorkoutDetails() {
    // Controlla se i dati sono già disponibili nel BLoC
    final currentState = _workoutBloc.state;
    if (currentState is WorkoutPlanDetailsLoaded &&
        currentState.workoutPlan.id == widget.workoutId) {
      // ✅ Dati già disponibili, usali direttamente
      _resetState(currentState.workoutPlan, currentState.exercises);
    } else {
      // ✅ Carica i dettagli dal server
      _workoutBloc.loadWorkoutPlanDetails(widget.workoutId);
    }
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

    // Prepara la lista esercizi rimanenti
    final exerciseRequests = _exercises.asMap().entries.map((entry) {
      final index = entry.key;
      final exercise = entry.value;

      return WorkoutExerciseRequest(
        id: exercise.id,
        schedaEsercizioId: exercise.schedaEsercizioId,
        serie: exercise.serie,
        ripetizioni: exercise.ripetizioni,
        peso: exercise.peso,
        ordine: index,
        tempoRecupero: exercise.tempoRecupero,
        note: exercise.note,
        setType: exercise.setType,
        linkedToPrevious: exercise.linkedToPrevious ? 1 : 0,
      );
    }).toList();

    // ✅ FIX: Usa esercizio_id (exercise.id) non scheda_esercizio_id
    List<WorkoutExerciseToRemove>? exercisesToRemove;
    if (_removedExercises.isNotEmpty) {
      exercisesToRemove = _removedExercises.map((exercise) {
        return WorkoutExerciseToRemove(
          id: exercise.id,
        );
      }).toList();

      developer.log('Esercizi da rimuovere: ${exercisesToRemove.length}', name: 'EditWorkoutScreen');
      for (final toRemove in exercisesToRemove) {
        developer.log('🗑️ Rimuovi esercizio_id: ${toRemove.id}', name: 'EditWorkoutScreen');
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

      developer.log('🔍 ESERCIZIO RIMOSSO:', name: 'EditWorkoutScreen');
      developer.log('- Nome: ${exerciseToRemove.nome}', name: 'EditWorkoutScreen');
      developer.log('- esercizio_id (exercise.id): ${exerciseToRemove.id}', name: 'EditWorkoutScreen');
      developer.log('- Totale esercizi rimossi: ${_removedExercises.length}', name: 'EditWorkoutScreen');
      developer.log('- Esercizi rimanenti: ${_exercises.length}', name: 'EditWorkoutScreen');

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
        _markAsChanged();
      });
    }
  }

  void _moveExerciseDown(int index) {
    if (index < _exercises.length - 1) {
      setState(() {
        final exercise = _exercises.removeAt(index);
        _exercises.insert(index + 1, exercise);
        _markAsChanged();
      });
    }
  }

  // ✅ AGGIORNATO: Reset stato migliorato
  void _resetState(WorkoutPlan workoutPlan, List<WorkoutExercise> exercises) {
    _originalWorkoutPlan = workoutPlan;
    _exercises = List.from(exercises);
    _removedExercises = [];
    _nameController.text = workoutPlan.nome;
    _descriptionController.text = workoutPlan.descrizione ?? '';
    setState(() {
      _hasChanges = false;
      _isLoading = false; // ✅ RESET loading locale
    });
  }

  // ✅ AGGIORNATO: Gestione back migliorata
  Future<bool> _onWillPop() async {
    if (_isLoading) {
      // ✅ Se stiamo caricando, blocca la navigazione
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
        appBar: CustomAppBar(
          title: 'Modifica Scheda',
          actions: [
            if (_hasChanges && !_isLoading) // ✅ Nasconde se loading
              TextButton(
                onPressed: _saveWorkout,
                child: Text(
                  'Salva',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF90CAF9)
                        : AppColors.indigo600, // ✅ DINAMICO!
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        body: BlocConsumer<WorkoutBloc, WorkoutState>(
          listener: (context, state) {
            // ✅ AGGIORNATO: Gestione stati migliorata
            if (state is WorkoutPlanDetailsLoaded) {
              _resetState(state.workoutPlan, state.exercises);
            } else if (state is WorkoutPlanUpdated) {
              CustomSnackbar.show(
                context,
                message: 'Scheda aggiornata con successo',
                isSuccess: true,
              );
              // Torna alla schermata precedente dopo un breve ritardo
              Future.delayed(const Duration(seconds: 1), () {
                if (context.mounted) {
                  context.pop();
                }
              });
            } else if (state is WorkoutError) {
              CustomSnackbar.show(
                context,
                message: state.message,
                isSuccess: false,
              );
              setState(() {
                _isLoading = false; // ✅ RESET loading su errore
              });
            } else if (state is WorkoutLoading || state is WorkoutLoadingWithMessage) {
              setState(() {
                _isLoading = true; // ✅ SET loading
              });
            }
          },
          builder: (context, state) {
            return LoadingOverlay(
              isLoading: _isLoading, // ✅ USA loading locale
              message: state is WorkoutLoadingWithMessage ? state.message : null,
              child: _buildContent(state),
            );
          },
        ),
      ),
    );
  }

  // ✅ AGGIORNATO: Content builder migliorato
  Widget _buildContent(WorkoutState state) {
    if (_originalWorkoutPlan != null) {
      // ✅ Se abbiamo i dati, mostra sempre il form
      return _buildEditForm();
    } else if (state is WorkoutPlanDetailsLoaded) {
      return _buildEditForm();
    } else if (state is WorkoutError) {
      return _buildErrorState(state);
    }

    // Loading state
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildEditForm() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Header con informazioni base ✅ SISTEMATO!
          Container(
            padding: EdgeInsets.all(AppConfig.spacingM.w),
            decoration: BoxDecoration(
              color: colorScheme.surface, // ✅ DINAMICO!
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outline.withOpacity(0.3), // ✅ DINAMICO!
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  style: TextStyle(
                    color: colorScheme.onSurface, // ✅ DINAMICO!
                  ),
                  decoration: InputDecoration(
                    labelText: 'Nome scheda *',
                    hintText: 'Es. Scheda Forza, Allenamento Gambe...',
                    labelStyle: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.7), // ✅ DINAMICO!
                    ),
                    hintStyle: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.5), // ✅ DINAMICO!
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: colorScheme.outline, // ✅ DINAMICO!
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
                      return 'Il nome della scheda è obbligatorio';
                    }
                    return null;
                  },
                  onChanged: (_) => _markAsChanged(),
                ),
                SizedBox(height: AppConfig.spacingM.h),
                TextFormField(
                  controller: _descriptionController,
                  style: TextStyle(
                    color: colorScheme.onSurface, // ✅ DINAMICO!
                  ),
                  decoration: InputDecoration(
                    labelText: 'Descrizione',
                    hintText: 'Descrizione opzionale della scheda',
                    labelStyle: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.7), // ✅ DINAMICO!
                    ),
                    hintStyle: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.5), // ✅ DINAMICO!
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: colorScheme.outline, // ✅ DINAMICO!
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

          // Lista esercizi
          Expanded(
            child: _exercises.isEmpty
                ? _buildEmptyExercisesState()
                : _buildExercisesList(),
          ),

          // Pulsante salva fisso in basso
          if (_hasChanges && !_isLoading) // ✅ Nasconde se loading
            Container(
              padding: EdgeInsets.all(AppConfig.spacingM.w),
              decoration: BoxDecoration(
                color: colorScheme.surface, // ✅ DINAMICO!
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outline.withOpacity(0.3), // ✅ DINAMICO!
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.1), // ✅ DINAMICO!
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

  Widget _buildExercisesList() {
    return ListView.builder(
      padding: EdgeInsets.all(AppConfig.spacingM.w),
      itemCount: _exercises.length,
      itemBuilder: (context, index) {
        final exercise = _exercises[index];

        return ExerciseEditorCard(
          exercise: exercise,
          index: index,
          isFirst: index == 0,
          isLast: index == _exercises.length - 1,
          onUpdate: (updatedExercise) => _updateExercise(index, updatedExercise),
          onDelete: () => _removeExercise(index),
          onMoveUp: () => _moveExerciseUp(index),
          onMoveDown: () => _moveExerciseDown(index),
        );
      },
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
            Icons.fitness_center,
            size: 64.sp,
            color: colorScheme.onSurface.withOpacity(0.4), // ✅ DINAMICO!
          ),
          SizedBox(height: AppConfig.spacingL.h),
          Text(
            'Nessun esercizio nella scheda',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface, // ✅ DINAMICO!
            ),
          ),
          SizedBox(height: AppConfig.spacingS.h),
          Text(
            'Aggiungi esercizi per completare la scheda',
            style: TextStyle(
              fontSize: 14.sp,
              color: colorScheme.onSurface.withOpacity(0.6), // ✅ DINAMICO!
            ),
          ),
          SizedBox(height: AppConfig.spacingXL.h),
          CustomButton(
            text: 'Aggiungi Esercizi',
            onPressed: () {
              CustomSnackbar.show(
                context,
                message: 'Funzionalità di aggiunta esercizi in arrivo',
                isSuccess: false,
              );
            },
            type: ButtonType.secondary,
          ),
        ],
      ),
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
              color: colorScheme.onSurface.withOpacity(0.6), // ✅ DINAMICO!
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