// lib/core/services/audio_settings_service.dart
// 🎵 Audio Settings Service - Gestione preferenze audio
// ✅ Gestisce mute/unmute, volume, audio ducking
// ✅ Persistenza con SharedPreferences

import 'package:shared_preferences/shared_preferences.dart';

/// 🎵 Audio Settings Service
/// Gestisce tutte le preferenze audio dell'app
/// - Suoni timer (on/off)
/// - Volume beep (0-100%)
/// - Audio ducking (on/off)
class AudioSettingsService {
  // Chiavi per le singole impostazioni
  static const String _keyTimerSoundsEnabled = 'timer_sounds_enabled';
  static const String _keyBeepVolume = 'beep_volume';
  static const String _keyAudioDuckingEnabled = 'audio_ducking_enabled';
  static const String _keyHapticFeedbackEnabled = 'haptic_feedback_enabled';
  
  // Valori di default
  static const bool _defaultTimerSoundsEnabled = true;
  static const double _defaultBeepVolume = 0.7; // 70%
  static const bool _defaultAudioDuckingEnabled = true;
  static const bool _defaultHapticFeedbackEnabled = true;
  
  // Cache delle impostazioni
  bool _timerSoundsEnabled = _defaultTimerSoundsEnabled;
  double _beepVolume = _defaultBeepVolume;
  bool _audioDuckingEnabled = _defaultAudioDuckingEnabled;
  bool _hapticFeedbackEnabled = _defaultHapticFeedbackEnabled;
  
  // Callback per notificare cambiamenti
  final List<Function()> _listeners = [];
  
  /// Inizializza il servizio caricando le impostazioni
  Future<void> initialize() async {
    await _loadSettings();
  }
  
  /// Aggiunge un listener per i cambiamenti delle impostazioni
  void addListener(Function() listener) {
    _listeners.add(listener);
  }
  
  /// Rimuove un listener
  void removeListener(Function() listener) {
    _listeners.remove(listener);
  }
  
  /// Notifica tutti i listener
  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }
  
  // ============================================================================
  // GETTERS
  // ============================================================================
  
  /// Suoni timer abilitati
  bool get timerSoundsEnabled => _timerSoundsEnabled;
  
  /// Volume beep (0.0 - 1.0)
  double get beepVolume => _beepVolume;
  
  /// Audio ducking abilitato
  bool get audioDuckingEnabled => _audioDuckingEnabled;
  
  /// Haptic feedback abilitato
  bool get hapticFeedbackEnabled => _hapticFeedbackEnabled;
  
  // ============================================================================
  // SETTERS
  // ============================================================================
  
  /// Imposta se i suoni timer sono abilitati
  Future<void> setTimerSoundsEnabled(bool enabled) async {
    if (_timerSoundsEnabled != enabled) {
      _timerSoundsEnabled = enabled;
      await _saveSettings();
      _notifyListeners();
    }
  }
  
  /// Imposta il volume dei beep (0.0 - 1.0)
  Future<void> setBeepVolume(double volume) async {
    final clampedVolume = volume.clamp(0.0, 1.0);
    if (_beepVolume != clampedVolume) {
      _beepVolume = clampedVolume;
      await _saveSettings();
      _notifyListeners();
    }
  }
  
  /// Imposta se l'audio ducking è abilitato
  Future<void> setAudioDuckingEnabled(bool enabled) async {
    if (_audioDuckingEnabled != enabled) {
      _audioDuckingEnabled = enabled;
      await _saveSettings();
      _notifyListeners();
    }
  }
  
  /// Imposta se l'haptic feedback è abilitato
  Future<void> setHapticFeedbackEnabled(bool enabled) async {
    if (_hapticFeedbackEnabled != enabled) {
      _hapticFeedbackEnabled = enabled;
      await _saveSettings();
      _notifyListeners();
    }
  }
  
  // ============================================================================
  // UTILITY METHODS
  // ============================================================================
  
  /// Verifica se i suoni timer sono abilitati E il volume > 0
  bool get shouldPlayTimerSounds => _timerSoundsEnabled && _beepVolume > 0.0;
  
  /// Resetta tutte le impostazioni ai valori di default
  Future<void> resetToDefaults() async {
    _timerSoundsEnabled = _defaultTimerSoundsEnabled;
    _beepVolume = _defaultBeepVolume;
    _audioDuckingEnabled = _defaultAudioDuckingEnabled;
    _hapticFeedbackEnabled = _defaultHapticFeedbackEnabled;
    
    await _saveSettings();
    _notifyListeners();
  }
  
  /// Ottiene tutte le impostazioni come Map
  Map<String, dynamic> getAllSettings() {
    return {
      _keyTimerSoundsEnabled: _timerSoundsEnabled,
      _keyBeepVolume: _beepVolume,
      _keyAudioDuckingEnabled: _audioDuckingEnabled,
      _keyHapticFeedbackEnabled: _hapticFeedbackEnabled,
    };
  }
  
  // ============================================================================
  // PERSISTENCE
  // ============================================================================
  
  /// Carica le impostazioni da SharedPreferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _timerSoundsEnabled = prefs.getBool(_keyTimerSoundsEnabled) ?? _defaultTimerSoundsEnabled;
      _beepVolume = prefs.getDouble(_keyBeepVolume) ?? _defaultBeepVolume;
      _audioDuckingEnabled = prefs.getBool(_keyAudioDuckingEnabled) ?? _defaultAudioDuckingEnabled;
      _hapticFeedbackEnabled = prefs.getBool(_keyHapticFeedbackEnabled) ?? _defaultHapticFeedbackEnabled;
      
      //print('🎵 [AUDIO SETTINGS] Loaded settings: timer=$_timerSoundsEnabled, volume=$_beepVolume, ducking=$_audioDuckingEnabled, haptic=$_hapticFeedbackEnabled');
    } catch (e) {
      //print('🎵 [AUDIO SETTINGS] Error loading settings: $e');
      // Usa valori di default in caso di errore
      _timerSoundsEnabled = _defaultTimerSoundsEnabled;
      _beepVolume = _defaultBeepVolume;
      _audioDuckingEnabled = _defaultAudioDuckingEnabled;
      _hapticFeedbackEnabled = _defaultHapticFeedbackEnabled;
    }
  }
  
  /// Salva le impostazioni in SharedPreferences
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool(_keyTimerSoundsEnabled, _timerSoundsEnabled);
      await prefs.setDouble(_keyBeepVolume, _beepVolume);
      await prefs.setBool(_keyAudioDuckingEnabled, _audioDuckingEnabled);
      await prefs.setBool(_keyHapticFeedbackEnabled, _hapticFeedbackEnabled);
      
      //print('🎵 [AUDIO SETTINGS] Saved settings: timer=$_timerSoundsEnabled, volume=$_beepVolume, ducking=$_audioDuckingEnabled, haptic=$_hapticFeedbackEnabled');
    } catch (e) {
      //print('🎵 [AUDIO SETTINGS] Error saving settings: $e');
    }
  }
} 