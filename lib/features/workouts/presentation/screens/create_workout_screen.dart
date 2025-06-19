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

  // ✅ NUOVO: Loading state locale per distinguere dal BLoC
  bool _isLocalLoading = false;

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

          print('[CONSOLE] [create_workout_screen]✅ Found existing plan in state: ${existingPlan.nome}');

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
          print('[CONSOLE] [create_workout_screen]⚠️ Plan not found in current state, loading from scratch');
        }
      }

      // Fallback: se non abbiamo i dati nel stato, dobbiamo ricaricare tutto
      print('[CONSOLE] [create_workout_screen]🔄 Loading workout plans first to get correct name...');
      if (_currentUserId != null) {
        _workoutBloc.loadWorkoutPlans(_currentUserId!);
        // Carica anche esercizi disponibili
        _loadAvailableExercises();
      }
    }
  }

  /// Popola i campi con i dati reali della scheda
  void _populateFieldsFromWorkoutPlan(WorkoutPlan workoutPlan) {
    print('[CONSOLE] [create_workout_screen]✅ Populating fields with real workout data: ${workoutPlan.nome}');

    _nameController.text = workoutPlan.nome;
    _descriptionController.text = workoutPlan.descrizione ?? '';

    if (workoutPlan.esercizi.isNotEmpty) {
      setState(() {
        _selectedExercises = List.from(workoutPlan.esercizi);
      });
    }
  }

  void _populateFieldsFromWorkoutData(WorkoutPlan workoutPlan, List<WorkoutExercise> exercises) {
    print('[CONSOLE] [create_workout_screen]✅ Populating fields with workout: ${workoutPlan.nome}');

    _nameController.text = workoutPlan.nome;
    _descriptionController.text = workoutPlan.descrizione ?? '';

    setState(() {
      _selectedExercises = List.from(exercises);
    });
  }

  /// Carica esercizi disponibili per il dialog di selezione
  void _loadAvailableExercises() {
    if (_currentUserId != null) {
      print('[CONSOLE] [create_workout_screen]Loading available exercises for user: $_currentUserId');
      setState(() {
        _isLoadingAvailableExercises = true;
      });
      _workoutBloc.loadAvailableExercises(_currentUserId!);
    }
  }

  /// Gestisce la selezione di un esercizio dal dialog
  void _onExerciseSelected(ExerciseItem exerciseItem) {
    print('[CONSOLE] [create_workout_screen]Adding exercise from dialog: ${exerciseItem.nome}');

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

  // ✅ FIX: Gestione del back navigation SEMPLIFICATA e SICURA
  void _handleBackNavigation() {
    print('[CONSOLE] [create_workout_screen]🔄 Handling back navigation - SIMPLIFIED');

    // ✅ CLEANUP FORZATO di tutti i loading states
    if (mounted) {
      setState(() {
        _isLoadingAvailableExercises = false;
        _showExerciseDialog = false;
        _isLocalLoading = false; // ✅ RESET anche local loading
      });
    }

    // ✅ STRATEGIA SEMPLICE: Se abbiamo l'utente, ricarica sempre le schede per lo stato pulito
    if (_currentUserId != null) {
      // Emetti l'evento di ricarica schede ma NON aspettare
      _workoutBloc.loadWorkoutPlans(_currentUserId!);
    }

    // ✅ TORNA INDIETRO IMMEDIATAMENTE senza aspettare il BLoC
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  // ✅ FIX: Dispose corretto con cleanup
  @override
  void dispose() {
    print('[CONSOLE] [create_workout_screen]🧹 Disposing - cleaning up');

    _nameController.dispose();
    _descriptionController.dispose();

    // ✅ CLEANUP: Reset loading states
    if (mounted) {
      setState(() {
        _isLoadingAvailableExercises = false;
        _showExerciseDialog = false;
        _isLocalLoading = false; // ✅ RESET anche local loading
      });
    }

    super.dispose();
  }

  // ✅ FIX: Build con PopScope migliorato
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Impedisce il pop automatico
      onPopInvoked: (didPop) {
        if (!didPop) {
          // ✅ CLEANUP + BACK NAVIGATION SICURA
          print('[CONSOLE] [create_workout_screen]📱 PopScope triggered - cleaning up');

          // Cleanup forzato prima del back
          if (mounted) {
            setState(() {
              _isLoadingAvailableExercises = false;
              _showExerciseDialog = false;
              _isLocalLoading = false; // ✅ RESET anche local loading
            });
          }

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
                actions: _isEditing ? [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _handleBackNavigation,
                  ),
                ] : null,
              ),
              body: BlocConsumer<WorkoutBloc, WorkoutState>(
                listener: (context, state) {
                  if (state is WorkoutPlanCreated) {
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
                    // ✅ RESET local loading quando i dettagli sono caricati
                    setState(() {
                      _isLocalLoading = false;
                    });
                    _populateFieldsFromWorkoutData(state.workoutPlan, state.exercises);
                  } else if (state is WorkoutPlansLoaded && _isEditing && widget.workoutId != null) {
                    // ✅ RESET local loading quando le schede sono caricate
                    setState(() {
                      _isLocalLoading = false;
                    });

                    // Quando si caricano le schede durante l'editing
                    try {
                      final existingPlan = state.workoutPlans.firstWhere(
                            (plan) => plan.id == widget.workoutId,
                      );
                      print('[CONSOLE] [create_workout_screen]✅ Found plan after loading: ${existingPlan.nome}');
                      _populateFieldsFromWorkoutPlan(existingPlan);

                      // Ora carica anche gli esercizi
                      _workoutBloc.loadWorkoutPlanWithData(existingPlan);

                      // Carica esercizi disponibili se non l'abbiamo già fatto
                      if (_availableExercises.isEmpty && !_isLoadingAvailableExercises) {
                        _loadAvailableExercises();
                      }
                    } catch (e) {
                      print('[CONSOLE] [create_workout_screen]❌ Plan not found even after loading: ${e}');
                    }
                  } else if (state is AvailableExercisesLoaded) {
                    // ✅ GESTISCE il caricamento degli esercizi disponibili - NON influenza loading principale
                    print('[CONSOLE] [create_workout_screen]✅ Available exercises loaded: ${state.availableExercises.length}');
                    setState(() {
                      _availableExercises = state.availableExercises;
                      _isLoadingAvailableExercises = false; // ✅ RESET LOADING esercizi
                    });
                    // ✅ NON toccare _isLocalLoading qui - gli esercizi disponibili sono separati
                  } else if (state is WorkoutError) {
                    // ✅ GESTISCE errori e reset loading states
                    print('[CONSOLE] [create_workout_screen]❌ Workout error: ${state.message}');
                    setState(() {
                      _isLoadingAvailableExercises = false; // ✅ RESET LOADING su errore
                      _isLocalLoading = false; // ✅ RESET anche local loading
                    });
                    CustomSnackbar.show(
                      context,
                      message: state.message,
                      isSuccess: false,
                    );
                  } else if (state is WorkoutLoading) {
                    // ✅ SOLO per operazioni principali, non per esercizi disponibili
                    final isMainOperation = !(state.toString().contains('Available') || state.toString().contains('exercises'));
                    if (isMainOperation) {
                      setState(() {
                        _isLocalLoading = true;
                      });
                    }
                  } else if (state is WorkoutLoadingWithMessage) {
                    // ✅ SOLO per operazioni principali che hanno messaggi importanti
                    final isMainOperation = !state.message.toLowerCase().contains('esercizi disponibili');
                    if (isMainOperation) {
                      setState(() {
                        _isLocalLoading = true;
                      });
                    }
                  }
                },
                builder: (context, state) {
                  // ✅ LOADING OVERLAY solo per operazioni principali (create, update, delete)
                  final showMainLoading = _isLocalLoading ||
                      (state is WorkoutLoadingWithMessage && !state.message.toLowerCase().contains('esercizi disponibili'));

                  return LoadingOverlay(
                    isLoading: showMainLoading,
                    message: state is WorkoutLoadingWithMessage && showMainLoading ? state.message : null,
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

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(32.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConfig.radiusM),
        border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.fitness_center_outlined,
            size: 48.sp,
            color: colorScheme.onSurface.withOpacity(0.4),
          ),
          SizedBox(height: 16.h),
          Text(
            'Nessun esercizio',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            _isEditing
                ? 'Caricamento esercizi in corso...'
                : 'Aggiungi degli esercizi per creare la tua scheda',
            style: TextStyle(
              fontSize: 14.sp,
              color: colorScheme.onSurface.withOpacity(0.6),
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
              foregroundColor: colorScheme.onSurface.withOpacity(0.6),
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
  }

  void _createWorkout() {
    final exerciseRequests = _selectedExercises.map((exercise) {
      // DEBUG: Log tutti i valori prima del salvataggio
      print('[CONSOLE] [create_workout_screen]Creating exercise: ${exercise.nome}');
      print('[CONSOLE] [create_workout_screen]  - setType: "${exercise.setType}"');
      print('[CONSOLE] [create_workout_screen]  - linkedToPreviousInt: ${exercise.linkedToPreviousInt}');
      print('[CONSOLE] [create_workout_screen]  - isIsometricInt: ${exercise.isIsometricInt}');
      print('[CONSOLE] [create_workout_screen]  - note: "${exercise.note}"');

      // 🚀 FASE 3 FIX: USA IL NUOVO HELPER METHOD
      return WorkoutExerciseRequest.fromWorkoutExercise(exercise);
    }).toList();

    final request = CreateWorkoutPlanRequest(
      userId: _currentUserId!,
      nome: _nameController.text.trim(),
      descrizione: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      esercizi: exerciseRequests,
    );

    print('[CONSOLE] [create_workout_screen]Creating workout: ${request.nome}');
    _workoutBloc.createWorkout(request);
  }

  void _updateWorkout() {
    final exerciseRequests = _selectedExercises.map((exercise) {
      // DEBUG: Log tutti i valori prima del salvataggio
      print('[CONSOLE] [create_workout_screen]Updating exercise: ${exercise.nome} (ID: ${exercise.id}, SchedaEsercizioID: ${exercise.schedaEsercizioId})');
      print('[CONSOLE] [create_workout_screen]  - setType: "${exercise.setType}"');
      print('[CONSOLE] [create_workout_screen]  - linkedToPreviousInt: ${exercise.linkedToPreviousInt}');
      print('[CONSOLE] [create_workout_screen]  - isIsometricInt: ${exercise.isIsometricInt}');
      print('[CONSOLE] [create_workout_screen]  - note: "${exercise.note}"');

      // 🚀 FASE 3 FIX: USA IL NUOVO HELPER METHOD
      return WorkoutExerciseRequest.fromWorkoutExercise(exercise);
    }).toList();

    final request = UpdateWorkoutPlanRequest(
      schedaId: widget.workoutId!,
      userId: _currentUserId,
      nome: _nameController.text.trim(),
      descrizione: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      esercizi: exerciseRequests,
    );

    print('[CONSOLE] [create_workout_screen]Updating workout - SchedaID: ${request.schedaId}, UserID: ${request.userId}, Nome: ${request.nome}');
    print('[CONSOLE] [create_workout_screen]Updating workout - Esercizi count: ${request.esercizi.length}');

    _workoutBloc.updateWorkout(request);
  }
}