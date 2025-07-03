import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/custom_button.dart';
import '../../features/exercises/models/exercises_response.dart';
import '../../features/workouts/models/workout_plan_models.dart';
import 'exercise_selection_dialog.dart';

class AddExerciseDuringWorkoutDialog extends StatefulWidget {
  final int userId;
  final List<ExerciseItem> availableExercises;
  final Function(WorkoutExercise) onExerciseAdded;
  final bool saveToWorkout;

  const AddExerciseDuringWorkoutDialog({
    super.key,
    required this.userId,
    required this.availableExercises,
    required this.onExerciseAdded,
    this.saveToWorkout = false,
  });

  @override
  State<AddExerciseDuringWorkoutDialog> createState() => _AddExerciseDuringWorkoutDialogState();
}

class _AddExerciseDuringWorkoutDialogState extends State<AddExerciseDuringWorkoutDialog> {
  bool _showExerciseDialog = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      backgroundColor: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.add_circle_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'Aggiungi Esercizio',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close,
                    color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 20.h),
            
            // Contenuto
            Text(
              'Vuoi aggiungere un nuovo esercizio al tuo allenamento?',
              style: TextStyle(
                fontSize: 16.sp,
                color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 20.h),
            
            // Opzioni
            Column(
              children: [
                _buildOption(
                  context,
                  'Solo per questo allenamento',
                  'L\'esercizio verrà aggiunto solo alla sessione corrente',
                  Icons.fitness_center,
                  () => _addExercise(false),
                  isDarkMode,
                ),
                
                SizedBox(height: 12.h),
                
                _buildOption(
                  context,
                  'Salva nella scheda',
                  'L\'esercizio verrà aggiunto anche alla scheda di allenamento',
                  Icons.save,
                  () => _addExercise(true),
                  isDarkMode,
                ),
              ],
            ),
            
            SizedBox(height: 20.h),
            
            // Pulsanti
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Annulla',
                    onPressed: () => Navigator.of(context).pop(),
                    type: ButtonType.outline,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: CustomButton(
                    text: 'Aggiungi',
                    onPressed: _showExerciseSelection,
                    type: ButtonType.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
    bool isDarkMode,
  ) {
    return Card(
      color: isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
      child: ListTile(
        leading: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDarkMode ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
            fontSize: 12.sp,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  void _showExerciseSelection() {
    setState(() {
      _showExerciseDialog = true;
    });
    
    showDialog(
      context: context,
      builder: (context) => ExerciseSelectionDialog(
        exercises: widget.availableExercises,
        selectedExerciseIds: const [],
        isLoading: false,
        onExerciseSelected: _onExerciseSelected,
        onDismissRequest: () => Navigator.of(context).pop(),
        currentUserId: widget.userId,
      ),
    ).then((_) {
      setState(() {
        _showExerciseDialog = false;
      });
    });
  }

  void _onExerciseSelected(ExerciseItem exerciseItem) {
    Navigator.of(context).pop(); // Chiudi dialog selezione
    
    // Mostra dialog per confermare se salvare nella scheda
    _showSaveConfirmation(exerciseItem);
  }

  void _showSaveConfirmation(ExerciseItem exerciseItem) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
        title: Text(
          'Salvare nella scheda?',
          style: TextStyle(
            color: isDarkMode ? Colors.white : AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Vuoi aggiungere "${exerciseItem.nome}" anche alla scheda di allenamento?',
          style: TextStyle(
            color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _addExerciseToWorkout(exerciseItem, false);
            },
            child: const Text('Solo ora'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _addExerciseToWorkout(exerciseItem, true);
            },
            child: const Text('Salva nella scheda'),
          ),
        ],
      ),
    );
  }

  void _addExercise(bool saveToWorkout) {
    // Questo metodo viene chiamato quando l'utente sceglie un'opzione
    // ma in realtà mostriamo prima la selezione dell'esercizio
    _showExerciseSelection();
  }

  void _addExerciseToWorkout(ExerciseItem exerciseItem, bool saveToWorkout) {
    // Converte ExerciseItem a WorkoutExercise
    final workoutExercise = WorkoutExercise(
      id: exerciseItem.id,
      schedaEsercizioId: null, // Nuovo esercizio
      nome: exerciseItem.nome,
      gruppoMuscolare: exerciseItem.gruppoMuscolare,
      attrezzatura: exerciseItem.attrezzatura,
      descrizione: exerciseItem.descrizione,
      serie: exerciseItem.serieDefault,
      ripetizioni: exerciseItem.ripetizioniDefault,
      peso: exerciseItem.pesoDefault,
      ordine: 0, // Verrà impostato dal workout
      tempoRecupero: 90,
      note: null,
      setType: 'normal',
      linkedToPreviousInt: 0,
      isIsometricInt: exerciseItem.isIsometric ? 1 : 0,
    );

    // Chiama il callback per aggiungere l'esercizio
    widget.onExerciseAdded(workoutExercise);
    
    // Chiudi il dialog principale
    Navigator.of(context).pop();
    
    // Mostra feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saveToWorkout 
              ? 'Esercizio aggiunto e salvato nella scheda!'
              : 'Esercizio aggiunto all\'allenamento!',
        ),
        backgroundColor: AppColors.success,
      ),
    );
  }
} 