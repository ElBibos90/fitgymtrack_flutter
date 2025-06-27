// lib/shared/widgets/exercise_selection_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../../core/config/app_config.dart';
import '../../features/exercises/models/exercises_response.dart';
import 'create_exercise_dialog.dart';
import 'exercise_editor.dart';

class ExerciseSelectionDialog extends StatefulWidget {
  final List<ExerciseItem> exercises;
  final List<int> selectedExerciseIds;
  final bool isLoading;
  final Function(ExerciseItem) onExerciseSelected;
  final VoidCallback onDismissRequest;

  // ✨ NUOVI PARAMETRI per la creazione di esercizi
  final int? currentUserId;
  final VoidCallback? onExercisesRefresh;

  const ExerciseSelectionDialog({
    super.key,
    required this.exercises,
    required this.selectedExerciseIds,
    required this.isLoading,
    required this.onExerciseSelected,
    required this.onDismissRequest,
    this.currentUserId,
    this.onExercisesRefresh,
  });

  @override
  State<ExerciseSelectionDialog> createState() => _ExerciseSelectionDialogState();
}

class _ExerciseSelectionDialogState extends State<ExerciseSelectionDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedMuscleGroup;

  // ✨ NUOVO STATO per il dialog di creazione
  bool _showCreateExerciseDialog = false;
  bool _showEditor = false;

  List<ExerciseItem> _exercises = [];

  @override
  void initState() {
    super.initState();
    _exercises = List.from(widget.exercises);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_showEditor) {
      return ExerciseEditor(
        isFirst: false,
        onSave: _addNewExercise,
        onCancel: () => setState(() => _showEditor = false),
      );
    }

    return Stack(
      children: [
        // ✨ DIALOG PRINCIPALE
        Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(16.w),
          child: Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.8,
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
              children: [
                _buildHeader(context),
                Expanded(child: _buildContent(context)),
                _buildFooter(context),
              ],
            ),
          ),
        ),

        // ✨ DIALOG PER CREARE NUOVO ESERCIZIO
        if (_showCreateExerciseDialog && widget.currentUserId != null)
          CreateExerciseDialog(
            currentUserId: widget.currentUserId!,
            onDismiss: () {
              setState(() {
                _showCreateExerciseDialog = false;
              });
            },
            onExerciseCreated: (newExercise) {
              setState(() {
                _showCreateExerciseDialog = false;
              });

              // Aggiorna la lista e seleziona il nuovo esercizio
              if (widget.onExercisesRefresh != null) {
                widget.onExercisesRefresh!();
              }

              // Seleziona automaticamente il nuovo esercizio
              widget.onExerciseSelected(newExercise);
            },
          ),
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
          Expanded(
            child: Text(
              'Seleziona Esercizi',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),

          // ✨ BOTTONE PER CREARE NUOVO ESERCIZIO
          if (widget.currentUserId != null) ...[
            IconButton(
              onPressed: () {
                setState(() {
                  _showCreateExerciseDialog = true;
                });
              },
              icon: Icon(
                Icons.add_circle,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                size: 28.sp,
              ),
              tooltip: 'Crea nuovo esercizio',
            ),
            SizedBox(width: 8.w),
          ],

          IconButton(
            onPressed: widget.onDismissRequest,
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

  Widget _buildContent(BuildContext context) {
    return Column(
      children: [
        _buildFilters(context),
        SizedBox(height: 16.h),
        Expanded(child: _buildExercisesList(context)),
      ],
    );
  }

  Widget _buildFilters(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          // Search field
          TextField(
            controller: _searchController,
            style: TextStyle(
              color: colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: 'Cerca esercizi...',
              hintStyle: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              prefixIcon: Icon(
                Icons.search,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                icon: Icon(
                  Icons.clear,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConfig.radiusM),
                borderSide: BorderSide(color: colorScheme.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConfig.radiusM),
                borderSide: BorderSide(color: colorScheme.outline),
              ),
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
          ),

          SizedBox(height: 12.h),

          // Muscle group filter
          DropdownButtonFormField<String>(
            value: _selectedMuscleGroup,
            style: TextStyle(
              color: colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              labelText: 'Filtra per gruppo muscolare',
              labelStyle: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConfig.radiusM),
              ),
            ),
            items: [
              DropdownMenuItem<String>(
                value: null,
                child: Text(
                  'Tutti i gruppi muscolari',
                  style: TextStyle(color: colorScheme.onSurface),
                ),
              ),
              ..._availableMuscleGroups.map((group) => DropdownMenuItem<String>(
                value: group,
                child: Text(
                  group,
                  style: TextStyle(color: colorScheme.onSurface),
                ),
              )),
            ],
            onChanged: (value) {
              setState(() => _selectedMuscleGroup = value);
            },
          ),

          // ✨ BOTTONE ALTERNATIVO PER SCHERMI PICCOLI
          if (widget.currentUserId != null) ...[
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _showCreateExerciseDialog = true;
                  });
                },
                icon: Icon(
                  Icons.add,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                label: Text(
                  'Crea nuovo esercizio',
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExercisesList(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (widget.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final filteredExercises = _filteredExercises;

    if (filteredExercises.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64.sp,
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            SizedBox(height: 16.h),
            Text(
              'Nessun esercizio trovato',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Prova a modificare i filtri di ricerca'
                  : 'Non ci sono esercizi disponibili',
              style: TextStyle(
                fontSize: 14.sp,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),

            // ✨ SUGGERIMENTO PER CREARE NUOVO ESERCIZIO
            if (widget.currentUserId != null && _searchQuery.isNotEmpty) ...[
              SizedBox(height: 16.h),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _showCreateExerciseDialog = true;
                  });
                },
                icon: const Icon(Icons.add),
                label: Text('Crea "$_searchQuery"'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: filteredExercises.length,
      itemBuilder: (context, index) {
        final exercise = filteredExercises[index];
        final isSelected = widget.selectedExerciseIds.contains(exercise.id);

        return _buildExerciseItem(context, exercise, isSelected);
      },
    );
  }

  Widget _buildExerciseItem(BuildContext context, ExerciseItem exercise, bool isSelected) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.indigo600.withValues(alpha: 0.1)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConfig.radiusM),
        border: Border.all(
          color: isSelected
              ? AppColors.indigo600
              : colorScheme.outline.withValues(alpha: 0.3),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        title: Text(
          exercise.nome,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? AppColors.indigo600
                : colorScheme.onSurface,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (exercise.gruppoMuscolare != null) ...[
              SizedBox(height: 4.h),
              Text(
                exercise.gruppoMuscolare!,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            if (exercise.attrezzatura != null) ...[
              SizedBox(height: 2.h),
              Row(
                children: [
                  Icon(
                    Icons.fitness_center,
                    size: 12.sp,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    exercise.attrezzatura!,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
            if (exercise.descrizione != null && exercise.descrizione!.isNotEmpty) ...[
              SizedBox(height: 4.h),
              Text(
                exercise.descrizione!,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: isSelected
            ? Icon(
          Icons.check_circle,
          color: AppColors.indigo600,
          size: 24.sp,
        )
            : Icon(
          Icons.add_circle_outline,
          color: colorScheme.onSurface.withValues(alpha: 0.6),
          size: 24.sp,
        ),
        onTap: isSelected ? null : () {
          _onExerciseSelected(exercise);
        },
      ),
    );
  }

  void _onExerciseSelected(ExerciseItem exercise) {
    widget.onExerciseSelected(exercise);
    Navigator.of(context).pop();
  }

  Widget _buildFooter(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
            child: Text(
              '${_filteredExercises.length} esercizi trovati',
              style: TextStyle(
                fontSize: 14.sp,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          TextButton(
            onPressed: widget.onDismissRequest,
            child: Text(
              'Chiudi',
              style: TextStyle(
                fontSize: 16.sp,
                color: AppColors.indigo600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<ExerciseItem> get _filteredExercises {
    var filtered = _exercises;

    // Filtro per nome (ricerca)
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((exercise) =>
          exercise.nome.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    // Filtro per gruppo muscolare
    if (_selectedMuscleGroup != null && _selectedMuscleGroup!.isNotEmpty) {
      filtered = filtered.where((exercise) =>
      exercise.gruppoMuscolare?.toLowerCase() == _selectedMuscleGroup!.toLowerCase()).toList();
    }

    return filtered;
  }

  List<String> get _availableMuscleGroups {
    final groups = _exercises
        .where((exercise) => exercise.gruppoMuscolare != null)
        .map((exercise) => exercise.gruppoMuscolare!)
        .toSet()
        .toList();
    groups.sort();
    return groups;
  }

  void _addNewExercise(Map<String, dynamic> data) {
    final newItem = ExerciseItem(
      id: data['id'] ?? 0,
      nome: data['nome'] ?? '',
      gruppoMuscolare: data['gruppoMuscolare'],
      attrezzatura: data['attrezzatura'],
      descrizione: data['descrizione'],
      isCustom: true,
      serieDefault: data['serie'] ?? 3,
      ripetizioniDefault: data['ripetizioni'] ?? 10,
      pesoDefault: data['peso'] ?? 20.0,
      isIsometric: data['isIsometric'] ?? false,
    );
    setState(() {
      _exercises.add(newItem);
      _showEditor = false;
    });
    widget.onExerciseSelected(newItem);
  }
}