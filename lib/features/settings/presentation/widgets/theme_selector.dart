import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/services/theme_service.dart';

/// Widget per la selezione del tema nelle impostazioni
class ThemeSelector extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;

  const ThemeSelector({
    super.key,
    required this.onThemeChanged,
  });

  @override
  State<ThemeSelector> createState() => _ThemeSelectorState();
}

class _ThemeSelectorState extends State<ThemeSelector> {
  ThemeMode _currentTheme = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadCurrentTheme();
  }

  Future<void> _loadCurrentTheme() async {
    final theme = await ThemeService.getThemeMode();
    setState(() {
      _currentTheme = theme;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tema',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 12.h),
        _buildThemeOption(
          ThemeMode.light,
          'Chiaro',
          Icons.light_mode,
          'Tema chiaro per ambienti luminosi',
        ),
        SizedBox(height: 8.h),
        _buildThemeOption(
          ThemeMode.dark,
          'Scuro',
          Icons.dark_mode,
          'Tema scuro per ambienti bui',
        ),
        SizedBox(height: 8.h),
        _buildThemeOption(
          ThemeMode.system,
          'Sistema',
          Icons.settings_system_daydream,
          'Segue le impostazioni del dispositivo',
        ),
      ],
    );
  }

  Widget _buildThemeOption(
    ThemeMode themeMode,
    String title,
    IconData icon,
    String description,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _currentTheme == themeMode;

    return InkWell(
      onTap: () => _selectTheme(themeMode),
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.1)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? colorScheme.primary : colorScheme.onSurface,
              size: 24.sp,
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: colorScheme.primary,
                size: 24.sp,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectTheme(ThemeMode themeMode) async {
    await ThemeService.setThemeMode(themeMode);
    setState(() {
      _currentTheme = themeMode;
    });
    widget.onThemeChanged(themeMode);
  }
} 