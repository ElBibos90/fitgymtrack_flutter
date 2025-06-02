// lib/shared/widgets/exercise_selection_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:developer' as developer;

import '../theme/app_colors.dart';
import '../../core/config/app_config.dart';
import '../../features/exercises/models/exercises_response.dart';

class ExerciseSelectionDialog extends StatefulWidget {
  final List<ExerciseItem> exercises;
  final List<int> selectedExerciseIds;
  final bool isLoading;
  final Function(ExerciseItem) onExerciseSelected;
  final VoidCallback onDismissRequest;

  const ExerciseSelectionDialog({
    super.key,
    required this.exercises,
    required this.selectedExerciseIds,
    required this.isLoading,
    required this.onExerciseSelected,
    required this.onDismissRequest,
  });

  @override
  State<ExerciseSelectionDialog> createState() => _ExerciseSelectionDialogState();
}

class _ExerciseSelectionDialogState extends State<ExerciseSelectionDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedMuscleGroup;

  List<ExerciseItem> get _filteredExercises {
    var filtered = widget.exercises;

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
    final groups = widget.exercises
        .where((exercise) => exercise.gruppoMuscolare != null)
        .map((exercise) => exercise.gruppoMuscolare!)
        .toSet()
        .toList();
    groups.sort();
    return groups;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(16.w),
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(AppConfig.radiusL),
        ),
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchAndFilters(),
            Expanded(child: _buildExercisesList()),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.indigo600,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppConfig.radiusL),
          topRight: Radius.circular(AppConfig.radiusL),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seleziona Esercizi',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${widget.exercises.length} esercizi disponibili',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: widget.onDismissRequest,
            icon: Icon(
              Icons.close,
              color: Colors.white,
              size: 24.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cerca esercizi...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                icon: const Icon(Icons.clear),
              )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConfig.radiusM),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConfig.radiusM),
                borderSide: BorderSide(color: AppColors.indigo600),
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
            decoration: InputDecoration(
              labelText: 'Filtra per gruppo muscolare',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConfig.radiusM),
              ),
            ),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Tutti i gruppi muscolari'),
              ),
              ..._availableMuscleGroups.map((group) => DropdownMenuItem<String>(
                value: group,
                child: Text(group),
              )),
            ],
            onChanged: (value) {
              setState(() => _selectedMuscleGroup = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExercisesList() {
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
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 16.h),
            Text(
              'Nessun esercizio trovato',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Prova a modificare i filtri di ricerca'
                  : 'Non ci sono esercizi disponibili',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
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

        return _buildExerciseItem(exercise, isSelected);
      },
    );
  }

  Widget _buildExerciseItem(ExerciseItem exercise, bool isSelected) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.indigo600.withOpacity(0.1)
            : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppConfig.radiusM),
        border: Border.all(
          color: isSelected
              ? AppColors.indigo600
              : AppColors.border,
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
            color: isSelected ? AppColors.indigo600 : AppColors.textPrimary,
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
                  color: AppColors.textSecondary,
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
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    exercise.attrezzatura!,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.textSecondary,
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
                  color: AppColors.textSecondary,
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
          color: AppColors.textSecondary,
          size: 24.sp,
        ),
        onTap: isSelected ? null : () {
          developer.log('Selected exercise: ${exercise.nome}', name: 'ExerciseSelectionDialog');
          widget.onExerciseSelected(exercise);
        },
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppConfig.radiusL),
          bottomRight: Radius.circular(AppConfig.radiusL),
        ),
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${_filteredExercises.length} esercizi trovati',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
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
}