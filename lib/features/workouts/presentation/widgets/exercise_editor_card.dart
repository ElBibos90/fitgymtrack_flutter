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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  color: isDark ? const Color(0xFF90CAF9) : AppColors.indigo600,
                  borderRadius: BorderRadius.circular(15.r),
                ),
                child: Center(
                  child: Text(
                    '${widget.index + 1}',
                    style: TextStyle(
                      color: isDark ? AppColors.backgroundDark : Colors.white,
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
                        color: colorScheme.onSurface, // ✅ DINAMICO!
                      ),
                    ),
                    if (widget.exercise.gruppoMuscolare != null) ...[
                      SizedBox(height: 2.h),
                      Text(
                        widget.exercise.gruppoMuscolare!,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: colorScheme.onSurface.withOpacity(0.6), // ✅ DINAMICO!
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
                  icon: Icon(
                    Icons.keyboard_arrow_up,
                    color: colorScheme.onSurface.withOpacity(0.6), // ✅ DINAMICO!
                  ),
                  iconSize: 20.sp,
                  visualDensity: VisualDensity.compact,
                ),
              ],
              if (!widget.isLast) ...[
                IconButton(
                  onPressed: widget.onMoveDown,
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    color: colorScheme.onSurface.withOpacity(0.6), // ✅ DINAMICO!
                  ),
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
                  color: colorScheme.onSurface.withOpacity(0.6), // ✅ DINAMICO!
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
                          color: colorScheme.onSurface.withOpacity(0.6), // ✅ DINAMICO!
                        ),
                      ),
                      SizedBox(height: 4.h),
                      TextFormField(
                        controller: _serieController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                          color: colorScheme.onSurface, // ✅ DINAMICO!
                        ),
                        decoration: InputDecoration(
                          hintText: '3',
                          hintStyle: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.4), // ✅ DINAMICO!
                          ),
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
                          color: colorScheme.onSurface.withOpacity(0.6), // ✅ DINAMICO!
                        ),
                      ),
                      SizedBox(height: 4.h),
                      TextFormField(
                        controller: _ripetizioniController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                          color: colorScheme.onSurface, // ✅ DINAMICO!
                        ),
                        decoration: InputDecoration(
                          hintText: '10',
                          hintStyle: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.4), // ✅ DINAMICO!
                          ),
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
                          color: colorScheme.onSurface.withOpacity(0.6), // ✅ DINAMICO!
                        ),
                      ),
                      SizedBox(height: 4.h),
                      TextFormField(
                        controller: _pesoController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: TextStyle(
                          color: colorScheme.onSurface, // ✅ DINAMICO!
                        ),
                        decoration: InputDecoration(
                          hintText: '0.0',
                          hintStyle: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.4), // ✅ DINAMICO!
                          ),
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
                          color: colorScheme.onSurface.withOpacity(0.6), // ✅ DINAMICO!
                        ),
                      ),
                      SizedBox(height: 4.h),
                      TextFormField(
                        controller: _tempoRecuperoController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                          color: colorScheme.onSurface, // ✅ DINAMICO!
                        ),
                        decoration: InputDecoration(
                          hintText: '90',
                          hintStyle: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.4), // ✅ DINAMICO!
                          ),
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
                    color: colorScheme.onSurface.withOpacity(0.6), // ✅ DINAMICO!
                  ),
                ),
                SizedBox(height: 4.h),
                TextFormField(
                  controller: _noteController,
                  maxLines: 2,
                  style: TextStyle(
                    color: colorScheme.onSurface, // ✅ DINAMICO!
                  ),
                  decoration: InputDecoration(
                    hintText: 'Aggiungi note per questo esercizio...',
                    hintStyle: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.4), // ✅ DINAMICO!
                    ),
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
                _buildCompactStat(context, 'Serie', widget.exercise.serie.toString()),
                SizedBox(width: AppConfig.spacingM.w),
                _buildCompactStat(context, 'Rip', widget.exercise.ripetizioni.toString()),
                if (widget.exercise.peso > 0) ...[
                  SizedBox(width: AppConfig.spacingM.w),
                  _buildCompactStat(context, 'Peso', '${widget.exercise.peso.toStringAsFixed(1)} kg'),
                ],
                SizedBox(width: AppConfig.spacingM.w),
                _buildCompactStat(context, 'Rec', '${widget.exercise.tempoRecupero}s'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactStat(BuildContext context, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10.sp,
            color: colorScheme.onSurface.withOpacity(0.6), // ✅ DINAMICO!
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.sp,
            color: colorScheme.onSurface, // ✅ DINAMICO!
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}