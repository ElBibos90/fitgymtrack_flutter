// lib/features/workouts/presentation/screens/create_workout_screen.dart

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
import '../../../../shared/theme/app_colors.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/session_service.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../bloc/workout_bloc.dart';
import '../../models/workout_plan_models.dart';
import '../../../exercises/models/exercises_response.dart';
import '../../../../shared/widgets/exercise_editor.dart';

class CreateWorkoutScreen extends StatefulWidget {
  final int? workoutId; // null per creazione, valorizzato per modifica

  const CreateWorkoutScreen({
    super.key,
    this.workoutId,
  });

  @override
  State<CreateWorkoutScreen> createState() => _CreateWorkoutScreenState();
}

class _CreateWorkoutScreenState extends State<CreateWorkoutScreen> {
  late final WorkoutBloc _workoutBloc;
  late final SessionService _sessionService;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  int? _currentUserId;
  bool _isLoadingUserId = true;
  bool _hasLoadedWorkoutData = false;
  bool get _isEditing => widget.workoutId != null;

  List<WorkoutExercise> _selectedExercises = [];

  // Stati per la selezione esercizi
  List<ExerciseItem> _availableExercises = [];
  bool _showExerciseDialog = false;
  bool _isLoadingAvailableExercises = false;
  int? _editIndex;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _workoutBloc = getIt<WorkoutBloc>();
    _sessionService = getIt<SessionService>();
    _initializeUserId();
  }

  Future<void> _initializeUserId() async {
    try {
      final userId = await _sessionService.getCurrentUserId();

      if (userId != null) {
        setState(() {
          _currentUserId = userId;
          _isLoadingUserId = false;
        });

        if (_isEditing) {
          _loadWorkoutForEditing();
        } else {
          _loadAvailableExercises();
        }
      } else {
        final authState = context.read<AuthBloc>().state;
        if (authState is AuthAuthenticated) {
          setState(() {
            _currentUserId = authState.user.id;
            _isLoadingUserId = false;
          });

          if (_isEditing) {
            _loadWorkoutForEditing();
          } else {
            _loadAvailableExercises();
          }
        } else if (authState is AuthLoginSuccess) {
          setState(() {
            _currentUserId = authState.user.id;
            _isLoadingUserId = false;
          });

          if (_isEditing) {
            _loadWorkoutForEditing();
          } else {
            _loadAvailableExercises();
          }
        } else {
          setState(() {
            _isLoadingUserId = false;
          });
          if (mounted) {
            context.go('/login');
          }
        }
      }
    } catch (e) {
      setState(() {
        _isLoadingUserId = false;
      });
      if (mounted) {
        CustomSnackbar.show(
          context,
          message: 'Errore nel recupero dati utente',
          isSuccess: false,
        );
        context.pop();
      }
    }
  }

  void _loadWorkoutForEditing() {
    if (!_hasLoadedWorkoutData && widget.workoutId != null) {
      _hasLoadedWorkoutData = true;

      // Prima verifica se abbiamo già i dati delle schede nel BLoC
      final currentState = _workoutBloc.state;
      if (currentState is WorkoutPlansLoaded) {
        // Cerca la scheda nei dati già caricati
        try {
          final existingPlan = currentState.workoutPlans.firstWhere(
                (plan) => plan.id == widget.workoutId,
          );

          ////print('[CONSOLE] [create_workout_screen]✅ Found existing plan in state: ${existingPlan.nome}');

          // Usa i dati reali della scheda
          _populateFieldsFromWorkoutPlan(existingPlan);

          // Poi carica gli esercizi se non ci sono già
          if (existingPlan.esercizi.isEmpty) {
            _workoutBloc.loadWorkoutPlanWithData(existingPlan);
          }

          // Carica anche esercizi disponibili per il dialog
          _loadAvailableExercises();
          return;
        } catch (e) {
          ////print('[CONSOLE] [create_workout_screen]⚠️ Plan not found in current state, loading from scratch');
        }
      }

      // Fallback: se non abbiamo i dati nel stato, dobbiamo ricaricare tutto
      ////print('[CONSOLE] [create_workout_screen]🔄 Loading workout plans first to get correct name...');
      if (_currentUserId != null) {
        _workoutBloc.loadWorkoutPlans(_currentUserId!);
        // Carica anche esercizi disponibili
        _loadAvailableExercises();
      }
    }
  }

  /// Popola i campi con i dati reali della scheda
  void _populateFieldsFromWorkoutPlan(WorkoutPlan workoutPlan) {
    ////print('[CONSOLE] [create_workout_screen]✅ Populating fields with real workout data: ${workoutPlan.nome}');

    _nameController.text = workoutPlan.nome;
    _descriptionController.text = workoutPlan.descrizione ?? '';

    if (workoutPlan.esercizi.isNotEmpty) {
      setState(() {
        _selectedExercises = List.from(workoutPlan.esercizi);
      });
    }
  }

  void _populateFieldsFromWorkoutData(WorkoutPlan workoutPlan, List<WorkoutExercise> exercises) {
    ////print('[CONSOLE] [create_workout_screen]✅ Populating fields with workout: ${workoutPlan.nome}');

    _nameController.text = workoutPlan.nome;
    _descriptionController.text = workoutPlan.descrizione ?? '';

    setState(() {
      _selectedExercises = List.from(exercises);
    });
  }

  /// Carica esercizi disponibili per il dialog di selezione
  void _loadAvailableExercises() {
    if (_currentUserId != null) {
      ////print('[CONSOLE] [create_workout_screen]Loading available exercises for user: $_currentUserId');
      setState(() {
        _isLoadingAvailableExercises = true;
      });
      _workoutBloc.loadAvailableExercises(_currentUserId!);
    }
  }

  /// Gestisce la selezione di un esercizio dal dialog
  void _onExerciseSelected(ExerciseItem exerciseItem) {
    ////print('[CONSOLE] [create_workout_screen]Adding exercise from dialog: ${exerciseItem.nome}');

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
      ordine: _selectedExercises.length + 1,
      tempoRecupero: 90,
      note: null,
      setType: 'normal',
      linkedToPreviousInt: 0,
      isIsometricInt: exerciseItem.isIsometric ? 1 : 0,
    );

    setState(() {
      _selectedExercises.add(workoutExercise);
      _showExerciseDialog = false;
    });
  }

  // ✅ FIX: Gestione del back navigation super-sicura
  void _handleBackNavigation() {
    final currentState = _workoutBloc.state;
    if (currentState is AvailableExercisesLoaded && _currentUserId != null) {
      _workoutBloc.loadWorkoutPlans(_currentUserId!);
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _workoutBloc.resetState();
          Navigator.of(context).pop(true); // Notifica la schermata precedente
        }
      });
    } else if (currentState is! WorkoutPlansLoaded && _currentUserId != null) {
      _workoutBloc.loadWorkoutPlans(_currentUserId!);
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _workoutBloc.resetState();
          Navigator.of(context).pop(true);
        }
      });
    } else {
      _workoutBloc.resetState();
      Navigator.of(context).pop(true);
    }
  }

  // ✅ FIX: Dispose corretto - NON chiude il bloc
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    // ❌ NON FARE: _workoutBloc.close();
    // Il BLoC è gestito dal DI e condiviso, non deve essere chiuso qui
    super.dispose();
  }

  // ✅ FIX: Build con PopScope per gestire il back
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Impedisce il pop automatico
      onPopInvoked: (didPop) {
        if (!didPop) {
          _handleBackNavigation();
        }
      },
      child: BlocProvider.value(
        value: _workoutBloc,
        child: Stack(
          children: [
            Scaffold(
              appBar: CustomAppBar(
                title: _isEditing ? 'Modifica Scheda' : 'Nuova Scheda',
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _handleBackNavigation, // ✅ Usa il metodo custom
                ),
                actions: [
                  if (!_isLoadingUserId && _currentUserId != null)
                    TextButton(
                      onPressed: _saveWorkout,
                      child: Text(
                        'Salva',
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF90CAF9)
                              : AppColors.indigo600, // ✅ DINAMICO!
                          fontWeight: FontWeight.w600,
                          fontSize: 16.sp,
                        ),
                      ),
                    ),
                ],
              ),
              body: _isLoadingUserId
                  ? const Center(child: CircularProgressIndicator())
                  : _currentUserId == null
                  ? const Center(
                child: Text('Errore: utente non autenticato'),
              )
                  : BlocConsumer<WorkoutBloc, WorkoutState>(
                listener: (context, state) {
                  if (state is WorkoutError) {
                    CustomSnackbar.show(
                      context,
                      message: state.message,
                      isSuccess: false,
                    );
                  } else if (state is WorkoutPlanCreated) {
                    CustomSnackbar.show(
                      context,
                      message: 'Scheda creata con successo!',
                      isSuccess: true,
                    );
                    context.pop();
                  } else if (state is WorkoutPlanUpdated) {
                    CustomSnackbar.show(
                      context,
                      message: 'Scheda aggiornata con successo!',
                      isSuccess: true,
                    );
                    context.pop();
                  } else if (state is WorkoutPlanDetailsLoaded) {
                    _populateFieldsFromWorkoutData(state.workoutPlan, state.exercises);
                  } else if (state is WorkoutPlansLoaded && _isEditing && widget.workoutId != null) {
                    // Quando si caricano le schede durante l'editing
                    try {
                      final existingPlan = state.workoutPlans.firstWhere(
                            (plan) => plan.id == widget.workoutId,
                      );
                      //print('[CONSOLE] [create_workout_screen]✅ Found plan after loading: ${existingPlan.nome}');
                      _populateFieldsFromWorkoutPlan(existingPlan);

                      // Ora carica anche gli esercizi
                      _workoutBloc.loadWorkoutPlanWithData(existingPlan);

                      // Carica esercizi disponibili se non l'abbiamo già fatto
                      if (_availableExercises.isEmpty && !_isLoadingAvailableExercises) {
                        _loadAvailableExercises();
                      }
                    } catch (e) {
                      //print('[CONSOLE] [create_workout_screen]❌ Plan not found even after loading: ${e}');
                    }
                  } else if (state is AvailableExercisesLoaded) {
                    // Gestisce il caricamento degli esercizi disponibili
                    //print('[CONSOLE] [create_workout_screen]✅ Available exercises loaded: ${state.availableExercises.length}');
                    setState(() {
                      _availableExercises = state.availableExercises;
                      _isLoadingAvailableExercises = false;
                    });
                  }
                },
                builder: (context, state) {
                  return LoadingOverlay(
                    isLoading: state is WorkoutLoading || state is WorkoutLoadingWithMessage,
                    message: state is WorkoutLoadingWithMessage ? state.message : null,
                    child: _buildBody(context, state),
                  );
                },
              ),
            ),

            // Dialog per selezione esercizi
            if (_showExerciseDialog)
              ExerciseSelectionDialog(
                exercises: _availableExercises,
                selectedExerciseIds: _selectedExercises.map((e) => e.id).toList(),
                isLoading: _isLoadingAvailableExercises,
                onExerciseSelected: _onExerciseSelected,
                onDismissRequest: () {
                  setState(() {
                    _showExerciseDialog = false;
                  });
                },
                // ✨ NUOVI PARAMETRI per la creazione di esercizi
                currentUserId: _currentUserId,
                onExercisesRefresh: () {
                  // Ricarica gli esercizi disponibili dopo la creazione di un nuovo esercizio
                  print('[CONSOLE] [create_workout_screen]🔄 Refreshing exercises after creation...');
                  _loadAvailableExercises();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WorkoutState state) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBasicInfoSection(),
            SizedBox(height: 24.h),
            _buildExercisesSection(),
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
            color: colorScheme.onSurface, // ✅ DINAMICO!
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
        ),

        SizedBox(height: 16.h),

        CustomTextField(
          controller: _descriptionController,
          label: 'Descrizione (opzionale)',
          hint: 'Aggiungi una descrizione per la tua scheda...',
          prefixIcon: Icons.description,
          maxLines: 3,
          validator: (value) {
            return null;
          },
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
        Row(
          children: [
            Expanded(
              child: Text(
                'Esercizi',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface, // ✅ DINAMICO!
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConfig.radiusM),
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: 16.h),

        if (_selectedExercises.isEmpty)
          _buildEmptyExercisesState()
        else
          _buildExercisesList(),
      ],
    );
  }

  Widget _buildEmptyExercisesState() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF90CAF9) : AppColors.indigo600).withValues(alpha:0.05),
        borderRadius: BorderRadius.circular(AppConfig.radiusM),
        border: Border.all(
          color: (isDark ? const Color(0xFF90CAF9) : AppColors.indigo600).withValues(alpha:0.2),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.fitness_center,
            size: 48.sp,
            color: (isDark ? const Color(0xFF90CAF9) : AppColors.indigo600).withValues(alpha:0.5),
          ),
          SizedBox(height: 12.h),
          Text(
            'Nessun Esercizio',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface, // ✅ DINAMICO!
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            _isEditing
                ? 'Caricamento esercizi in corso...'
                : 'Aggiungi degli esercizi per creare la tua scheda',
            style: TextStyle(
              fontSize: 14.sp,
              color: colorScheme.onSurface.withValues(alpha:0.6), // ✅ DINAMICO!
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildExercisesList() {
    return Column(
      children: [
        for (int i = 0; i < _selectedExercises.length; i++)
          WorkoutExerciseEditor(
            key: ValueKey('exercise_${_selectedExercises[i].id}_$i'),
            exercise: _selectedExercises[i],
            onUpdate: (updatedExercise) => _updateExercise(i, updatedExercise),
            onDelete: () => _removeExercise(i),
            onMoveUp: i > 0 ? () => _moveExercise(i, i - 1) : null,
            onMoveDown: i < _selectedExercises.length - 1 ? () => _moveExercise(i, i + 1) : null,
            isFirst: i == 0,
            isLast: i == _selectedExercises.length - 1,
          ),
      ],
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
              _isEditing ? 'Aggiorna Scheda' : 'Crea Scheda',
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
            onPressed: _handleBackNavigation, // ✅ Usa il metodo custom anche qui
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.onSurface.withValues(alpha:0.6), // ✅ DINAMICO!
              side: BorderSide(color: colorScheme.outline), // ✅ DINAMICO!
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

  void _updateExercise(int index, WorkoutExercise updatedExercise) {
    if (index >= 0 && index < _selectedExercises.length) {
      setState(() {
        _selectedExercises[index] = updatedExercise;
      });
    }
  }

  void _moveExercise(int fromIndex, int toIndex) {
    if (fromIndex >= 0 && fromIndex < _selectedExercises.length &&
        toIndex >= 0 && toIndex < _selectedExercises.length) {
      setState(() {
        final exercise = _selectedExercises.removeAt(fromIndex);
        _selectedExercises.insert(toIndex, exercise);

        // Aggiorna gli ordini
        for (int i = 0; i < _selectedExercises.length; i++) {
          _selectedExercises[i] = _selectedExercises[i].safeCopy(ordine: i + 1);
        }
      });
    }
  }

  void _removeExercise(int index) {
    setState(() {
      _selectedExercises.removeAt(index);
      for (int i = 0; i < _selectedExercises.length; i++) {
        _selectedExercises[i] = _selectedExercises[i].safeCopy(ordine: i + 1);
      }
    });
  }

  void _saveWorkout() {
    if (_currentUserId == null) {
      CustomSnackbar.show(
        context,
        message: 'Errore: utente non identificato',
        isSuccess: false,
      );
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedExercises.isEmpty) {
      CustomSnackbar.show(
        context,
        message: 'Aggiungi almeno un esercizio alla scheda',
        isSuccess: false,
      );
      return;
    }
    if (_isEditing) {
      _updateWorkout();
    } else {
      _createWorkout();
    }
    // Dopo il salvataggio, reset bloc e pop
    _workoutBloc.resetState();
    context.pop(true);
  }

  void _createWorkout() {
    final exerciseRequests = _selectedExercises.map((exercise) {
      // DEBUG: Log tutti i valori prima del salvataggio
      //print('[CONSOLE] [create_workout_screen]Creating exercise: ${exercise.nome}');
      //print('[CONSOLE] [create_workout_screen]  - setType: "${exercise.setType}"');
      //print('[CONSOLE] [create_workout_screen]  - linkedToPreviousInt: ${exercise.linkedToPreviousInt}');
      //print('[CONSOLE] [create_workout_screen]  - isIsometricInt: ${exercise.isIsometricInt}');
      //print('[CONSOLE] [create_workout_screen]  - note: "${exercise.note}"');
      // 🚀 FASE 3 FIX: Log valori REST-PAUSE
      //print('[CONSOLE] [create_workout_screen]  - isRestPauseInt: ${exercise.isRestPauseInt}');
      //print('[CONSOLE] [create_workout_screen]  - restPauseReps: "${exercise.restPauseReps}"');
      //print('[CONSOLE] [create_workout_screen]  - restPauseRestSeconds: ${exercise.restPauseRestSeconds}');

      // 🚀 FASE 3 FIX: USA IL NUOVO HELPER METHOD
      return WorkoutExerciseRequest.fromWorkoutExercise(exercise);
    }).toList();

    // DEBUG: Log della richiesta finale
    for (int i = 0; i < exerciseRequests.length; i++) {
      final req = exerciseRequests[i];
      //print('[CONSOLE] [create_workout_screen]ExerciseRequest $i:');
      //print('[CONSOLE] [create_workout_screen]  - setType: "${req.setType}"');
      //print('[CONSOLE] [create_workout_screen]  - linkedToPrevious: ${req.linkedToPrevious}');
      // 🚀 FASE 3 FIX: Log REST-PAUSE nella richiesta
      //print('[CONSOLE] [create_workout_screen]  - isRestPauseInt: ${req.isRestPauseInt}');
      //print('[CONSOLE] [create_workout_screen]  - restPauseReps: "${req.restPauseReps}"');
      //print('[CONSOLE] [create_workout_screen]  - restPauseRestSeconds: ${req.restPauseRestSeconds}');
    }

    final request = CreateWorkoutPlanRequest(
      userId: _currentUserId!,
      nome: _nameController.text.trim(),
      descrizione: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      esercizi: exerciseRequests,
    );

    //print('[CONSOLE] [create_workout_screen]Creating workout: ${request.nome}');
    _workoutBloc.createWorkout(request);
  }

  void _updateWorkout() {
    final exerciseRequests = _selectedExercises.map((exercise) {
      // DEBUG: Log tutti i valori prima del salvataggio
      //print('[CONSOLE] [create_workout_screen]Updating exercise: ${exercise.nome} (ID: ${exercise.id}, SchedaEsercizioID: ${exercise.schedaEsercizioId})');
      //print('[CONSOLE] [create_workout_screen]  - setType: "${exercise.setType}"');
      //print('[CONSOLE] [create_workout_screen]  - linkedToPreviousInt: ${exercise.linkedToPreviousInt}');
      //print('[CONSOLE] [create_workout_screen]  - isIsometricInt: ${exercise.isIsometricInt}');
      //print('[CONSOLE] [create_workout_screen]  - note: "${exercise.note}"');
      // 🚀 FASE 3 FIX: Log valori REST-PAUSE
      //print('[CONSOLE] [create_workout_screen]  - isRestPauseInt: ${exercise.isRestPauseInt}');
      //print('[CONSOLE] [create_workout_screen]  - restPauseReps: "${exercise.restPauseReps}"');
      //print('[CONSOLE] [create_workout_screen]  - restPauseRestSeconds: ${exercise.restPauseRestSeconds}');

      // 🚀 FASE 3 FIX: USA IL NUOVO HELPER METHOD
      return WorkoutExerciseRequest.fromWorkoutExercise(exercise);
    }).toList();

    // DEBUG: Log della richiesta finale
    for (int i = 0; i < exerciseRequests.length; i++) {
      final req = exerciseRequests[i];
      //print('[CONSOLE] [create_workout_screen]ExerciseRequest $i: ID=${req.id}, SchedaEsercizioID=${req.schedaEsercizioId}');
      //print('[CONSOLE] [create_workout_screen]  - setType: "${req.setType}"');
      //print('[CONSOLE] [create_workout_screen]  - linkedToPrevious: ${req.linkedToPrevious}');
      // 🚀 FASE 3 FIX: Log REST-PAUSE nella richiesta
      //print('[CONSOLE] [create_workout_screen]  - isRestPauseInt: ${req.isRestPauseInt}');
      //print('[CONSOLE] [create_workout_screen]  - restPauseReps: "${req.restPauseReps}"');
      //print('[CONSOLE] [create_workout_screen]  - restPauseRestSeconds: ${req.restPauseRestSeconds}');

      if (req.schedaEsercizioId == null) {
        //print('[CONSOLE] [create_workout_screen]ATTENZIONE: Esercizio ${req.id} non ha schedaEsercizioId!');
      }
    }

    final request = UpdateWorkoutPlanRequest(
      schedaId: widget.workoutId!,
      userId: _currentUserId,
      nome: _nameController.text.trim(),
      descrizione: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      esercizi: exerciseRequests,
    );

    //print('[CONSOLE] [create_workout_screen]Updating workout - SchedaID: ${request.schedaId}, UserID: ${request.userId}, Nome: ${request.nome}');
    //print('[CONSOLE] [create_workout_screen]Updating workout - Esercizi count: ${request.esercizi.length}');

    _workoutBloc.updateWorkout(request);
  }

  void _onCancel() {
    _workoutBloc.resetState();
    context.pop(true);
  }
}