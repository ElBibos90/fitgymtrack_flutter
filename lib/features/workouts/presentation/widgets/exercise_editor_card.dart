// lib/features/workouts/presentation/widgets/exercise_editor_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/custom_card.dart';
import '../../../../core/config/app_config.dart';
import '../../models/workout_plan_models.dart';

class ExerciseEditorCard extends StatefulWidget {
  final WorkoutExercise exercise;
  final int index;
  final bool isFirst;
  final bool isLast;
  final Function(WorkoutExercise) onUpdate;
  final VoidCallback onDelete;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  const ExerciseEditorCard({
    super.key,
    required this.exercise,
    required this.index,
    required this.isFirst,
    required this.isLast,
    required this.onUpdate,
    required this.onDelete,
    this.onMoveUp,
    this.onMoveDown,
  });

  @override
  State<ExerciseEditorCard> createState() => _ExerciseEditorCardState();
}

class _ExerciseEditorCardState extends State<ExerciseEditorCard> {
  late TextEditingController _serieController;
  late TextEditingController _ripetizioniController;
  late TextEditingController _pesoController;
  late TextEditingController _tempoRecuperoController;
  late TextEditingController _noteController;

  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _serieController = TextEditingController(text: widget.exercise.serie.toString());
    _ripetizioniController = TextEditingController(text: widget.exercise.ripetizioni.toString());
    _pesoController = TextEditingController(
      text: widget.exercise.peso > 0 ? widget.exercise.peso.toString() : '',
    );
    _tempoRecuperoController = TextEditingController(text: widget.exercise.tempoRecupero.toString());
    _noteController = TextEditingController(text: widget.exercise.note ?? '');

    // Aggiungi listener per aggiornamenti automatici
    _serieController.addListener(_updateExercise);
    _ripetizioniController.addListener(_updateExercise);
    _pesoController.addListener(_updateExercise);
    _tempoRecuperoController.addListener(_updateExercise);
    _noteController.addListener(_updateExercise);
  }

  @override
  void dispose() {
    _serieController.dispose();
    _ripetizioniController.dispose();
    _pesoController.dispose();
    _tempoRecuperoController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _updateExercise() {
    final updatedExercise = widget.exercise.safeCopy(
      serie: int.tryParse(_serieController.text) ?? widget.exercise.serie,
      ripetizioni: int.tryParse(_ripetizioniController.text) ?? widget.exercise.ripetizioni,
      peso: double.tryParse(_pesoController.text) ?? widget.exercise.peso,
      tempoRecupero: int.tryParse(_tempoRecuperoController.text) ?? widget.exercise.tempoRecupero,
      note: _noteController.text.isEmpty ? null : _noteController.text,
    );

    widget.onUpdate(updatedExercise);
  }

  Future<void> _showDeleteConfirmationDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rimuovi Esercizio'),
        content: Text('Sei sicuro di voler rimuovere "${widget.exercise.nome}" dalla scheda?'),
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
            child: const Text('Rimuovi'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      widget.onDelete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      margin: EdgeInsets.only(bottom: AppConfig.spacingS.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header dell'esercizio
          Row(
            children: [
              // Numero esercizio
              Container(
                width: 30.w,
                height: 30.w,
                decoration: BoxDecoration(
                  color: AppColors.indigo600,
                  borderRadius: BorderRadius.circular(15.r),
                ),
                child: Center(
                  child: Text(
                    '${widget.index + 1}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              SizedBox(width: AppConfig.spacingS.w),

              // Nome esercizio
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.exercise.nome,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (widget.exercise.gruppoMuscolare != null) ...[
                      SizedBox(height: 2.h),
                      Text(
                        widget.exercise.gruppoMuscolare!,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Controlli movimento
              if (!widget.isFirst) ...[
                IconButton(
                  onPressed: widget.onMoveUp,
                  icon: const Icon(Icons.keyboard_arrow_up),
                  iconSize: 20.sp,
                  visualDensity: VisualDensity.compact,
                ),
              ],
              if (!widget.isLast) ...[
                IconButton(
                  onPressed: widget.onMoveDown,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  iconSize: 20.sp,
                  visualDensity: VisualDensity.compact,
                ),
              ],

              // Pulsante espandi/collassa
              IconButton(
                onPressed: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                icon: Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                ),
                iconSize: 20.sp,
              ),

              // Pulsante elimina
              IconButton(
                onPressed: _showDeleteConfirmationDialog,
                icon: const Icon(Icons.delete),
                color: AppColors.error,
                iconSize: 20.sp,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),

          // Sezione espandibile con i dettagli
          if (_isExpanded) ...[
            SizedBox(height: AppConfig.spacingM.h),

            // Prima riga: Serie e Ripetizioni
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Serie',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      TextFormField(
                        controller: _serieController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '3',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(width: AppConfig.spacingM.w),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ripetizioni',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      TextFormField(
                        controller: _ripetizioniController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '10',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: AppConfig.spacingM.h),

            // Seconda riga: Peso e Tempo Recupero
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Peso (kg)',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      TextFormField(
                        controller: _pesoController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: '0.0',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(width: AppConfig.spacingM.w),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recupero (sec)',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      TextFormField(
                        controller: _tempoRecuperoController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '90',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: AppConfig.spacingM.h),

            // Note
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Note (opzionale)',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 4.h),
                TextFormField(
                  controller: _noteController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Aggiungi note per questo esercizio...',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Vista compatta quando non espanso
            SizedBox(height: AppConfig.spacingS.h),

            Row(
              children: [
                _buildCompactStat('Serie', widget.exercise.serie.toString()),
                SizedBox(width: AppConfig.spacingM.w),
                _buildCompactStat('Rip', widget.exercise.ripetizioni.toString()),
                if (widget.exercise.peso > 0) ...[
                  SizedBox(width: AppConfig.spacingM.w),
                  _buildCompactStat('Peso', '${widget.exercise.peso.toStringAsFixed(1)} kg'),
                ],
                SizedBox(width: AppConfig.spacingM.w),
                _buildCompactStat('Rec', '${widget.exercise.tempoRecupero}s'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10.sp,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.sp,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}