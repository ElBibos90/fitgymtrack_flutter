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
  bool _hasLoadedWorkoutData = false; // Per evitare caricamenti multipli
  bool get _isEditing => widget.workoutId != null;

  List<WorkoutExerciseRequest> _selectedExercises = [];

  @override
  void initState() {
    super.initState();
    _workoutBloc = getIt<WorkoutBloc>();
    _sessionService = getIt<SessionService>();
    _initializeUserId();
  }

  Future<void> _initializeUserId() async {
    try {
      // Prima prova a recuperare da SessionService
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
        // Se non c'è in SessionService, prova dall'AuthBloc
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
          // Utente non autenticato
          setState(() {
            _isLoadingUserId = false;
          });
          // Reindirizza al login
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
        context.pop(); // Torna indietro se non riesce a recuperare l'utente
      }
    }
  }

  void _loadWorkoutForEditing() {
    if (!_hasLoadedWorkoutData && widget.workoutId != null) {
      _hasLoadedWorkoutData = true;
      _workoutBloc.loadWorkoutPlanDetails(widget.workoutId!);
    }
  }

  void _populateFieldsFromWorkoutData(WorkoutPlan workoutPlan, List<WorkoutExercise> exercises) {
    // Popola i campi del form
    _nameController.text = workoutPlan.nome;
    _descriptionController.text = workoutPlan.descrizione ?? '';

    // Converte gli esercizi esistenti in WorkoutExerciseRequest
    setState(() {
      _selectedExercises = exercises.map((exercise) => WorkoutExerciseRequest(
        id: exercise.id,
        serie: exercise.serie,
        ripetizioni: exercise.ripetizioni,
        peso: exercise.peso,
        ordine: exercise.ordine,
        tempoRecupero: exercise.tempoRecupero,
        note: exercise.note,
        setType: exercise.setType,
        linkedToPrevious: exercise.linkedToPreviousInt,
      )).toList();
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
              // ✅ NUOVO: Popola i campi quando carica i dati per la modifica
              _populateFieldsFromWorkoutData(state.workoutPlan, state.exercises);
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
            // Sezione informazioni base
            _buildBasicInfoSection(),

            SizedBox(height: 24.h),

            // Sezione esercizi
            _buildExercisesSection(),

            SizedBox(height: 32.h),

            // Pulsanti azione
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

        // Nome scheda
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

        // Descrizione (opzionale)
        CustomTextField(
          controller: _descriptionController,
          label: 'Descrizione (opzionale)',
          hint: 'Aggiungi una descrizione per la tua scheda...',
          prefixIcon: Icons.description,
          maxLines: 3,
          validator: (value) {
            // Descrizione opzionale, no validation
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
          _buildExerciseCard(_selectedExercises[i], i),
      ],
    );
  }

  Widget _buildExerciseCard(WorkoutExerciseRequest exercise, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppConfig.radiusM),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Esercizio ${index + 1} (ID: ${exercise.id})', // Mostra ID per debug in edit
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _removeExercise(index),
                icon: const Icon(Icons.delete, color: AppColors.error),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              _buildExerciseParameter('Serie', exercise.serie.toString()),
              SizedBox(width: 16.w),
              _buildExerciseParameter('Rip', exercise.ripetizioni.toString()),
              SizedBox(width: 16.w),
              _buildExerciseParameter('Peso', '${exercise.peso.toStringAsFixed(1)} kg'),
            ],
          ),
          if (exercise.note?.isNotEmpty == true) ...[
            SizedBox(height: 8.h),
            Text(
              'Note: ${exercise.note}',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExerciseParameter(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
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

  void _addExercise() {
    // TODO: Navigate to exercise selection screen
    // For now, add a placeholder exercise
    setState(() {
      _selectedExercises.add(WorkoutExerciseRequest(
        id: DateTime.now().millisecondsSinceEpoch, // Placeholder ID
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
      // Riordina gli esercizi
      for (int i = 0; i < _selectedExercises.length; i++) {
        _selectedExercises[i] = WorkoutExerciseRequest(
          id: _selectedExercises[i].id,
          serie: _selectedExercises[i].serie,
          ripetizioni: _selectedExercises[i].ripetizioni,
          peso: _selectedExercises[i].peso,
          ordine: i + 1,
          tempoRecupero: _selectedExercises[i].tempoRecupero,
          note: _selectedExercises[i].note,
          setType: _selectedExercises[i].setType,
          linkedToPrevious: _selectedExercises[i].linkedToPrevious,
        );
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
    final request = CreateWorkoutPlanRequest(
      userId: _currentUserId!,
      nome: _nameController.text.trim(),
      descrizione: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      esercizi: _selectedExercises,
    );

    _workoutBloc.createWorkout(request);
  }

  void _updateWorkout() {
    final request = UpdateWorkoutPlanRequest(
      schedaId: widget.workoutId!,
      nome: _nameController.text.trim(),
      descrizione: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      esercizi: _selectedExercises,
    );

    _workoutBloc.updateWorkout(request);
  }
}