// lib/features/settings/presentation/widgets/audio_settings_widget.dart
// 🎵 Audio Settings Widget - Controlli per impostazioni audio
// ✅ Toggle suoni timer, volume, audio ducking, haptic feedback

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../core/services/audio_settings_service.dart';
import '../../../../shared/theme/app_colors.dart';

/// 🎵 Widget per le impostazioni audio
/// Mostra controlli per:
/// - Suoni timer (on/off)
/// - Volume beep (slider)
/// - Audio ducking (on/off)
/// - Haptic feedback (on/off)
class AudioSettingsWidget extends StatefulWidget {
  const AudioSettingsWidget({super.key});

  @override
  State<AudioSettingsWidget> createState() => _AudioSettingsWidgetState();
}

class _AudioSettingsWidgetState extends State<AudioSettingsWidget> {
  late AudioSettingsService _audioSettings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _audioSettings = getIt<AudioSettingsService>();
    _initializeSettings();
  }

  Future<void> _initializeSettings() async {
    await _audioSettings.initialize();
    _audioSettings.addListener(_onSettingsChanged);
    setState(() {
      _isLoading = false;
    });
  }

  void _onSettingsChanged() {
    setState(() {
      // Rebuild quando le impostazioni cambiano
    });
  }

  @override
  void dispose() {
    _audioSettings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header sezione
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Row(
            children: [
              Icon(
                Icons.volume_up,
                color: isDarkMode ? Colors.white70 : Colors.grey[600],
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Audio',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : Colors.grey[800],
                ),
              ),
            ],
          ),
        ),

        // Container principale
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Suoni Timer
              _buildSwitchTile(
                context,
                'Suoni Timer',
                'Riproduci beep durante i timer di pausa e isometrici',
                Icons.timer,
                _audioSettings.timerSoundsEnabled,
                (value) => _audioSettings.setTimerSoundsEnabled(value),
                isDarkMode,
              ),

              // Volume Beep
              if (_audioSettings.timerSoundsEnabled) ...[
                _buildDivider(isDarkMode),
                _buildVolumeSlider(context, isDarkMode),
              ],

              // Audio Ducking
              _buildDivider(isDarkMode),
              _buildSwitchTile(
                context,
                'Audio Ducking',
                'Abbassa temporaneamente la musica invece di interromperla',
                Icons.music_note,
                _audioSettings.audioDuckingEnabled,
                (value) => _audioSettings.setAudioDuckingEnabled(value),
                isDarkMode,
              ),

              // Haptic Feedback
              _buildDivider(isDarkMode),
              _buildSwitchTile(
                context,
                'Vibrazione',
                'Vibrazione durante timer e completamento serie',
                Icons.vibration,
                _audioSettings.hapticFeedbackEnabled,
                (value) => _audioSettings.setHapticFeedbackEnabled(value),
                isDarkMode,
              ),

              // Reset to Defaults
              _buildDivider(isDarkMode),
              _buildResetButton(context, isDarkMode),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
    bool isDarkMode,
  ) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: (isDarkMode ? Colors.grey[800] : Colors.grey[100])!.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(
          icon,
          color: isDarkMode ? Colors.white70 : Colors.grey[600],
          size: 20.sp,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
          color: isDarkMode ? Colors.white : Colors.grey[800],
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12.sp,
          color: isDarkMode ? Colors.white60 : Colors.grey[600],
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.indigo600,
        activeTrackColor: AppColors.indigo600.withValues(alpha: 0.3),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
    );
  }

  Widget _buildVolumeSlider(BuildContext context, bool isDarkMode) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.volume_up,
                color: isDarkMode ? Colors.white70 : Colors.grey[600],
                size: 16.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Volume Beep',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white : Colors.grey[800],
                ),
              ),
              const Spacer(),
              Text(
                '${(_audioSettings.beepVolume * 100).round()}%',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: isDarkMode ? Colors.white60 : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.indigo600,
              inactiveTrackColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
              thumbColor: AppColors.indigo600,
              overlayColor: AppColors.indigo600.withValues(alpha: 0.2),
              trackHeight: 4.h,
            ),
            child: Slider(
              value: _audioSettings.beepVolume,
              min: 0.0,
              max: 1.0,
              divisions: 10,
              onChanged: (value) => _audioSettings.setBeepVolume(value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDarkMode) {
    return Divider(
      height: 1,
      color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
      indent: 16.w,
      endIndent: 16.w,
    );
  }

  Widget _buildResetButton(BuildContext context, bool isDarkMode) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(
          Icons.restore,
          color: Colors.orange[600],
          size: 20.sp,
        ),
      ),
      title: Text(
        'Ripristina Impostazioni',
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
          color: isDarkMode ? Colors.white : Colors.grey[800],
        ),
      ),
      subtitle: Text(
        'Ripristina tutte le impostazioni audio ai valori predefiniti',
        style: TextStyle(
          fontSize: 12.sp,
          color: isDarkMode ? Colors.white60 : Colors.grey[600],
        ),
      ),
      onTap: _showResetConfirmation,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
    );
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ripristina Impostazioni'),
        content: const Text(
          'Sei sicuro di voler ripristinare tutte le impostazioni audio ai valori predefiniti?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              _audioSettings.resetToDefaults();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Impostazioni audio ripristinate'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Ripristina'),
          ),
        ],
      ),
    );
  }
} 