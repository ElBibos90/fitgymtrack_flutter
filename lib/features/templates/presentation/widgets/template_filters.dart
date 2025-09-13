// lib/features/templates/presentation/widgets/template_filters.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../bloc/template_bloc.dart';
import '../../models/template_models.dart';

class TemplateFilters extends StatefulWidget {
  final int? selectedCategoryId;
  final String? selectedDifficulty;
  final String? selectedGoal;
  final bool? featuredOnly;
  final Function({
    int? categoryId,
    String? difficulty,
    String? goal,
    bool? featured,
    String? search,
  }) onApplyFilters;
  final VoidCallback onClearFilters;

  const TemplateFilters({
    super.key,
    this.selectedCategoryId,
    this.selectedDifficulty,
    this.selectedGoal,
    this.featuredOnly,
    required this.onApplyFilters,
    required this.onClearFilters,
  });

  @override
  State<TemplateFilters> createState() => _TemplateFiltersState();
}

class _TemplateFiltersState extends State<TemplateFilters> {
  int? _selectedCategoryId;
  String? _selectedDifficulty;
  String? _selectedGoal;
  bool? _featuredOnly;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.selectedCategoryId;
    _selectedDifficulty = widget.selectedDifficulty;
    _selectedGoal = widget.selectedGoal;
    _featuredOnly = widget.featuredOnly;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: EdgeInsets.only(top: 12.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Row(
              children: [
                Text(
                  'Filtri Template',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _clearFilters,
                  child: Text(
                    'Cancella tutto',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Contenuto filtri
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Categoria
                  _buildSectionTitle('Categoria'),
                  SizedBox(height: 12.h),
                  BlocBuilder<TemplateBloc, TemplateState>(
                    builder: (context, state) {
                      if (state is CategoriesLoaded) {
                        return _buildCategoryFilter(state.categories);
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  SizedBox(height: 24.h),

                  // Difficoltà
                  _buildSectionTitle('Livello di Difficoltà'),
                  SizedBox(height: 12.h),
                  _buildDifficultyFilter(),

                  SizedBox(height: 24.h),

                  // Obiettivo
                  _buildSectionTitle('Obiettivo'),
                  SizedBox(height: 12.h),
                  _buildGoalFilter(),

                  SizedBox(height: 24.h),

                  // In evidenza
                  _buildSectionTitle('Filtri Speciali'),
                  SizedBox(height: 12.h),
                  _buildFeaturedFilter(),

                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),

          // Pulsanti azione
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.cardBackgroundDark : AppColors.cardBackgroundLight,
              border: Border(
                top: BorderSide(
                  color: AppColors.borderColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _clearFilters,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      side: BorderSide(color: AppColors.borderColor),
                    ),
                    child: Text(
                      'Cancella',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    child: Text(
                      'Applica Filtri',
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
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildCategoryFilter(List<TemplateCategory> categories) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: categories.map((category) {
        final isSelected = _selectedCategoryId == category.id;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedCategoryId = isSelected ? null : category.id;
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: isSelected 
                  ? AppColors.primary 
                  : AppColors.cardBackgroundLight,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: isSelected 
                    ? AppColors.primary 
                    : AppColors.borderColor,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getCategoryIcon(category.icon),
                  size: 16.sp,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
                SizedBox(width: 6.w),
                Text(
                  category.name,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                SizedBox(width: 4.w),
                Text(
                  '(${category.templateCount})',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: isSelected 
                        ? Colors.white.withOpacity(0.8)
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDifficultyFilter() {
    final difficulties = [
      {'value': 'beginner', 'label': 'Principiante', 'color': AppColors.success},
      {'value': 'intermediate', 'label': 'Intermedio', 'color': AppColors.warning},
      {'value': 'advanced', 'label': 'Avanzato', 'color': AppColors.error},
    ];

    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: difficulties.map((difficulty) {
        final isSelected = _selectedDifficulty == difficulty['value'];
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDifficulty = isSelected ? null : difficulty['value'] as String;
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: isSelected 
                  ? difficulty['color'] as Color
                  : AppColors.cardBackgroundLight,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: isSelected 
                    ? difficulty['color'] as Color
                    : AppColors.borderColor,
                width: 1,
              ),
            ),
            child: Text(
              difficulty['label'] as String,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGoalFilter() {
    final goals = [
      {'value': 'strength', 'label': 'Forza', 'color': AppColors.error},
      {'value': 'hypertrophy', 'label': 'Ipertrofia', 'color': AppColors.primary},
      {'value': 'endurance', 'label': 'Resistenza', 'color': AppColors.info},
      {'value': 'weight_loss', 'label': 'Dimagrimento', 'color': AppColors.success},
      {'value': 'general', 'label': 'Generale', 'color': AppColors.textSecondary},
    ];

    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: goals.map((goal) {
        final isSelected = _selectedGoal == goal['value'];
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedGoal = isSelected ? null : goal['value'] as String;
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: isSelected 
                  ? goal['color'] as Color
                  : AppColors.cardBackgroundLight,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: isSelected 
                    ? goal['color'] as Color
                    : AppColors.borderColor,
                width: 1,
              ),
            ),
            child: Text(
              goal['label'] as String,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFeaturedFilter() {
    return Row(
      children: [
        Checkbox(
          value: _featuredOnly ?? false,
          onChanged: (value) {
            setState(() {
              _featuredOnly = value;
            });
          },
          activeColor: AppColors.primary,
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            'Solo template in evidenza',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String iconName) {
    switch (iconName) {
      case 'fitness_center':
        return Icons.fitness_center;
      case 'accessibility':
        return Icons.accessibility;
      case 'sports_gymnastics':
        return Icons.sports_gymnastics;
      case 'sports_mma':
        return Icons.sports_mma;
      case 'self_improvement':
        return Icons.self_improvement;
      case 'accessibility_new':
        return Icons.accessibility_new;
      case 'apps':
        return Icons.apps;
      default:
        return Icons.fitness_center;
    }
  }

  void _applyFilters() {
    widget.onApplyFilters(
      categoryId: _selectedCategoryId,
      difficulty: _selectedDifficulty,
      goal: _selectedGoal,
      featured: _featuredOnly,
    );
    Navigator.of(context).pop();
  }

  void _clearFilters() {
    setState(() {
      _selectedCategoryId = null;
      _selectedDifficulty = null;
      _selectedGoal = null;
      _featuredOnly = null;
    });
    widget.onClearFilters();
    Navigator.of(context).pop();
  }
}
