// lib/shared/widgets/workout_exercise_editor.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:developer' as developer;

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
  }

  @override
  void dispose() {
    _serieController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    _recoveryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    // 🔧 DEBUG: Log dei valori prima dell'update
    developer.log('Saving changes for exercise: ${widget.exercise.nome}', name: 'WorkoutExerciseEditor');
    developer.log('  - selectedSetType: "$_selectedSetType"', name: 'WorkoutExerciseEditor');
    developer.log('  - linkedToPrevious: $_linkedToPrevious', name: 'WorkoutExerciseEditor');
    developer.log('  - isIsometric: $_isIsometric', name: 'WorkoutExerciseEditor');
    developer.log('  - notes: "${_notesController.text}"', name: 'WorkoutExerciseEditor');

    final updatedExercise = widget.exercise.safeCopy(
      serie: int.tryParse(_serieController.text) ?? widget.exercise.serie,
      ripetizioni: int.tryParse(_repsController.text) ?? widget.exercise.ripetizioni,
      peso: double.tryParse(_weightController.text) ?? widget.exercise.peso,
      tempoRecupero: int.tryParse(_recoveryController.text) ?? widget.exercise.tempoRecupero,
      note: _notesController.text.isEmpty ? null : _notesController.text,
      setType: _selectedSetType,
      linkedToPrevious: _linkedToPrevious,
      isIsometric: _isIsometric,
    );

    // 🔧 DEBUG: Log del risultato dopo safeCopy
    developer.log('After safeCopy:', name: 'WorkoutExerciseEditor');
    developer.log('  - setType: "${updatedExercise.setType}"', name: 'WorkoutExerciseEditor');
    developer.log('  - linkedToPreviousInt: ${updatedExercise.linkedToPreviousInt}', name: 'WorkoutExerciseEditor');
    developer.log('  - isIsometricInt: ${updatedExercise.isIsometricInt}', name: 'WorkoutExerciseEditor');
    developer.log('  - note: "${updatedExercise.note}"', name: 'WorkoutExerciseEditor');

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
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppConfig.radiusM),
        border: Border.all(
          color: _isEditing ? AppColors.indigo600 : AppColors.border,
          width: _isEditing ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con nome esercizio e azioni
          _buildHeader(),

          // Parametri (view o edit mode)
          if (_isEditing)
            _buildEditMode()
          else
            _buildViewMode(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: _isEditing ? AppColors.indigo600.withOpacity(0.05) : Colors.transparent,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppConfig.radiusM),
          topRight: Radius.circular(AppConfig.radiusM),
        ),
      ),
      child: Row(
        children: [
          // Move up/down buttons
          if (!_isEditing) ...[
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: widget.isFirst ? null : widget.onMoveUp,
                  icon: Icon(Icons.keyboard_arrow_up, size: 20.sp),
                  constraints: BoxConstraints(minWidth: 32.w, minHeight: 32.w),
                  padding: EdgeInsets.zero,
                  color: widget.isFirst ? AppColors.textSecondary : AppColors.indigo600,
                ),
                IconButton(
                  onPressed: widget.isLast ? null : widget.onMoveDown,
                  icon: Icon(Icons.keyboard_arrow_down, size: 20.sp),
                  constraints: BoxConstraints(minWidth: 32.w, minHeight: 32.w),
                  padding: EdgeInsets.zero,
                  color: widget.isLast ? AppColors.textSecondary : AppColors.indigo600,
                ),
              ],
            ),
            SizedBox(width: 8.w),
          ],

          // Exercise info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.exercise.nome,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (widget.exercise.gruppoMuscolare?.isNotEmpty == true) ...[
                  SizedBox(height: 2.h),
                  Text(
                    widget.exercise.gruppoMuscolare!,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],

                // Set type badge
                if (_selectedSetType != 'normal') ...[
                  SizedBox(height: 4.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: _getSetTypeColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: _getSetTypeColor().withOpacity(0.3)),
                    ),
                    child: Text(
                      _getSetTypeLabel(),
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: _getSetTypeColor(),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Action buttons
          if (_isEditing) ...[
            IconButton(
              onPressed: _cancelChanges,
              icon: const Icon(Icons.close, color: AppColors.error),
              constraints: BoxConstraints(minWidth: 40.w, minHeight: 40.w),
            ),
            IconButton(
              onPressed: _saveChanges,
              icon: const Icon(Icons.check, color: AppColors.success),
              constraints: BoxConstraints(minWidth: 40.w, minHeight: 40.w),
            ),
          ] else ...[
            IconButton(
              onPressed: () => setState(() => _isEditing = true),
              icon: Icon(Icons.edit, color: AppColors.indigo600, size: 20.sp),
              constraints: BoxConstraints(minWidth: 40.w, minHeight: 40.w),
            ),
            IconButton(
              onPressed: widget.onDelete,
              icon: Icon(Icons.delete, color: AppColors.error, size: 20.sp),
              constraints: BoxConstraints(minWidth: 40.w, minHeight: 40.w),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildViewMode() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Parametri principali in griglia
          Row(
            children: [
              _buildViewParameter('Serie', widget.exercise.serie.toString()),
              _buildViewParameter(
                  _isIsometric ? 'Secondi' : 'Ripetizioni',
                  widget.exercise.ripetizioni.toString()
              ),
              _buildViewParameter('Peso', '${widget.exercise.peso.toStringAsFixed(1)} kg'),
              _buildViewParameter('Recupero', '${widget.exercise.tempoRecupero}s'),
            ],
          ),

          // Note (se presenti)
          if (widget.exercise.note?.isNotEmpty == true) ...[
            SizedBox(height: 12.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: AppColors.border.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Note',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    widget.exercise.note!,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Indicators - Linked solo se ha senso per il set type
          if ((_linkedToPrevious && (_selectedSetType == 'superset' || _selectedSetType == 'circuit')) || _isIsometric) ...[
            SizedBox(height: 8.h),
            Wrap(
              spacing: 8.w,
              children: [
                if (_linkedToPrevious && (_selectedSetType == 'superset' || _selectedSetType == 'circuit'))
                  _buildIndicator(
                      _selectedSetType == 'superset' ? '🔗 Superset' : '🔗 Circuit',
                      AppColors.warning
                  ),
                if (_isIsometric)
                  _buildIndicator('⏱️ Isometrico', AppColors.indigo600),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildViewParameter(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.sp,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildEditMode() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Parametri principali
          Row(
            children: [
              Expanded(child: _buildEditField('Serie', _serieController, false)),
              SizedBox(width: 12.w),
              Expanded(child: _buildEditField(
                  _isIsometric ? 'Secondi' : 'Ripetizioni',
                  _repsController,
                  false
              )),
            ],
          ),

          SizedBox(height: 12.h),

          Row(
            children: [
              Expanded(child: _buildEditField('Peso (kg)', _weightController, true)),
              SizedBox(width: 12.w),
              Expanded(child: _buildEditField('Recupero (s)', _recoveryController, false)),
            ],
          ),

          SizedBox(height: 16.h),

          // Set Type Dropdown
          _buildSetTypeDropdown(),

          SizedBox(height: 16.h),

          // Checkboxes - Linked to Previous solo per Superset e Circuit
          if (_selectedSetType == 'superset' || _selectedSetType == 'circuit') ...[
            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    title: Text(
                      'Collegato al precedente',
                      style: TextStyle(fontSize: 14.sp),
                    ),
                    subtitle: Text(
                      _selectedSetType == 'superset'
                          ? 'Esegui subito dopo l\'esercizio precedente'
                          : 'Parte del circuito precedente',
                      style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
                    ),
                    value: _linkedToPrevious,
                    onChanged: (value) => setState(() => _linkedToPrevious = value ?? false),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],

          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  title: Text(
                    'Esercizio isometrico',
                    style: TextStyle(fontSize: 14.sp),
                  ),
                  subtitle: Text(
                    'Mantieni la posizione per i secondi indicati',
                    style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
                  ),
                  value: _isIsometric,
                  onChanged: (value) => setState(() => _isIsometric = value ?? false),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // Note field
          _buildNotesField(),
        ],
      ),
    );
  }

  Widget _buildEditField(String label, TextEditingController controller, bool isDecimal) {
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
        SizedBox(height: 4.h),
        TextFormField(
          controller: controller,
          keyboardType: isDecimal
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.number,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: AppColors.indigo600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSetTypeDropdown() {
    const setTypes = [
      ('normal', 'Normale'),
      ('superset', 'Superset'),
      ('dropset', 'Dropset'),
      ('rest_pause', 'Rest Pause'),
      ('giant_set', 'Giant Set'),
      ('circuit', 'Circuit'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo di Serie',
          style: TextStyle(
            fontSize: 12.sp,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4.h),
        DropdownButtonFormField<String>(
          value: _selectedSetType,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: AppColors.border),
            ),
          ),
          items: setTypes.map((type) => DropdownMenuItem(
            value: type.$1,
            child: Text(type.$2),
          )).toList(),
          onChanged: (value) {
            setState(() {
              _selectedSetType = value ?? 'normal';
              // Reset linked to previous se non è più appropriato
              if (_selectedSetType != 'superset' && _selectedSetType != 'circuit') {
                _linkedToPrevious = false;
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Note (opzionale)',
          style: TextStyle(
            fontSize: 12.sp,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4.h),
        TextFormField(
          controller: _notesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Aggiungi note per questo esercizio...',
            isDense: true,
            contentPadding: EdgeInsets.all(12.w),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: AppColors.indigo600),
            ),
          ),
        ),
      ],
    );
  }

  Color _getSetTypeColor() {
    switch (_selectedSetType) {
      case 'superset':
        return AppColors.warning;
      case 'dropset':
        return AppColors.error;
      case 'rest_pause':
        return Colors.purple;
      case 'giant_set':
        return Colors.orange;
      case 'circuit':
        return Colors.green;
      default:
        return AppColors.indigo600;
    }
  }

  String _getSetTypeLabel() {
    switch (_selectedSetType) {
      case 'superset':
        return 'SUPERSET';
      case 'dropset':
        return 'DROPSET';
      case 'rest_pause':
        return 'REST PAUSE';
      case 'giant_set':
        return 'GIANT SET';
      case 'circuit':
        return 'CIRCUIT';
      default:
        return 'NORMALE';
    }
  }
}