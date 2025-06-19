// lib/shared/widgets/create_exercise_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../../core/config/app_config.dart';
import '../../core/di/dependency_injection.dart';
import '../../core/network/api_client.dart';
import '../../core/services/session_service.dart';
import '../../features/exercises/models/exercise.dart';
import '../../features/subscription/bloc/subscription_bloc.dart';
import './custom_snackbar.dart';

class CreateExerciseDialog extends StatefulWidget {
  final VoidCallback? onSuccess;
  final VoidCallback? onDismiss;

  const CreateExerciseDialog({
    super.key,
    this.onSuccess,
    this.onDismiss,
  });

  @override
  State<CreateExerciseDialog> createState() => _CreateExerciseDialogState();
}

class _CreateExerciseDialogState extends State<CreateExerciseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _equipmentController = TextEditingController();

  String? _selectedMuscleGroup;
  bool _isIsometric = false;
  bool _isLoading = false;

  final List<String> _muscleGroups = [
    'Petto',
    'Schiena',
    'Spalle',
    'Bicipiti',
    'Tricipiti',
    'Quadricipiti',
    'Femorali',
    'Glutei',
    'Polpacci',
    'Addominali',
    'Avambracci',
    'Cardio',
    'Full Body',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _equipmentController.dispose();
    super.dispose();
  }

  void _createExercise() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedMuscleGroup == null) {
      CustomSnackbar.show(
        context,
        message: 'Seleziona un gruppo muscolare',
        isSuccess: false,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Ottieni l'ID utente corrente
      final sessionService = getIt<SessionService>();
      final userId = await sessionService.getCurrentUserId();

      if (userId == null) {
        throw Exception('Utente non autenticato');
      }

      // Crea la richiesta
      final request = CreateUserExerciseRequest(
        nome: _nameController.text.trim(),
        gruppoMuscolare: _selectedMuscleGroup!,
        descrizione: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        attrezzatura: _equipmentController.text.trim().isEmpty
            ? null
            : _equipmentController.text.trim(),
        isIsometric: _isIsometric,
        createdByUserId: userId,
        status: 'pending_review',
      );

      // Chiama l'API direttamente
      final apiClient = getIt<ApiClient>();
      final response = await apiClient.createCustomExercise(request.toJson());

      print('[CONSOLE] [create_exercise_dialog]Response: $response');

      if (response != null && response is Map<String, dynamic>) {
        final userExerciseResponse = UserExerciseResponse.fromJson(response);

        if (userExerciseResponse.success) {
          setState(() {
            _isLoading = false;
          });

          print('[CONSOLE] [create_exercise_dialog]✅ Exercise created successfully');

          CustomSnackbar.show(
            context,
            message: 'Esercizio creato con successo!',
            isSuccess: true,
          );

          // ✅ CHIUSURA SICURA DEL DIALOG con delay per evitare race conditions
          if (mounted) {
            Navigator.of(context).pop();
          }

          // ✅ CALLBACK ASINCRONA per evitare interferenze con il close
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              // Aggiorna i limiti della subscription
              context.read<SubscriptionBloc>().add(const CheckResourceLimitsEvent('max_custom_exercises'));

              // Callback di successo
              if (widget.onSuccess != null) {
                widget.onSuccess!();
              }
            }
          });
        } else {
          throw Exception(userExerciseResponse.message);
        }
      } else {
        throw Exception('Formato risposta non valido');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      print('[CONSOLE] [create_exercise_dialog]Error creating exercise: $e');

      CustomSnackbar.show(
        context,
        message: 'Errore nella creazione dell\'esercizio: ${e.toString()}',
        isSuccess: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(16.w),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppConfig.radiusL),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: _buildForm(context),
              ),
            ),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppConfig.radiusL),
          topRight: Radius.circular(AppConfig.radiusL),
        ),
        border: Border(
          bottom: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Crea Esercizio Personalizzato',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              // ✅ CHIUSURA SICURA CON CLEANUP
              if (widget.onDismiss != null) {
                widget.onDismiss!();
              }
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
            icon: Icon(
              Icons.close,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nome esercizio
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Nome Esercizio *',
              hintText: 'es. Panca piana manubri',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConfig.radiusM),
                borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Inserisci il nome dell\'esercizio';
              }
              if (value.trim().length < 3) {
                return 'Il nome deve essere almeno 3 caratteri';
              }
              return null;
            },
          ),
          SizedBox(height: 16.h),

          // Gruppo muscolare
          DropdownButtonFormField<String>(
            value: _selectedMuscleGroup,
            decoration: InputDecoration(
              labelText: 'Gruppo Muscolare *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConfig.radiusM),
                borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            ),
            items: _muscleGroups.map((group) => DropdownMenuItem<String>(
              value: group,
              child: Text(
                group,
                style: TextStyle(color: colorScheme.onSurface),
              ),
            )).toList(),
            onChanged: (value) {
              setState(() => _selectedMuscleGroup = value);
            },
            validator: (value) {
              if (value == null) {
                return 'Seleziona un gruppo muscolare';
              }
              return null;
            },
          ),
          SizedBox(height: 16.h),

          // Attrezzatura
          TextFormField(
            controller: _equipmentController,
            decoration: InputDecoration(
              labelText: 'Attrezzatura',
              hintText: 'es. Manubri, Bilanciere, Corpo libero...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConfig.radiusM),
                borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            ),
          ),
          SizedBox(height: 16.h),

          // Descrizione
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Descrizione',
              hintText: 'Aggiungi una descrizione dell\'esercizio...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConfig.radiusM),
                borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            ),
            maxLines: 3,
          ),
          SizedBox(height: 16.h),

          // Checkbox esercizio isometrico
          Row(
            children: [
              Checkbox(
                value: _isIsometric,
                onChanged: (value) {
                  setState(() => _isIsometric = value ?? false);
                },
                activeColor: isDark ? const Color(0xFF90CAF9) : AppColors.indigo600,
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _isIsometric = !_isIsometric);
                  },
                  child: Text(
                    'Esercizio isometrico (a tempo)',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 8.h),

          // Info sui campi obbligatori
          Text(
            '* Campi obbligatori',
            style: TextStyle(
              fontSize: 12.sp,
              color: colorScheme.onSurface.withOpacity(0.6),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppConfig.radiusL),
          bottomRight: Radius.circular(AppConfig.radiusL),
        ),
        border: Border(
          top: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isLoading ? null : () {
                // ✅ CHIUSURA SICURA CON CLEANUP
                if (widget.onDismiss != null) {
                  widget.onDismiss!();
                }
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.onSurface.withOpacity(0.6),
                side: BorderSide(color: colorScheme.outline),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConfig.radiusM),
                ),
                padding: EdgeInsets.symmetric(vertical: 12.h),
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
          SizedBox(width: 16.w),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _createExercise,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF90CAF9) : AppColors.indigo600,
                foregroundColor: isDark ? AppColors.backgroundDark : Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConfig.radiusM),
                ),
                padding: EdgeInsets.symmetric(vertical: 12.h),
              ),
              child: _isLoading
                  ? SizedBox(
                height: 20.h,
                width: 20.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isDark ? AppColors.backgroundDark : Colors.white,
                ),
              )
                  : Text(
                'Crea Esercizio',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}