// lib/features/templates/presentation/widgets/create_workout_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/custom_snackbar.dart';
import '../../../../core/services/session_service.dart';
import '../../bloc/template_bloc.dart';
import '../../models/template_models.dart';
import '../../../workouts/bloc/workout_bloc.dart';

class CreateWorkoutDialog extends StatefulWidget {
  final WorkoutTemplate template;
  final Function(CreateWorkoutFromTemplateResponse) onWorkoutCreated;

  const CreateWorkoutDialog({
    super.key,
    required this.template,
    required this.onWorkoutCreated,
  });

  @override
  State<CreateWorkoutDialog> createState() => _CreateWorkoutDialogState();
}

class _CreateWorkoutDialogState extends State<CreateWorkoutDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final SessionService _sessionService = SessionService();
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    // Pre-compila il nome con il nome del template
    _nameController.text = widget.template.name;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<TemplateBloc, TemplateState>(
      listener: (context, state) async {
        if (state is WorkoutCreatedFromTemplate) {
          // ✅ Refresh automatico delle schede dopo creazione da template
          final userId = await _sessionService.getCurrentUserId();
          if (userId != null) {
            context.read<WorkoutBloc>().add(RefreshWorkoutPlansAfterOperation(
              userId: userId,
              operation: 'create_from_template',
            ));
          }
          
          widget.onWorkoutCreated(state.response);
          Navigator.of(context).pop();
        } else if (state is TemplateError) {
          CustomSnackbar.show(
            context,
            message: state.message,
            isSuccess: false,
          );
          setState(() {
            _isCreating = false;
          });
        }
      },
      child: Dialog(
        backgroundColor: isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Container(
          width: double.maxFinite,
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.fitness_center,
                    size: 24.sp,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'Crea Scheda da Template',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      size: 24.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 16.h),
              
              // Template info
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Template selezionato:',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white70 : AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      widget.template.name,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${widget.template.exercises?.length ?? 0} esercizi • ${widget.template.estimatedDurationFormatted} • ${widget.template.difficultyLevelFormatted}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: isDarkMode ? Colors.white60 : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 24.h),
              
              // Form
              Text(
                'Personalizza la tua scheda',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : AppColors.textPrimary,
                ),
              ),
              
              SizedBox(height: 16.h),
              
              // Nome scheda
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nome scheda *',
                  labelStyle: TextStyle(
                    color: isDarkMode ? Colors.white70 : AppColors.textPrimary,
                  ),
                  hintText: 'Inserisci il nome della scheda',
                  hintStyle: TextStyle(
                    color: isDarkMode ? Colors.white60 : AppColors.textSecondary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide(color: AppColors.borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide(color: AppColors.borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                  filled: true,
                  fillColor: isDarkMode ? AppColors.surfaceDark : Colors.white,
                  prefixIcon: Icon(
                    Icons.edit,
                    color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
                style: TextStyle(
                  fontSize: 14.sp,
                  color: isDarkMode ? Colors.white : AppColors.textPrimary,
                ),
              ),
              
              SizedBox(height: 16.h),
              
              // Descrizione scheda
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Descrizione (opzionale)',
                  labelStyle: TextStyle(
                    color: isDarkMode ? Colors.white70 : AppColors.textPrimary,
                  ),
                  hintText: 'Aggiungi una descrizione alla tua scheda',
                  hintStyle: TextStyle(
                    color: isDarkMode ? Colors.white60 : AppColors.textSecondary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide(color: AppColors.borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide(color: AppColors.borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                  filled: true,
                  fillColor: isDarkMode ? AppColors.surfaceDark : Colors.white,
                  prefixIcon: Icon(
                    Icons.description,
                    color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
                style: TextStyle(
                  fontSize: 14.sp,
                  color: isDarkMode ? Colors.white : AppColors.textPrimary,
                ),
              ),
              
              SizedBox(height: 24.h),
              
              // Pulsanti
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isCreating ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        side: BorderSide(color: AppColors.borderColor),
                      ),
                      child: Text(
                        'Annulla',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isCreating || _nameController.text.trim().isEmpty
                          ? null
                          : _createWorkout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      child: _isCreating
                          ? SizedBox(
                              height: 20.h,
                              width: 20.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Crea Scheda',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _createWorkout() async {
    if (_nameController.text.trim().isEmpty) return;

    // Verifica se l'utente è autenticato
    final isAuthenticated = await _sessionService.isAuthenticated();
    if (!isAuthenticated) {
      CustomSnackbar.show(
        context,
        message: 'Devi essere loggato per creare una scheda',
        isSuccess: false,
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    final request = CreateWorkoutFromTemplateRequest(
      templateId: widget.template.id,
      workoutName: _nameController.text.trim(),
      workoutDescription: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
    );

    context.read<TemplateBloc>().add(CreateWorkoutFromTemplate(request));
  }
}
