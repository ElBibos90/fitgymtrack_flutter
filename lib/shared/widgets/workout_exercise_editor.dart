// lib/shared/widgets/workout_exercise_editor.dart
// 🚀 FASE 4: Aggiunta UI per configurazione REST-PAUSE
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../../core/config/app_config.dart';
import '../../features/workouts/models/workout_plan_models.dart';

class WorkoutExerciseEditor extends StatefulWidget {
  final WorkoutExercise exercise;
  final Function(WorkoutExercise) onUpdate;
  final VoidCallback onDelete;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final bool isFirst;
  final bool isLast;

  const WorkoutExerciseEditor({
    super.key,
    required this.exercise,
    required this.onUpdate,
    required this.onDelete,
    this.onMoveUp,
    this.onMoveDown,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  State<WorkoutExerciseEditor> createState() => _WorkoutExerciseEditorState();
}

class _WorkoutExerciseEditorState extends State<WorkoutExerciseEditor> {
  bool _isEditing = false;
  late TextEditingController _serieController;
  late TextEditingController _repsController;
  late TextEditingController _weightController;
  late TextEditingController _recoveryController;
  late TextEditingController _notesController;

  late String _selectedSetType;
  late bool _linkedToPrevious;
  late bool _isIsometric;

  // 🚀 FASE 4: NUOVI CONTROLLI REST-PAUSE
  late bool _isRestPause;
  late TextEditingController _restPauseRepsController;
  late double _restPauseRestSeconds;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _serieController = TextEditingController(text: widget.exercise.serie.toString());
    _repsController = TextEditingController(text: widget.exercise.ripetizioni.toString());
    _weightController = TextEditingController(text: widget.exercise.peso.toStringAsFixed(1));
    _recoveryController = TextEditingController(text: widget.exercise.tempoRecupero.toString());
    _notesController = TextEditingController(text: widget.exercise.note ?? '');

    _selectedSetType = widget.exercise.setType;
    _linkedToPrevious = widget.exercise.linkedToPrevious;
    _isIsometric = widget.exercise.isIsometric;

    // 🚀 FASE 4: Inizializzazione controlli REST-PAUSE
    _isRestPause = widget.exercise.isRestPause;
    _restPauseRepsController = TextEditingController(text: widget.exercise.restPauseReps ?? '');
    _restPauseRestSeconds = widget.exercise.restPauseRestSeconds.toDouble();
  }

  @override
  void dispose() {
    _serieController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    _recoveryController.dispose();
    _notesController.dispose();
    // 🚀 FASE 4: Dispose nuovo controller
    _restPauseRepsController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    // 🔧 DEBUG: Log dei valori prima dell'update
    print('[CONSOLE] [workout_exercise_editor]Saving changes for exercise: ${widget.exercise.nome}');
    print('[CONSOLE] [workout_exercise_editor]  - selectedSetType: "$_selectedSetType"');
    print('[CONSOLE] [workout_exercise_editor]  - linkedToPrevious: $_linkedToPrevious');
    print('[CONSOLE] [workout_exercise_editor]  - isIsometric: $_isIsometric');
    print('[CONSOLE] [workout_exercise_editor]  - notes: "${_notesController.text}"');
    // 🚀 FASE 4: Log valori REST-PAUSE
    print('[CONSOLE] [workout_exercise_editor]  - isRestPause: $_isRestPause');
    print('[CONSOLE] [workout_exercise_editor]  - restPauseReps: "${_restPauseRepsController.text}"');
    print('[CONSOLE] [workout_exercise_editor]  - restPauseRestSeconds: $_restPauseRestSeconds');

    final updatedExercise = widget.exercise.safeCopy(
      serie: int.tryParse(_serieController.text) ?? widget.exercise.serie,
      ripetizioni: int.tryParse(_repsController.text) ?? widget.exercise.ripetizioni,
      peso: double.tryParse(_weightController.text) ?? widget.exercise.peso,
      tempoRecupero: int.tryParse(_recoveryController.text) ?? widget.exercise.tempoRecupero,
      note: _notesController.text.isEmpty ? null : _notesController.text,
      setType: _selectedSetType,
      linkedToPrevious: _linkedToPrevious,
      isIsometric: _isIsometric,
      // 🚀 FASE 4: Aggiunto supporto parametri REST-PAUSE
      isRestPause: _isRestPause,
      restPauseReps: _isRestPause && _restPauseRepsController.text.isNotEmpty
          ? _restPauseRepsController.text
          : null,
      restPauseRestSeconds: _isRestPause ? _restPauseRestSeconds.round() : 15,
    );

    // 🔧 DEBUG: Log del risultato dopo safeCopy
    print('[CONSOLE] [workout_exercise_editor]After safeCopy:');
    print('[CONSOLE] [workout_exercise_editor]  - setType: "${updatedExercise.setType}"');
    print('[CONSOLE] [workout_exercise_editor]  - linkedToPreviousInt: ${updatedExercise.linkedToPreviousInt}');
    print('[CONSOLE] [workout_exercise_editor]  - isIsometricInt: ${updatedExercise.isIsometricInt}');
    print('[CONSOLE] [workout_exercise_editor]  - note: "${updatedExercise.note}"');
    // 🚀 FASE 4: Log risultato REST-PAUSE
    print('[CONSOLE] [workout_exercise_editor]  - isRestPauseInt: ${updatedExercise.isRestPauseInt}');
    print('[CONSOLE] [workout_exercise_editor]  - restPauseReps: "${updatedExercise.restPauseReps}"');
    print('[CONSOLE] [workout_exercise_editor]  - restPauseRestSeconds: ${updatedExercise.restPauseRestSeconds}');

    widget.onUpdate(updatedExercise);

    setState(() {
      _isEditing = false;
    });
  }

  void _cancelChanges() {
    _initializeControllers();
    setState(() {
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConfig.radiusM),
        border: Border.all(
          color: _isEditing
              ? (isDark ? const Color(0xFF90CAF9) : AppColors.indigo600)
              : colorScheme.outline.withOpacity(0.3),
          width: _isEditing ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con nome esercizio e azioni
          _buildHeader(context),

          // Parametri (view o edit mode)
          if (_isEditing)
            _buildEditMode(context)
          else
            _buildViewMode(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: _isEditing
            ? (isDark ? const Color(0xFF90CAF9).withOpacity(0.1) : AppColors.indigo600.withOpacity(0.1))
            : Colors.transparent,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppConfig.radiusM),
          topRight: Radius.circular(AppConfig.radiusM),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.exercise.nome,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (widget.exercise.gruppoMuscolare != null) ...[
                  SizedBox(height: 4.h),
                  Text(
                    widget.exercise.gruppoMuscolare!,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
                // 🚀 FASE 4: Indicatore REST-PAUSE nella view mode
                if (!_isEditing && widget.exercise.isRestPause) ...[
                  SizedBox(height: 4.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.flash_on,
                          size: 14.sp,
                          color: Colors.deepPurple,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'REST-PAUSE',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.deepPurple,
                          ),
                        ),
                        if (widget.exercise.restPauseReps != null) ...[
                          SizedBox(width: 4.w),
                          Text(
                            '(${widget.exercise.restPauseReps})',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.deepPurple.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Azioni (move, edit, delete)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_isEditing) ...[
                // Move up
                if (!widget.isFirst)
                  IconButton(
                    onPressed: widget.onMoveUp,
                    icon: Icon(
                      Icons.keyboard_arrow_up,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                // Move down
                if (!widget.isLast)
                  IconButton(
                    onPressed: widget.onMoveDown,
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                // Edit
                IconButton(
                  onPressed: () => setState(() => _isEditing = true),
                  icon: Icon(
                    Icons.edit,
                    color: isDark ? const Color(0xFF90CAF9) : AppColors.indigo600,
                  ),
                ),
                // Delete
                IconButton(
                  onPressed: widget.onDelete,
                  icon: Icon(
                    Icons.delete,
                    color: Colors.red,
                  ),
                ),
              ] else ...[
                // Save
                IconButton(
                  onPressed: _saveChanges,
                  icon: Icon(
                    Icons.check,
                    color: Colors.green,
                  ),
                ),
                // Cancel
                IconButton(
                  onPressed: _cancelChanges,
                  icon: Icon(
                    Icons.close,
                    color: Colors.grey,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewMode(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInfoTile(
                  'Serie',
                  widget.exercise.serie.toString(),
                  Icons.repeat,
                  colorScheme,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildInfoTile(
                  'Ripetizioni',
                  widget.exercise.ripetizioni.toString(),
                  Icons.fitness_center,
                  colorScheme,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _buildInfoTile(
                  'Peso',
                  '${widget.exercise.peso.toStringAsFixed(1)} kg',
                  Icons.line_weight,
                  colorScheme,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildInfoTile(
                  'Recupero',
                  '${widget.exercise.tempoRecupero}s',
                  Icons.timer,
                  colorScheme,
                ),
              ),
            ],
          ),
          if (widget.exercise.note != null && widget.exercise.note!.isNotEmpty) ...[
            SizedBox(height: 12.h),
            _buildInfoTile(
              'Note',
              widget.exercise.note!,
              Icons.note,
              colorScheme,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEditMode(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Parametri base
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _serieController,
                  label: 'Serie',
                  keyboardType: TextInputType.number,
                  colorScheme: colorScheme,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildTextField(
                  controller: _repsController,
                  label: 'Ripetizioni',
                  keyboardType: TextInputType.number,
                  colorScheme: colorScheme,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _weightController,
                  label: 'Peso (kg)',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  colorScheme: colorScheme,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildTextField(
                  controller: _recoveryController,
                  label: 'Recupero (s)',
                  keyboardType: TextInputType.number,
                  colorScheme: colorScheme,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Set Type Dropdown
          _buildSetTypeDropdown(colorScheme),
          SizedBox(height: 16.h),

          // 🚀 FASE 4: SEZIONE REST-PAUSE
          _buildRestPauseSection(colorScheme),
          SizedBox(height: 16.h),

          // Options switches
          _buildOptionsRow(colorScheme),
          SizedBox(height: 16.h),

          // Note field
          _buildTextField(
            controller: _notesController,
            label: 'Note (opzionali)',
            maxLines: 2,
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }

  // 🚀 FASE 4: NUOVA SEZIONE REST-PAUSE UI
  Widget _buildRestPauseSection(ColorScheme colorScheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: _isRestPause
            ? Colors.deepPurple.withOpacity(0.05)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConfig.radiusM),
        border: Border.all(
          color: _isRestPause
              ? Colors.deepPurple.withOpacity(0.3)
              : colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header REST-PAUSE
          Row(
            children: [
              Icon(
                Icons.flash_on,
                size: 20.sp,
                color: _isRestPause ? Colors.deepPurple : colorScheme.onSurface.withOpacity(0.6),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'REST-PAUSE',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: _isRestPause ? Colors.deepPurple : colorScheme.onSurface,
                  ),
                ),
              ),
              Switch(
                value: _isRestPause,
                onChanged: (value) {
                  setState(() {
                    _isRestPause = value;
                    if (!value) {
                      // Reset valori quando disabilitato
                      _restPauseRepsController.clear();
                      _restPauseRestSeconds = 15;
                    }
                  });
                },
                activeColor: Colors.deepPurple,
              ),
            ],
          ),

          if (_isRestPause) ...[
            SizedBox(height: 12.h),

            // Descrizione
            Text(
              'Il REST-PAUSE permette di continuare la serie dopo un breve recupero quando raggiungi il cedimento muscolare.',
              style: TextStyle(
                fontSize: 14.sp,
                color: colorScheme.onSurface.withOpacity(0.7),
                height: 1.4,
              ),
            ),
            SizedBox(height: 16.h),

            // Sequenza ripetizioni
            _buildTextField(
              controller: _restPauseRepsController,
              label: 'Sequenza ripetizioni',
              hint: 'es. 8+4+2 o 6+3+2+1',
              keyboardType: TextInputType.text,
              colorScheme: colorScheme,
              helperText: 'Indica le ripetizioni per ogni mini-serie separata da "+"',
            ),
            SizedBox(height: 16.h),

            // Slider recupero tra mini-serie
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recupero tra mini-serie',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${_restPauseRestSeconds.round()}s',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.deepPurple,
                    thumbColor: Colors.deepPurple,
                    overlayColor: Colors.deepPurple.withOpacity(0.2),
                  ),
                  child: Slider(
                    value: _restPauseRestSeconds,
                    min: 5,
                    max: 30,
                    divisions: 25,
                    onChanged: (value) {
                      setState(() {
                        _restPauseRestSeconds = value;
                      });
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '5s',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    Text(
                      '30s',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8.h),

            // Helper text
            Text(
              'Recupero breve ottimale: 10-15 secondi',
              style: TextStyle(
                fontSize: 12.sp,
                color: colorScheme.onSurface.withOpacity(0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSetTypeDropdown(ColorScheme colorScheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DropdownButtonFormField<String>(
      value: _selectedSetType,
      style: TextStyle(color: colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: 'Tipo di serie',
        labelStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConfig.radiusS),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConfig.radiusS),
          borderSide: BorderSide(color: isDark ? const Color(0xFF90CAF9) : AppColors.indigo600),
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'normal', child: Text('Normale')),
        DropdownMenuItem(value: 'superset', child: Text('Superset')),
        DropdownMenuItem(value: 'dropset', child: Text('Dropset')),
        DropdownMenuItem(value: 'giant_set', child: Text('Giant Set')),
        DropdownMenuItem(value: 'circuit', child: Text('Circuit')),
      ],
      onChanged: (value) => setState(() => _selectedSetType = value ?? 'normal'),
    );
  }

  Widget _buildOptionsRow(ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Switch(
                value: _linkedToPrevious,
                onChanged: (value) => setState(() => _linkedToPrevious = value),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Collegato al precedente',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Row(
            children: [
              Switch(
                value: _isIsometric,
                onChanged: (value) => setState(() => _isIsometric = value),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Isometrico',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? helperText,
    TextInputType? keyboardType,
    int maxLines = 1,
    required ColorScheme colorScheme,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(color: colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helperText,
        labelStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
        hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.4)),
        helperStyle: TextStyle(
          color: colorScheme.onSurface.withOpacity(0.6),
          fontSize: 12.sp,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConfig.radiusS),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConfig.radiusS),
          borderSide: BorderSide(color: isDark ? const Color(0xFF90CAF9) : AppColors.indigo600),
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConfig.radiusS),
        border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18.sp,
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}