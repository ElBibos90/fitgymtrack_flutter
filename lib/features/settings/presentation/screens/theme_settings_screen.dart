import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/theme_service.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../shared/widgets/custom_button.dart';

class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  String _selectedTheme = 'indigo';
  ThemeMode _selectedMode = ThemeMode.system;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    try {
      final themeService = ThemeService.instance;
      final theme = await themeService.getSelectedTheme();
      final mode = await themeService.getThemeMode();
      
      setState(() {
        _selectedTheme = theme;
        _selectedMode = mode;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateTheme(String themeName) async {
    try {
      await ThemeService.instance.setSelectedTheme(themeName);
      setState(() {
        _selectedTheme = themeName;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tema aggiornato: ${_getThemeDisplayName(themeName)}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Errore nel salvataggio del tema'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _updateThemeMode(ThemeMode mode) async {
    try {
      await ThemeService.instance.setThemeMode(mode);
      setState(() {
        _selectedMode = mode;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Modalità tema aggiornata: ${_getModeDisplayName(mode)}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Errore nel salvataggio della modalità tema'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _getThemeDisplayName(String themeName) {
    final theme = AppColors.availableThemes.firstWhere(
      (t) => t['name'] == themeName,
      orElse: () => {'displayName': 'Sconosciuto'},
    );
    return theme['displayName'] as String;
  }

  String _getModeDisplayName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Chiaro';
      case ThemeMode.dark:
        return 'Scuro';
      case ThemeMode.system:
        return 'Sistema';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Impostazioni Tema',
        showBackButton: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              color: isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
              child: ListView(
                padding: EdgeInsets.all(16.w),
                children: [
                  // Sezione Modalità Tema
                  _buildSection(
                    context,
                    'Modalità Tema',
                    [
                      _buildModeOption(
                        context,
                        'Sistema',
                        'Segue le impostazioni del dispositivo',
                        Icons.settings_system_daydream,
                        ThemeMode.system,
                        isDarkMode,
                      ),
                      _buildModeOption(
                        context,
                        'Chiaro',
                        'Tema chiaro sempre attivo',
                        Icons.wb_sunny,
                        ThemeMode.light,
                        isDarkMode,
                      ),
                      _buildModeOption(
                        context,
                        'Scuro',
                        'Tema scuro sempre attivo',
                        Icons.nightlight_round,
                        ThemeMode.dark,
                        isDarkMode,
                      ),
                    ],
                    isDarkMode,
                  ),
                  
                  SizedBox(height: 24.h),
                  
                  // Sezione Colori Tema
                  _buildSection(
                    context,
                    'Colori Tema',
                    [
                      _buildThemeGrid(context, isDarkMode),
                    ],
                    isDarkMode,
                  ),
                  
                  SizedBox(height: 24.h),
                  
                  // Sezione Anteprima
                  _buildSection(
                    context,
                    'Anteprima',
                    [
                      _buildPreviewCard(context, isDarkMode),
                    ],
                    isDarkMode,
                  ),
                  
                  SizedBox(height: 32.h),
                  
                  // Pulsante Reset
                  CustomButton(
                    text: 'Ripristina Impostazioni Predefinite',
                    onPressed: _resetToDefaults,
                    type: ButtonType.secondary,
                    isFullWidth: true,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildModeOption(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    ThemeMode mode,
    bool isDarkMode,
  ) {
    final isSelected = _selectedMode == mode;
    
    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      color: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected 
              ? Theme.of(context).colorScheme.primary 
              : (isDarkMode ? Colors.white70 : AppColors.textSecondary),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDarkMode ? Colors.white : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
          ),
        ),
        trailing: isSelected
            ? Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              )
            : null,
        onTap: () => _updateThemeMode(mode),
      ),
    );
  }

  Widget _buildThemeGrid(BuildContext context, bool isDarkMode) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 1.2,
      ),
      itemCount: AppColors.availableThemes.length,
      itemBuilder: (context, index) {
        final theme = AppColors.availableThemes[index];
        final themeName = theme['name'] as String;
        final displayName = theme['displayName'] as String;
        final color = theme['color'] as Color;
        final isSelected = _selectedTheme == themeName;
        
        return GestureDetector(
          onTap: () => _updateTheme(themeName),
          child: Card(
            color: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
            elevation: isSelected ? 4 : 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: isSelected 
                  ? BorderSide(color: color, width: 2)
                  : BorderSide.none,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 20.sp,
                        )
                      : null,
                ),
                SizedBox(height: 8.h),
                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isDarkMode ? Colors.white : AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreviewCard(BuildContext context, bool isDarkMode) {
    final primaryColor = AppColors.getPrimaryColor(_selectedTheme);
    
    return Card(
      color: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Anteprima Tema',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    child: const Text('Pulsante Primario'),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    child: const Text('Pulsante Secondario'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Container(
              width: double.infinity,
              height: 60.h,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'Colore Primario: ${_getThemeDisplayName(_selectedTheme)}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resetToDefaults() async {
    try {
      await ThemeService.instance.resetThemePreferences();
      await _loadCurrentSettings();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impostazioni ripristinate ai valori predefiniti'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Errore nel ripristino delle impostazioni'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
} 