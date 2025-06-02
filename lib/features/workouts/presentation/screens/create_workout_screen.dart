// lib/features/workouts/presentation/screens/create_workout_screen.dart
import 'dart:developer' as developer;

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
import '../../../../shared/theme/app_colors.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/session_service.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../bloc/workout_bloc.dart';
import '../../models/workout_plan_models.dart';

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
          }
        } else if (authState is AuthLoginSuccess) {
          setState(() {
            _currentUserId = authState.user.id;
            _isLoadingUserId = false;
          });

          if (_isEditing) {
            _loadWorkoutForEditing();
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

      // ✅ SISTEMATO: Prima verifica se abbiamo già i dati delle schede nel BLoC
      final currentState = _workoutBloc.state;
      if (currentState is WorkoutPlansLoaded) {
        // Cerca la scheda nei dati già caricati
        try {
          final existingPlan = currentState.workoutPlans.firstWhere(
                (plan) => plan.id == widget.workoutId,
          );

          developer.log('✅ Found existing plan in state: ${existingPlan.nome}', name: 'CreateWorkoutScreen');

          // ✅ IMPORTANTE: Usa i dati reali della scheda
          _populateFieldsFromWorkoutPlan(existingPlan);

          // Poi carica gli esercizi se non ci sono già
          if (existingPlan.esercizi.isEmpty) {
            _workoutBloc.loadWorkoutPlanWithData(existingPlan);
          }
          return;
        } catch (e) {
          developer.log('⚠️ Plan not found in current state, loading from scratch', name: 'CreateWorkoutScreen');
        }
      }

      // ✅ Fallback: se non abbiamo i dati nel stato, dobbiamo ricaricare tutto
      developer.log('🔄 Loading workout plans first to get correct name...', name: 'CreateWorkoutScreen');
      if (_currentUserId != null) {
        _workoutBloc.loadWorkoutPlans(_currentUserId!);
      }
    }
  }

  /// ✅ NUOVO: Popola i campi con i dati reali della scheda
  void _populateFieldsFromWorkoutPlan(WorkoutPlan workoutPlan) {
    developer.log('✅ Populating fields with real workout data: ${workoutPlan.nome}', name: 'CreateWorkoutScreen');

    _nameController.text = workoutPlan.nome;
    _descriptionController.text = workoutPlan.descrizione ?? '';

    if (workoutPlan.esercizi.isNotEmpty) {
      setState(() {
        _selectedExercises = List.from(workoutPlan.esercizi);
      });
    }
  }

  void _populateFieldsFromWorkoutData(WorkoutPlan workoutPlan, List<WorkoutExercise> exercises) {
    developer.log('✅ Populating fields with workout: ${workoutPlan.nome}', name: 'CreateWorkoutScreen');

    _nameController.text = workoutPlan.nome;
    _descriptionController.text = workoutPlan.descrizione ?? '';

    setState(() {
      _selectedExercises = List.from(exercises);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _workoutBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _workoutBloc,
      child: Scaffold(
        appBar: CustomAppBar(
          title: _isEditing ? 'Modifica Scheda' : 'Nuova Scheda',
          actions: [
            if (!_isLoadingUserId && _currentUserId != null)
              TextButton(
                onPressed: _saveWorkout,
                child: Text(
                  'Salva',
                  style: TextStyle(
                    color: AppColors.indigo600,
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
              // ✅ NUOVO: Quando si caricano le schede durante l'editing
              try {
                final existingPlan = state.workoutPlans.firstWhere(
                      (plan) => plan.id == widget.workoutId,
                );
                developer.log('✅ Found plan after loading: ${existingPlan.nome}', name: 'CreateWorkoutScreen');
                _populateFieldsFromWorkoutPlan(existingPlan);

                // Ora carica anche gli esercizi
                _workoutBloc.loadWorkoutPlanWithData(existingPlan);
              } catch (e) {
                developer.log('❌ Plan not found even after loading: ${e}', name: 'CreateWorkoutScreen');
              }
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informazioni Base',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
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
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _addExercise,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Aggiungi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.indigo600,
                foregroundColor: Colors.white,
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
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: AppColors.indigo600.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppConfig.radiusM),
        border: Border.all(
          color: AppColors.indigo600.withOpacity(0.2),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.fitness_center,
            size: 48.sp,
            color: AppColors.indigo600.withOpacity(0.5),
          ),
          SizedBox(height: 12.h),
          Text(
            'Nessun Esercizio',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            _isEditing
                ? 'Caricamento esercizi in corso...'
                : 'Aggiungi degli esercizi per creare la tua scheda',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
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
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50.h,
          child: ElevatedButton(
            onPressed: _saveWorkout,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.indigo600,
              foregroundColor: Colors.white,
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
            onPressed: () => context.pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: BorderSide(color: AppColors.border),
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

  void _addExercise() {
    setState(() {
      _selectedExercises.add(WorkoutExercise(
        id: DateTime.now().millisecondsSinceEpoch,
        nome: 'Nuovo Esercizio ${_selectedExercises.length + 1}',
        gruppoMuscolare: 'Da definire',
        serie: 3,
        ripetizioni: 10,
        peso: 20.0,
        ordine: _selectedExercises.length + 1,
        tempoRecupero: 90,
      ));
    });
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
      // 🔧 DEBUG: Log tutti i valori prima del salvataggio
      developer.log('Creating exercise: ${exercise.nome}', name: 'CreateWorkoutScreen');
      developer.log('  - setType: "${exercise.setType}"', name: 'CreateWorkoutScreen');
      developer.log('  - linkedToPreviousInt: ${exercise.linkedToPreviousInt}', name: 'CreateWorkoutScreen');
      developer.log('  - isIsometricInt: ${exercise.isIsometricInt}', name: 'CreateWorkoutScreen');
      developer.log('  - note: "${exercise.note}"', name: 'CreateWorkoutScreen');

      return WorkoutExerciseRequest(
        id: exercise.id,
        schedaEsercizioId: null,
        serie: exercise.serie,
        ripetizioni: exercise.ripetizioni,
        peso: exercise.peso,
        ordine: exercise.ordine,
        tempoRecupero: exercise.tempoRecupero,
        note: exercise.note,
        setType: exercise.setType,
        linkedToPrevious: exercise.linkedToPreviousInt,
      );
    }).toList();

    // 🔧 DEBUG: Log della richiesta finale
    for (int i = 0; i < exerciseRequests.length; i++) {
      final req = exerciseRequests[i];
      developer.log('ExerciseRequest $i:', name: 'CreateWorkoutScreen');
      developer.log('  - setType: "${req.setType}"', name: 'CreateWorkoutScreen');
      developer.log('  - linkedToPrevious: ${req.linkedToPrevious}', name: 'CreateWorkoutScreen');
    }

    final request = CreateWorkoutPlanRequest(
      userId: _currentUserId!,
      nome: _nameController.text.trim(),
      descrizione: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      esercizi: exerciseRequests,
    );

    developer.log('Creating workout: ${request.nome}', name: 'CreateWorkoutScreen');
    _workoutBloc.createWorkout(request);
  }

  void _updateWorkout() {
    final exerciseRequests = _selectedExercises.map((exercise) {
      developer.log('Converting exercise: ${exercise.nome} (ID: ${exercise.id}, SchedaEsercizioID: ${exercise.schedaEsercizioId})', name: 'CreateWorkoutScreen');

      return WorkoutExerciseRequest(
        id: exercise.id,
        schedaEsercizioId: exercise.schedaEsercizioId,
        serie: exercise.serie,
        ripetizioni: exercise.ripetizioni,
        peso: exercise.peso,
        ordine: exercise.ordine,
        tempoRecupero: exercise.tempoRecupero,
        note: exercise.note,
        setType: exercise.setType,
        linkedToPrevious: exercise.linkedToPreviousInt,
      );
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

    developer.log('Updating workout - SchedaID: ${request.schedaId}, UserID: ${request.userId}, Nome: ${request.nome}', name: 'CreateWorkoutScreen');
    developer.log('Updating workout - Esercizi count: ${request.esercizi.length}', name: 'CreateWorkoutScreen');

    _workoutBloc.updateWorkout(request);
  }
}