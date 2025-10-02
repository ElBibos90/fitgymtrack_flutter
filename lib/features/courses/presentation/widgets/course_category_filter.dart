import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../shared/theme/app_colors.dart';

/// 🏷️ Filtro per categorie di corsi
class CourseCategoryFilter extends StatelessWidget {
  final String? selectedCategory;
  final ValueChanged<String?> onCategoryChanged;

  const CourseCategoryFilter({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  // Categorie predefinite
  static const List<String> _categories = [
    'Tutte',
    'Yoga',
    'Pilates',
    'CrossFit',
    'Cardio',
    'Muscolazione',
    'Danza',
    'Arti Marziali',
    'Nuoto',
    'Spinning',
  ];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return SizedBox(
      height: 40.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = selectedCategory == category || 
              (selectedCategory == null && category == 'Tutte');
          
          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: _buildCategoryChip(
              category: category,
              isSelected: isSelected,
              isDarkMode: isDarkMode,
              onTap: () {
                if (category == 'Tutte') {
                  onCategoryChanged(null);
                } else {
                  onCategoryChanged(category);
                }
              },
            ),
          );
        },
      ),
    );
  }

  /// Chip categoria
  Widget _buildCategoryChip({
    required String category,
    required bool isSelected,
    required bool isDarkMode,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : (isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1,
          ),
        ),
        child: Text(
          category,
          style: TextStyle(
            fontSize: 12.sp,
            color: isSelected ? Colors.white : (isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
