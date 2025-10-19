// lib/shared/widgets/exercise_substitution_dialog.dart
// 🔄 DIALOG SOSTITUZIONE ESERCIZIO
// Permette di sostituire un esercizio durante l'allenamento

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/workout_design_system.dart';
import '../../features/workouts/models/workout_plan_models.dart';
import '../../core/services/session_service.dart';
import '../../core/config/app_config.dart';

class ExerciseSubstitutionDialog extends StatefulWidget {
  final WorkoutExercise currentExercise;
  final Function(WorkoutExercise, int, int, double) onSubstitute;
  
  const ExerciseSubstitutionDialog({
    super.key,
    required this.currentExercise,
    required this.onSubstitute,
  });

  @override
  State<ExerciseSubstitutionDialog> createState() => _ExerciseSubstitutionDialogState();
}

class _ExerciseSubstitutionDialogState extends State<ExerciseSubstitutionDialog> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _seriesController = TextEditingController(text: '3');
  final TextEditingController _repsController = TextEditingController(text: '0');
  final TextEditingController _weightController = TextEditingController(text: '0');
  
  List<WorkoutExercise> _exercises = [];
  List<String> _selectedMuscleGroups = [];
  bool _loading = false;
  
  @override
  void initState() {
    super.initState();
    // Imposta i muscoli selezionati PRIMA di fare la ricerca
    if (widget.currentExercise.gruppoMuscolare != null) {
      _selectedMuscleGroups = widget.currentExercise.gruppoMuscolare!
          .split(',')
          .map((m) => m.trim())
          .toList();
    }
    // Ora fai la ricerca con i muscoli già impostati
    _searchExercises();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _seriesController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }
  
  Future<void> _searchExercises() async {
    if (_loading) return;
    
    setState(() {
      _loading = true;
    });
    
    try {
      // Recupera il token di autenticazione
      print('[SUBSTITUTION] 🔑 Recupero token...');
      final sessionService = SessionService();
      final token = await sessionService.getAuthToken();
      
      print('[SUBSTITUTION] 🔑 Token length: ${token?.length ?? 0}');
      
      if (token == null) {
        print('[SUBSTITUTION] ❌ Token non disponibile');
        setState(() {
          _loading = false;
        });
        return;
      }
      
      final queryParams = {
        'action': 'search',
        'current_exercise_id': widget.currentExercise.id.toString(),
        'query': _searchController.text,
        'muscles': _selectedMuscleGroups.join(','),
      };
      
      final uri = Uri.parse('${AppConfig.baseUrl}exercise_substitution_api.php')
          .replace(queryParameters: queryParams);
      
      print('[SUBSTITUTION] 📡 Richiesta a: $uri');
      print('[SUBSTITUTION] 🔍 Query: "${_searchController.text}", Muscles: ${_selectedMuscleGroups.join(", ")}');
      
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'X-Platform': 'mobile',
        },
      ).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          print('[SUBSTITUTION] ⏱️ Timeout dopo 10 secondi');
          throw Exception('Timeout');
        },
      );
      
      print('[SUBSTITUTION] 📥 Status Code: ${response.statusCode}');
      print('[SUBSTITUTION] 📥 Response body length: ${response.body.length}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        print('[SUBSTITUTION] 📦 Success: ${data['success']}, Exercises: ${data['exercises']?.length ?? 0}');
        
        if (data['success'] == true) {
          final exercisesList = (data['exercises'] as List);
          
          setState(() {
            _exercises = exercisesList
                .map((e) => WorkoutExercise.fromJson(e))
                .toList();
          });
          
          print('[SUBSTITUTION] ✅ Caricati ${_exercises.length} esercizi');
        } else {
          print('[SUBSTITUTION] ⚠️ API returned success: false');
          print('[SUBSTITUTION] ⚠️ Full response: ${response.body.substring(0, 200)}');
        }
      } else {
        print('[SUBSTITUTION] ❌ Errore HTTP: ${response.statusCode}');
        print('[SUBSTITUTION] ❌ Response body: ${response.body.substring(0, 200)}');
      }
    } catch (e, stackTrace) {
      print('[SUBSTITUTION] 💥 Errore ricerca esercizi: $e');
      print('[SUBSTITUTION] 💥 StackTrace: ${stackTrace.toString().substring(0, 200)}');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }
  
  void _toggleMuscleFilter(String muscle) {
    setState(() {
      if (_selectedMuscleGroups.contains(muscle)) {
        _selectedMuscleGroups.remove(muscle);
      } else {
        _selectedMuscleGroups.add(muscle);
      }
    });
    _searchExercises();
  }
  
  String? _getImageUrl(WorkoutExercise exercise) {
    // Se c'è immagine_url, usala
    if (exercise.immagineNome != null && exercise.immagineNome!.isNotEmpty) {
      return '${AppConfig.baseUrl}serve_image.php?filename=${exercise.immagineNome}';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: WorkoutDesignSystem.borderRadiusM,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: 600.w,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(colorScheme),
            
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(WorkoutDesignSystem.spacingM.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCurrentExercise(colorScheme),
                    SizedBox(height: WorkoutDesignSystem.spacingM.h),
                    _buildSearchField(colorScheme),
                    SizedBox(height: WorkoutDesignSystem.spacingM.h),
                    _buildMuscleFilters(colorScheme),
                    SizedBox(height: WorkoutDesignSystem.spacingM.h),
                    _buildParametersInput(colorScheme),
                    SizedBox(height: WorkoutDesignSystem.spacingM.h),
                    _buildExercisesList(colorScheme),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(WorkoutDesignSystem.spacingM.w),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.only(
          topLeft: WorkoutDesignSystem.borderRadiusM.topLeft,
          topRight: WorkoutDesignSystem.borderRadiusM.topRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.swap_horiz,
                color: WorkoutDesignSystem.primary600,
                size: 24.sp,
              ),
              SizedBox(width: WorkoutDesignSystem.spacingS.w),
              Text(
                'Sostituisci Esercizio',
                style: TextStyle(
                  fontSize: WorkoutDesignSystem.fontSizeH3.sp,
                  fontWeight: WorkoutDesignSystem.fontWeightBold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.close, color: colorScheme.onSurface),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentExercise(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(WorkoutDesignSystem.spacingM.w),
      decoration: BoxDecoration(
        color: WorkoutDesignSystem.primary600.withOpacity(0.1),
        borderRadius: WorkoutDesignSystem.borderRadiusS,
        border: Border.all(
          color: WorkoutDesignSystem.primary600.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60.w,
            height: 60.h,
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant,
              borderRadius: WorkoutDesignSystem.borderRadiusXS,
            ),
            child: Icon(
              Icons.fitness_center,
              color: WorkoutDesignSystem.primary600,
              size: 30.sp,
            ),
          ),
          SizedBox(width: WorkoutDesignSystem.spacingM.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.currentExercise.nome,
                  style: TextStyle(
                    fontSize: WorkoutDesignSystem.fontSizeBody.sp,
                    fontWeight: WorkoutDesignSystem.fontWeightBold,
                    color: colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: WorkoutDesignSystem.spacingXXS.h),
                Text(
                  widget.currentExercise.gruppoMuscolare ?? 'N/A',
                  style: TextStyle(
                    fontSize: WorkoutDesignSystem.fontSizeCaption.sp,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '${widget.currentExercise.serie} serie × ${widget.currentExercise.ripetizioni} reps @ ${widget.currentExercise.peso}kg',
                  style: TextStyle(
                    fontSize: WorkoutDesignSystem.fontSizeCaption.sp,
                    color: WorkoutDesignSystem.primary600,
                    fontWeight: WorkoutDesignSystem.fontWeightMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(ColorScheme colorScheme) {
    return TextField(
      controller: _searchController,
      onChanged: (_) => _searchExercises(),
      decoration: InputDecoration(
        labelText: 'Cerca esercizio...',
        hintText: 'Nome esercizio',
        prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear, color: colorScheme.onSurfaceVariant),
                onPressed: () {
                  _searchController.clear();
                  _searchExercises();
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: WorkoutDesignSystem.borderRadiusS,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: WorkoutDesignSystem.borderRadiusS,
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: WorkoutDesignSystem.borderRadiusS,
          borderSide: BorderSide(color: WorkoutDesignSystem.primary600, width: 2),
        ),
      ),
    );
  }

  Widget _buildMuscleFilters(ColorScheme colorScheme) {
    final allMuscles = [
      'Petto', 'Spalle', 'Tricipiti', 'Schiena', 
      'Bicipiti', 'Avambracci', 'Gambe', 'Glutei',
      'Addominali', 'Polpacci', 'Core',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filtra per muscoli:',
          style: TextStyle(
            fontSize: WorkoutDesignSystem.fontSizeBody.sp,
            fontWeight: WorkoutDesignSystem.fontWeightSemiBold,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: WorkoutDesignSystem.spacingS.h),
        Wrap(
          spacing: WorkoutDesignSystem.spacingXS.w,
          runSpacing: WorkoutDesignSystem.spacingXS.h,
          children: allMuscles.map((muscle) {
            final isSelected = _selectedMuscleGroups.contains(muscle);
            return FilterChip(
              label: Text(muscle),
              selected: isSelected,
              onSelected: (_) => _toggleMuscleFilter(muscle),
              selectedColor: WorkoutDesignSystem.primary600.withOpacity(0.2),
              checkmarkColor: WorkoutDesignSystem.primary600,
              labelStyle: TextStyle(
                color: isSelected
                    ? WorkoutDesignSystem.primary600
                    : colorScheme.onSurfaceVariant,
                fontSize: WorkoutDesignSystem.fontSizeCaption.sp,
                fontWeight: isSelected
                    ? WorkoutDesignSystem.fontWeightSemiBold
                    : WorkoutDesignSystem.fontWeightRegular,
              ),
              side: BorderSide(
                color: isSelected
                    ? WorkoutDesignSystem.primary600
                    : colorScheme.outline,
              ),
              backgroundColor: colorScheme.surface,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildParametersInput(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nuovi parametri:',
          style: TextStyle(
            fontSize: WorkoutDesignSystem.fontSizeBody.sp,
            fontWeight: WorkoutDesignSystem.fontWeightSemiBold,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: WorkoutDesignSystem.spacingS.h),
        Row(
          children: [
            Expanded(
              child: _buildNumberField(
                controller: _seriesController,
                label: 'Serie',
                colorScheme: colorScheme,
              ),
            ),
            SizedBox(width: WorkoutDesignSystem.spacingS.w),
            Expanded(
              child: _buildNumberField(
                controller: _repsController,
                label: 'Reps',
                colorScheme: colorScheme,
              ),
            ),
            SizedBox(width: WorkoutDesignSystem.spacingS.w),
            Expanded(
              child: _buildNumberField(
                controller: _weightController,
                label: 'Peso (kg)',
                colorScheme: colorScheme,
                isDecimal: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required ColorScheme colorScheme,
    bool isDecimal = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isDecimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.number,
      inputFormatters: isDecimal
          ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))]
          : [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: WorkoutDesignSystem.borderRadiusS,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: WorkoutDesignSystem.borderRadiusS,
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: WorkoutDesignSystem.borderRadiusS,
          borderSide: BorderSide(color: WorkoutDesignSystem.primary600, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: WorkoutDesignSystem.spacingS.w,
          vertical: WorkoutDesignSystem.spacingS.h,
        ),
      ),
      style: TextStyle(
        fontSize: WorkoutDesignSystem.fontSizeBody.sp,
        color: colorScheme.onSurface,
      ),
    );
  }

  Widget _buildExercisesList(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Esercizi disponibili (${_exercises.length})',
              style: TextStyle(
                fontSize: WorkoutDesignSystem.fontSizeBody.sp,
                fontWeight: WorkoutDesignSystem.fontWeightSemiBold,
                color: colorScheme.onSurface,
              ),
            ),
            if (_loading)
              SizedBox(
                width: 16.w,
                height: 16.h,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: WorkoutDesignSystem.primary600,
                ),
              ),
          ],
        ),
        SizedBox(height: WorkoutDesignSystem.spacingS.h),
        if (_exercises.isEmpty && !_loading)
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: WorkoutDesignSystem.spacingL.h),
              child: Text(
                'Nessun esercizio trovato',
                style: TextStyle(
                  fontSize: WorkoutDesignSystem.fontSizeBody.sp,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _exercises.length,
            itemBuilder: (context, index) {
              final exercise = _exercises[index];
              return _buildExerciseCard(exercise, colorScheme);
            },
          ),
      ],
    );
  }

  Widget _buildExerciseCard(WorkoutExercise exercise, ColorScheme colorScheme) {
    final imageUrl = _getImageUrl(exercise);
    
    return Card(
      margin: EdgeInsets.only(bottom: WorkoutDesignSystem.spacingS.h),
      color: colorScheme.surface,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: WorkoutDesignSystem.borderRadiusS,
        side: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: () => _confirmSubstitution(exercise),
        borderRadius: WorkoutDesignSystem.borderRadiusS,
        child: Padding(
          padding: EdgeInsets.all(WorkoutDesignSystem.spacingM.w),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: WorkoutDesignSystem.borderRadiusXS,
                child: imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: 50.w,
                        height: 50.h,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 50.w,
                          height: 50.h,
                          color: colorScheme.surfaceVariant,
                          child: Icon(Icons.fitness_center, color: colorScheme.onSurfaceVariant, size: 24.sp),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 50.w,
                          height: 50.h,
                          color: colorScheme.surfaceVariant,
                          child: Icon(Icons.fitness_center, color: colorScheme.onSurfaceVariant, size: 24.sp),
                        ),
                      )
                    : Container(
                        width: 50.w,
                        height: 50.h,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceVariant,
                          borderRadius: WorkoutDesignSystem.borderRadiusXS,
                        ),
                        child: Icon(Icons.fitness_center, color: colorScheme.onSurfaceVariant, size: 24.sp),
                      ),
              ),
              SizedBox(width: WorkoutDesignSystem.spacingM.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.nome,
                      style: TextStyle(
                        fontSize: WorkoutDesignSystem.fontSizeBody.sp,
                        fontWeight: WorkoutDesignSystem.fontWeightSemiBold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: WorkoutDesignSystem.spacingXXS.h),
                    Text(
                      exercise.gruppoMuscolare ?? 'N/A',
                      style: TextStyle(
                        fontSize: WorkoutDesignSystem.fontSizeCaption.sp,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16.sp,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmSubstitution(WorkoutExercise exercise) {
    final newSeries = int.tryParse(_seriesController.text) ?? 3;
    final newReps = int.tryParse(_repsController.text) ?? 0;
    final newWeight = double.tryParse(_weightController.text) ?? 0.0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conferma Sostituzione'),
        content: Text(
          'Sostituire "${widget.currentExercise.nome}" con "${exercise.nome}"?\n\n'
          'Parametri: $newSeries serie × $newReps reps @ ${newWeight}kg',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Chiudi conferma
              Navigator.of(context).pop(); // Chiudi dialog principale
              widget.onSubstitute(exercise, newSeries, newReps, newWeight);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: WorkoutDesignSystem.primary600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Conferma'),
          ),
        ],
      ),
    );
  }
}

