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
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  final int _currentUserId = 1; // TODO: Get from AuthBloc/SessionService
  bool get _isEditing => widget.workoutId != null;

  List<WorkoutExerciseRequest> _selectedExercises = [];

  @override
  void initState() {
    super.initState();
    _workoutBloc = getIt<WorkoutBloc>();

    if (_isEditing) {
      _loadWorkoutForEditing();
    }
  }

  void _loadWorkoutForEditing() {
    // TODO: Load workout data for editing
    // _workoutBloc.loadWorkoutPlanDetails(widget.workoutId!);
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
        body: BlocConsumer<WorkoutBloc, WorkoutState>(
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
            'Aggiungi degli esercizi per creare la tua scheda',
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
                  'Esercizio ${index + 1}', // TODO: Show actual exercise name
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
        tempoRecupero: 90, // ✅ CORRETTO: camelCase
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
          tempoRecupero: _selectedExercises[i].tempoRecupero, // ✅ CORRETTO: camelCase
          note: _selectedExercises[i].note,
          setType: _selectedExercises[i].setType, // ✅ CORRETTO: camelCase
          linkedToPrevious: _selectedExercises[i].linkedToPrevious, // ✅ CORRETTO: camelCase
        );
      }
    });
  }

  void _saveWorkout() {
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
      userId: _currentUserId, // Corretto: camelCase nel constructor
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
      schedaId: widget.workoutId!, // Corretto: camelCase nel constructor
      nome: _nameController.text.trim(),
      descrizione: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      esercizi: _selectedExercises,
    );

    _workoutBloc.updateWorkout(request);
  }
}