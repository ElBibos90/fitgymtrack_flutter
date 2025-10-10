// lib/shared/widgets/create_exercise_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../../core/config/app_config.dart';
import '../../core/di/dependency_injection.dart';
import '../../core/network/api_client.dart';
import '../../core/services/muscle_groups_service.dart';
import '../../features/exercises/models/exercises_response.dart';
import '../../features/exercises/models/muscle_group.dart';
import '../../features/exercises/models/secondary_muscle.dart';
import 'package:get_it/get_it.dart';
// RIMOSSA: import image_service e image_selection_dialog - non più necessari
// import '../../features/exercises/services/image_service.dart';
// import 'image_selection_dialog.dart';
import 'custom_text_field.dart';
import 'custom_snackbar.dart';

class CreateExerciseDialog extends StatefulWidget {
  final int currentUserId;
  final VoidCallback onDismiss;
  final Function(ExerciseItem) onExerciseCreated;

  const CreateExerciseDialog({
    super.key,
    required this.currentUserId,
    required this.onDismiss,
    required this.onExerciseCreated,
  });

  @override
  State<CreateExerciseDialog> createState() => _CreateExerciseDialogState();
}

class _CreateExerciseDialogState extends State<CreateExerciseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _equipmentController = TextEditingController();

  // ========== NUOVO SISTEMA MUSCOLI ==========
  final MuscleGroupsService _muscleService = GetIt.I<MuscleGroupsService>();
  List<MuscleGroup> _availableMuscles = [];
  bool _loadingMuscles = false;
  int? _selectedPrimaryMuscleId;
  List<SecondaryMuscle> _selectedSecondaryMuscles = [];
  // ===========================================
  
  bool _isIsometric = false;
  bool _isLoading = false;
  // RIMOSSA: gestione immagine - sarà gestita dall'admin
  // String? _selectedImageName;
  // bool _showImageSelectionDialog = false;

  // Lista delle attrezzature predefinite
  final List<String> _equipmentTypes = [
    'Corpo libero',
    'Bilanciere',
    'Manubri',
    'Cavi',
    'Macchine',
    'Kettlebell',
    'Fasce elastiche',
    'TRX',
    'Palla medica',
    'Parallele',
    'Sbarra',
    'Panca',
    'Altro',
  ];

  @override
  void initState() {
    super.initState();
    _loadMuscleGroups();
  }

  // ========== CARICA MUSCOLI DALL'API ==========
  Future<void> _loadMuscleGroups() async {
    setState(() => _loadingMuscles = true);
    try {
      final muscles = await _muscleService.getAllMuscleGroups();
      setState(() {
        _availableMuscles = muscles;
        _loadingMuscles = false;
      });
    } catch (e) {
      setState(() => _loadingMuscles = false);
      //print('[CONSOLE] Error loading muscle groups: $e');
    }
  }
  // ===========================================

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _equipmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(16.w),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppConfig.radiusL),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
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
                child: _buildForm(context),
              ),
            ),
            _buildFooter(context),
          ],
        ),
      ),
    ),

        // RIMOSSA: Dialog per selezione immagini - gestita dall'admin
      ],
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
          bottom: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.add_circle,
            color: colorScheme.primary,
            size: 24.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'Crea Nuovo Esercizio',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          IconButton(
            onPressed: widget.onDismiss,
            icon: Icon(
              Icons.close,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
              size: 24.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nome esercizio
            CustomTextField(
              controller: _nameController,
              label: 'Nome Esercizio *',
              hint: 'es. Panca piana con manubri',
              prefixIcon: Icons.fitness_center,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Il nome è obbligatorio';
                }
                if (value.trim().length < 3) {
                  return 'Il nome deve avere almeno 3 caratteri';
                }
                return null;
              },
            ),

            SizedBox(height: 16.h),

            // ========== NUOVO SISTEMA: MUSCOLO PRIMARIO ==========
            DropdownButtonFormField<int>(
              value: _selectedPrimaryMuscleId,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Muscolo Primario *',
                labelStyle: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConfig.radiusM),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConfig.radiusM),
                  borderSide: BorderSide(color: colorScheme.primary),
                ),
                suffixIcon: _loadingMuscles 
                  ? Padding(
                      padding: EdgeInsets.all(12.w),
                      child: SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
              ),
              items: [
                DropdownMenuItem<int>(
                  value: null,
                  child: Text(
                    'Seleziona muscolo primario',
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                ),
                ..._availableMuscles.map((muscle) => DropdownMenuItem<int>(
                  value: muscle.id,
                  child: Text(
                    '${muscle.name} (${muscle.parentCategory})',
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                )),
              ],
              onChanged: (value) {
                setState(() => _selectedPrimaryMuscleId = value);
              },
              validator: (value) {
                if (value == null) {
                  return 'Seleziona un muscolo primario';
                }
                return null;
              },
            ),
            // =====================================================

            SizedBox(height: 16.h),

            // Attrezzatura
            DropdownButtonFormField<String>(
              value: _equipmentController.text.isEmpty ? null : _equipmentController.text,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Attrezzatura',
                labelStyle: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConfig.radiusM),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConfig.radiusM),
                  borderSide: BorderSide(color: colorScheme.primary),
                ),
              ),
              items: _equipmentTypes.map((equipment) => DropdownMenuItem<String>(
                value: equipment,
                child: Text(
                  equipment,
                  style: TextStyle(color: colorScheme.onSurface),
                ),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  _equipmentController.text = value ?? '';
                });
              },
            ),

            SizedBox(height: 16.h),

            // ========== NUOVO SISTEMA: MUSCOLI SECONDARI ==========
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(AppConfig.radiusM),
              ),
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Muscoli Secondari (opzionale)',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Seleziona i muscoli che vengono attivati secondariamente durante l\'esercizio',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  _buildSecondaryMusclesSelector(),
                ],
              ),
            ),
            // =====================================================

            SizedBox(height: 16.h),

            // RIMOSSA: Selezione immagine - sarà gestita dall'admin
            // _buildImageSelectionSection(context),

            SizedBox(height: 16.h),

            // Checkbox isometrico
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(AppConfig.radiusM),
              ),
              child: CheckboxListTile(
                title: Text(
                  'Esercizio Isometrico',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  'Spunta se è un esercizio a tempo fisso (es. plank)',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                value: _isIsometric,
                onChanged: (value) {
                  setState(() => _isIsometric = value ?? false);
                },
                activeColor: colorScheme.primary,
              ),
            ),

            SizedBox(height: 16.h),

            // Descrizione
            CustomTextField(
              controller: _descriptionController,
              label: 'Descrizione',
              hint: 'Breve descrizione dell\'esercizio (opzionale)',
              prefixIcon: Icons.description,
              maxLines: 3,
              keyboardType: TextInputType.multiline,
            ),

            SizedBox(height: 8.h),

            // Note informative
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppConfig.radiusS),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: colorScheme.primary,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'I campi contrassegnati con * sono obbligatori. L\'esercizio creato sarà disponibile solo per te.',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
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

  // RIMOSSA: Sezione per selezione immagine - sarà gestita dall'admin
  // Widget _buildImageSelectionSection(BuildContext context) { ... }

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
          top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isLoading ? null : widget.onDismiss,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colorScheme.outline),
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConfig.radiusM),
                ),
              ),
              child: Text(
                'Annulla',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _createExercise,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF90CAF9) : AppColors.indigo600,
                foregroundColor: isDark ? Colors.black : Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConfig.radiusM),
                ),
              ),
              child: _isLoading
                  ? SizedBox(
                height: 20.h,
                width: 20.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? Colors.black : Colors.white,
                  ),
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

  Future<void> _createExercise() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ✅ Richiesta corretta basata sul PHP reale con NUOVO SISTEMA MUSCOLI
      final requestData = {
        'nome': _nameController.text.trim(),
        'gruppo_muscolare': _selectedPrimaryMuscleId != null 
            ? _availableMuscles.firstWhere((m) => m.id == _selectedPrimaryMuscleId).parentCategory
            : null, // ✅ Fallback per retrocompatibilità
        'primary_muscle_id': _selectedPrimaryMuscleId, // ✅ NUOVO: Muscolo primario
        'secondary_muscles': _selectedSecondaryMuscles.map((muscle) => {
          'muscle_id': muscle.id,
          'activation_level': muscle.activationLevel,
        }).toList(), // ✅ NUOVO: Muscoli secondari
        'created_by_user_id': widget.currentUserId, // ✅ FIX: Nome corretto del campo!
        'descrizione': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'attrezzatura': _equipmentController.text.trim().isEmpty
            ? null
            : _equipmentController.text.trim(),
        'is_isometric': _isIsometric, // ✅ FIX: Boolean, non int
        'status': 'pending_review', // ✅ Esercizio solo per l'utente
        // RIMOSSA: immagine sarà gestita dall'admin
        // 'immagine_nome': _selectedImageName,
      };

      // Rimuovi campi null
      requestData.removeWhere((key, value) => value == null);

      // Chiama l'API custom_exercise_standalone.php
      final apiClient = getIt<ApiClient>();
      final response = await apiClient.createCustomExercise(requestData);

      if (response != null && response is Map<String, dynamic>) {
        final success = response['success'] as bool? ?? false;

        if (success) {
          // Ottieni l'ID del nuovo esercizio
          final exerciseId = response['exercise_id'] as int? ??
              DateTime.now().millisecondsSinceEpoch;

          // Crea l'ExerciseItem dal risultato con NUOVO SISTEMA MUSCOLI
          final primaryMuscle = _selectedPrimaryMuscleId != null 
              ? _availableMuscles.firstWhere((m) => m.id == _selectedPrimaryMuscleId)
              : null;
              
          final newExercise = ExerciseItem(
            id: exerciseId,
            nome: _nameController.text.trim(),
            gruppoMuscolare: primaryMuscle?.parentCategory, // ✅ Fallback per retrocompatibilità
            // ========== NUOVI CAMPI SISTEMA MUSCOLI ==========
            primaryMuscleId: _selectedPrimaryMuscleId,
            primaryMuscle: primaryMuscle,
            secondaryMuscles: _selectedSecondaryMuscles,
            // ==================================================
            attrezzatura: _equipmentController.text.trim().isEmpty
                ? null
                : _equipmentController.text.trim(),
            descrizione: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            // RIMOSSA: immagine sarà gestita dall'admin
            immagineNome: null,
            isIsometric: _isIsometric,
            serieDefault: 3,
            ripetizioniDefault: _isIsometric ? 0 : 10,
            pesoDefault: _isIsometric ? 0.0 : 20.0,
            isCustom: true,
            createdBy: widget.currentUserId,
          );

          if (mounted) {
            CustomSnackbar.show(
              context,
              message: 'Esercizio "${newExercise.nome}" creato con successo!',
              isSuccess: true,
            );

            widget.onExerciseCreated(newExercise);
          }
        } else {
          final message = response['message'] as String? ?? 'Errore durante la creazione';
          throw Exception(message);
        }
      } else {
        throw Exception('Formato risposta non valido');
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Errore durante la creazione dell\'esercizio';

        // Gestisci errori specifici
        if (e.toString().contains('upgrade_required')) {
          errorMessage = 'Hai raggiunto il limite di esercizi personalizzati. Aggiorna il tuo piano per continuare.';
        } else if (e.toString().contains('403')) {
          errorMessage = 'Non hai i permessi per creare esercizi personalizzati.';
        } else if (e.toString().contains('400')) {
          errorMessage = 'Dati non validi. Verifica che tutti i campi obbligatori siano compilati.';
        }

        CustomSnackbar.show(
          context,
          message: errorMessage,
          isSuccess: false,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ========== SELEZIONATORE MUSCOLI SECONDARI ==========
  Widget _buildSecondaryMusclesSelector() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      children: [
        // Lista dei muscoli secondari selezionati
        if (_selectedSecondaryMuscles.isNotEmpty) ...[
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: _selectedSecondaryMuscles.map((muscle) {
              return Chip(
                label: Text('${muscle.name} (${muscle.activationLevel})'),
                onDeleted: () {
                  setState(() {
                    _selectedSecondaryMuscles.removeWhere((m) => m.id == muscle.id);
                  });
                },
                backgroundColor: colorScheme.primaryContainer,
                labelStyle: TextStyle(color: colorScheme.onPrimaryContainer),
                deleteIconColor: colorScheme.onPrimaryContainer,
              );
            }).toList(),
          ),
          SizedBox(height: 12.h),
        ],
        
        // Bottone per aggiungere muscoli secondari
        OutlinedButton.icon(
          onPressed: _showSecondaryMuscleSelector,
          icon: Icon(Icons.add, size: 18.w),
          label: Text('Aggiungi Muscolo Secondario'),
          style: OutlinedButton.styleFrom(
            foregroundColor: colorScheme.primary,
            side: BorderSide(color: colorScheme.primary),
          ),
        ),
      ],
    );
  }

  void _showSecondaryMuscleSelector() {
    final colorScheme = Theme.of(context).colorScheme;
    
    // ✅ LOGICA MIGLIORATA: Prima categoria del primario, poi tutti gli altri
    List<MuscleGroup> availableMuscles = _availableMuscles.where((muscle) => 
      muscle.id != _selectedPrimaryMuscleId && 
      !_selectedSecondaryMuscles.any((selected) => selected.id == muscle.id)
    ).toList();
    
    // Se c'è un muscolo primario selezionato, raggruppa per categoria
    if (_selectedPrimaryMuscleId != null) {
      final primaryMuscle = _availableMuscles.firstWhere((m) => m.id == _selectedPrimaryMuscleId);
      final primaryCategory = primaryMuscle.parentCategory;
      
      // Ordina: prima quelli della stessa categoria, poi gli altri
      availableMuscles.sort((a, b) {
        final aIsSameCategory = a.parentCategory == primaryCategory;
        final bIsSameCategory = b.parentCategory == primaryCategory;
        
        if (aIsSameCategory && !bIsSameCategory) return -1; // a prima
        if (!aIsSameCategory && bIsSameCategory) return 1;  // b prima
        return a.name.compareTo(b.name); // stesso livello, ordina per nome
      });
    } else {
      // Nessun primario selezionato, ordina per nome
      availableMuscles.sort((a, b) => a.name.compareTo(b.name));
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Seleziona Muscolo Secondario'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400.h,
          child: ListView.builder(
            itemCount: availableMuscles.length,
            itemBuilder: (context, index) {
              final muscle = availableMuscles[index];
              final isSameCategory = _selectedPrimaryMuscleId != null && 
                  muscle.parentCategory == _availableMuscles
                      .firstWhere((m) => m.id == _selectedPrimaryMuscleId)
                      .parentCategory;
              
              return Column(
                children: [
                  // Separatore per categoria (solo se è diversa dalla precedente)
                  if (index > 0 && 
                      availableMuscles[index - 1].parentCategory != muscle.parentCategory)
                    Divider(height: 1.h),
                  
                  ListTile(
                    leading: isSameCategory 
                        ? Icon(Icons.priority_high, color: colorScheme.primary, size: 16.w)
                        : null,
                    title: Text(
                      muscle.name,
                      style: TextStyle(
                        fontWeight: isSameCategory ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      '${muscle.parentCategory}${isSameCategory ? ' • Stessa categoria del primario' : ''}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: isSameCategory 
                            ? colorScheme.primary 
                            : colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showActivationLevelDialog(muscle);
                    },
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annulla'),
          ),
        ],
      ),
    );
  }

  void _showActivationLevelDialog(MuscleGroup muscle) {
    final colorScheme = Theme.of(context).colorScheme;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Livello di Attivazione'),
        content: Text('Seleziona il livello di attivazione per ${muscle.name}:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annulla'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedSecondaryMuscles.add(SecondaryMuscle(
                  id: muscle.id,
                  name: muscle.name,
                  activationLevel: 'low',
                  parentCategory: muscle.parentCategory,
                ));
              });
            },
            child: Text('Bassa'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedSecondaryMuscles.add(SecondaryMuscle(
                  id: muscle.id,
                  name: muscle.name,
                  activationLevel: 'medium',
                  parentCategory: muscle.parentCategory,
                ));
              });
            },
            child: Text('Media'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedSecondaryMuscles.add(SecondaryMuscle(
                  id: muscle.id,
                  name: muscle.name,
                  activationLevel: 'high',
                  parentCategory: muscle.parentCategory,
                ));
              });
            },
            child: Text('Alta'),
          ),
        ],
      ),
    );
  }
  // =====================================================
}