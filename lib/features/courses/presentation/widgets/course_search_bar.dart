import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../shared/theme/app_colors.dart';

/// 🔍 Barra di ricerca per i corsi
class CourseSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSearchChanged;
  final String? hintText;

  const CourseSearchBar({
    super.key,
    required this.controller,
    required this.onSearchChanged,
    this.hintText,
  });

  @override
  State<CourseSearchBar> createState() => _CourseSearchBarState();
}

class _CourseSearchBarState extends State<CourseSearchBar> {
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final query = widget.controller.text;
    final wasSearching = _isSearching;
    _isSearching = query.isNotEmpty;
    
    if (wasSearching != _isSearching) {
      setState(() {});
    }
    
    widget.onSearchChanged(query);
  }

  void _clearSearch() {
    widget.controller.clear();
    setState(() {
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: 48.h,
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: TextField(
        controller: widget.controller,
        style: TextStyle(
          fontSize: 14.sp,
          color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: widget.hintText ?? 'Cerca corsi...',
          hintStyle: TextStyle(
            fontSize: 14.sp,
            color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
          prefixIcon: Icon(
            Icons.search,
            size: 20.sp,
            color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
          suffixIcon: _isSearching
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    size: 20.sp,
                    color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  ),
                  onPressed: _clearSearch,
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 12.h,
          ),
        ),
      ),
    );
  }
}
