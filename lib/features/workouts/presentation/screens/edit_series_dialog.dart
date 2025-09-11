// lib/features/workouts/presentation/screens/edit_series_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/custom_snackbar.dart';
import '../../models/active_workout_models.dart';

/// 🏋️ EDIT SERIES DIALOG: Dialog per modificare i dettagli di una serie completata
class EditSeriesDialog extends StatefulWidget {
  final CompletedSeriesData series;
  final Function(double weight, int reps, int? recoveryTime, String? notes) onSave;

  const EditSeriesDialog({
    super.key,
    required this.series,
    required this.onSave,
  });

  @override
  State<EditSeriesDialog> createState() => _EditSeriesDialogState();
}

class _EditSeriesDialogState extends State<EditSeriesDialog> {
  late final TextEditingController _weightController;
  late final TextEditingController _repsController;
  late final TextEditingController _recoveryTimeController;
  late final TextEditingController _notesController;
  
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(text: widget.series.peso.toString());
    _repsController = TextEditingController(text: widget.series.ripetizioni.toString());
    _recoveryTimeController = TextEditingController(
      text: widget.series.tempoRecupero?.toString() ?? '',
    );
    _notesController = TextEditingController(text: widget.series.note ?? '');
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    _recoveryTimeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 400.w,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: AppColors.indigo50.withValues(alpha: 0.3),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  topRight: Radius.circular(16.r),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.edit_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Modifica Serie',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Theme.of(context).textTheme.titleLarge?.color
                                : Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Serie ${widget.series.serieNumber ?? 1} - ${widget.series.esercizioNome ?? 'Esercizio'}',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Theme.of(context).textTheme.bodyMedium?.color
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    onPressed: () => context.pop(),
                    tooltip: 'Chiudi',
                  ),
                ],
              ),
            ),
            
            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Peso
                      _buildFormField(
                        controller: _weightController,
                        label: 'Peso (kg)',
                        icon: Icons.scale_rounded,
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Inserisci il peso';
                          }
                          final weight = double.tryParse(value);
                          if (weight == null || weight < 0) {
                            return 'Peso non valido';
                          }
                          if (weight > 1000) {
                            return 'Peso troppo elevato';
                          }
                          return null;
                        },
                      ),
                      
                      SizedBox(height: 16.h),
                      
                      // Ripetizioni
                      _buildFormField(
                        controller: _repsController,
                        label: 'Ripetizioni',
                        icon: Icons.repeat_rounded,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Inserisci le ripetizioni';
                          }
                          final reps = int.tryParse(value);
                          if (reps == null || reps <= 0) {
                            return 'Ripetizioni non valide';
                          }
                          if (reps > 1000) {
                            return 'Ripetizioni troppo elevate';
                          }
                          return null;
                        },
                      ),
                      
                      SizedBox(height: 16.h),
                      
                      // Tempo di recupero
                      _buildFormField(
                        controller: _recoveryTimeController,
                        label: 'Tempo di recupero (secondi)',
                        icon: Icons.timer_rounded,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final time = int.tryParse(value);
                            if (time == null || time < 0) {
                              return 'Tempo non valido';
                            }
                            if (time > 3600) {
                              return 'Tempo troppo elevato (max 1 ora)';
                            }
                          }
                          return null;
                        },
                      ),
                      
                      SizedBox(height: 16.h),
                      
                      // Note
                      _buildFormField(
                        controller: _notesController,
                        label: 'Note (opzionale)',
                        icon: Icons.note_rounded,
                        maxLines: 3,
                        maxLength: 200,
                        validator: (value) {
                          if (value != null && value.length > 200) {
                            return 'Note troppo lunghe (max 200 caratteri)';
                          }
                          return null;
                        },
                      ),
                      
                      SizedBox(height: 24.h),
                      
                      // Informazioni serie originale
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: AppColors.textHint.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: AppColors.border.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dati originali:',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'Peso: ${widget.series.peso} kg • '
                              'Ripetizioni: ${widget.series.ripetizioni} • '
                              'Recupero: ${widget.series.tempoRecupero ?? 0}s',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                            ),
                            if (widget.series.note != null && widget.series.note!.isNotEmpty) ...[
                              SizedBox(height: 2.h),
                              Text(
                                'Note: ${widget.series.note}',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: Theme.of(context).textTheme.bodyMedium?.color,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Azioni
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: AppColors.border.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Annulla'),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.indigo600,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 16.w,
                              height: 16.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Salva'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Theme.of(context).textTheme.titleMedium?.color
                                : Colors.grey[800],
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          maxLength: maxLength,
          validator: validator,
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              size: 20.sp,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(
                color: AppColors.error,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(
                color: AppColors.error,
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 12.h,
            ),
            counterText: '', // Nasconde il contatore caratteri
          ),
        ),
      ],
    );
  }

  void _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final weight = double.parse(_weightController.text);
      final reps = int.parse(_repsController.text);
      final recoveryTime = _recoveryTimeController.text.isNotEmpty
          ? int.parse(_recoveryTimeController.text)
          : null;
      final notes = _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim();

      // Verifica se ci sono effettivamente dei cambiamenti
      final hasChanges = weight != widget.series.peso ||
          reps != widget.series.ripetizioni ||
          recoveryTime != widget.series.tempoRecupero ||
          notes != widget.series.note;

      if (!hasChanges) {
        CustomSnackbar.show(
          context,
          message: 'Nessuna modifica rilevata',
          isSuccess: false,
        );
        Navigator.of(context).pop();
        return;
      }

      // Salva le modifiche
      widget.onSave(weight, reps, recoveryTime, notes);
      
      // Chiudi il dialog
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(
          context,
          message: 'Errore nel salvataggio: $e',
          isSuccess: false,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
