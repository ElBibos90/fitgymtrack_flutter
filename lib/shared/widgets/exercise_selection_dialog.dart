// lib/shared/widgets/exercise_selection_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';


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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(16.w),
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: colorScheme.surface, // ✅ DINAMICO!
          borderRadius: BorderRadius.circular(AppConfig.radiusL),
        ),
        child: Column(
          children: [
            _buildHeader(context),
            _buildSearchAndFilters(context),
            Expanded(child: _buildExercisesList(context)),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF90CAF9) : AppColors.indigo600,
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
                    color: isDark ? AppColors.backgroundDark : Colors.white,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${widget.exercises.length} esercizi disponibili',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: isDark
                        ? AppColors.backgroundDark.withOpacity(0.8)
                        : Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: widget.onDismissRequest,
            icon: Icon(
              Icons.close,
              color: isDark ? AppColors.backgroundDark : Colors.white,
              size: 24.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            style: TextStyle(
              color: colorScheme.onSurface, // ✅ DINAMICO!
            ),
            decoration: InputDecoration(
              hintText: 'Cerca esercizi...',
              hintStyle: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.6), // ✅ DINAMICO!
              ),
              prefixIcon: Icon(
                Icons.search,
                color: colorScheme.onSurface.withOpacity(0.6), // ✅ DINAMICO!
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                icon: Icon(
                  Icons.clear,
                  color: colorScheme.onSurface.withOpacity(0.6), // ✅ DINAMICO!
                ),
              )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConfig.radiusM),
                borderSide: BorderSide(color: colorScheme.outline), // ✅ DINAMICO!
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConfig.radiusM),
                borderSide: BorderSide(color: isDark ? const Color(0xFF90CAF9) : AppColors.indigo600),
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
              color: colorScheme.onSurface, // ✅ DINAMICO!
            ),
            decoration: InputDecoration(
              labelText: 'Filtra per gruppo muscolare',
              labelStyle: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.6), // ✅ DINAMICO!
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
                  style: TextStyle(color: colorScheme.onSurface), // ✅ DINAMICO!
                ),
              ),
              ..._availableMuscleGroups.map((group) => DropdownMenuItem<String>(
                value: group,
                child: Text(
                  group,
                  style: TextStyle(color: colorScheme.onSurface), // ✅ DINAMICO!
                ),
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
              color: colorScheme.onSurface.withOpacity(0.4), // ✅ DINAMICO!
            ),
            SizedBox(height: 16.h),
            Text(
              'Nessun esercizio trovato',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface, // ✅ DINAMICO!
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Prova a modificare i filtri di ricerca'
                  : 'Non ci sono esercizi disponibili',
              style: TextStyle(
                fontSize: 14.sp,
                color: colorScheme.onSurface.withOpacity(0.6), // ✅ DINAMICO!
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

        return _buildExerciseItem(context, exercise, isSelected);
      },
    );
  }

  Widget _buildExerciseItem(BuildContext context, ExerciseItem exercise, bool isSelected) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark ? const Color(0xFF90CAF9).withOpacity(0.1) : AppColors.indigo600.withOpacity(0.1))
            : colorScheme.surface, // ✅ DINAMICO!
        borderRadius: BorderRadius.circular(AppConfig.radiusM),
        border: Border.all(
          color: isSelected
              ? (isDark ? const Color(0xFF90CAF9) : AppColors.indigo600)
              : colorScheme.outline.withOpacity(0.3), // ✅ DINAMICO!
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
                ? (isDark ? const Color(0xFF90CAF9) : AppColors.indigo600)
                : colorScheme.onSurface, // ✅ DINAMICO!
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
                  color: colorScheme.onSurface.withOpacity(0.6), // ✅ DINAMICO!
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
                    color: colorScheme.onSurface.withOpacity(0.6), // ✅ DINAMICO!
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    exercise.attrezzatura!,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: colorScheme.onSurface.withOpacity(0.6), // ✅ DINAMICO!
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
                  color: colorScheme.onSurface.withOpacity(0.6), // ✅ DINAMICO!
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
          color: isDark ? const Color(0xFF90CAF9) : AppColors.indigo600,
          size: 24.sp,
        )
            : Icon(
          Icons.add_circle_outline,
          color: colorScheme.onSurface.withOpacity(0.6), // ✅ DINAMICO!
          size: 24.sp,
        ),
        onTap: isSelected ? null : () {
          print('[CONSOLE] [exercise_selection_dialog]Selected exercise: ${exercise.nome}');
          widget.onExerciseSelected(exercise);
        },
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: colorScheme.surface, // ✅ DINAMICO!
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppConfig.radiusL),
          bottomRight: Radius.circular(AppConfig.radiusL),
        ),
        border: Border(
          top: BorderSide(color: colorScheme.outline.withOpacity(0.3)), // ✅ DINAMICO!
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${_filteredExercises.length} esercizi trovati',
              style: TextStyle(
                fontSize: 14.sp,
                color: colorScheme.onSurface.withOpacity(0.6), // ✅ DINAMICO!
              ),
            ),
          ),
          TextButton(
            onPressed: widget.onDismissRequest,
            child: Text(
              'Chiudi',
              style: TextStyle(
                fontSize: 16.sp,
                color: isDark ? const Color(0xFF90CAF9) : AppColors.indigo600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}