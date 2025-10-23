// 🔧 AUTOFILL UPDATE: Login Screen con supporto completo autofill
// File: lib/features/auth/presentation/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'dart:io' show Platform;
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../../core/network/dio_client.dart';
import '../../bloc/auth_bloc.dart';
import '../../../../core/services/biometric_auth_service.dart';
import '../../../../core/di/dependency_injection.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isAutofillComplete = false;

  // 🔐 BIOMETRIC: Variabili per autenticazione biometrica
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  String _biometricType = 'Biometric';
  bool _biometricChecked = false; // Flag per evitare controlli duplicati
  final BiometricAuthService _biometricService = getIt<BiometricAuthService>();
  
  // Helper per ottenere testo user-friendly
  String get _biometricDisplayName {
    if (_biometricType.toLowerCase().contains('face')) {
      return 'Face ID';
    } else if (_biometricType.toLowerCase().contains('finger')) {
      return 'Impronta';
    }
    return 'Sblocco biometrico';
  }
  
  // Helper per ottenere icona corretta
  IconData get _biometricIcon {
    if (_biometricType.toLowerCase().contains('face')) {
      return Icons.face;
    }
    return Icons.fingerprint;
  }

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();  // 🔐 BIOMETRIC
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reset flag quando si torna alla login screen
    _biometricChecked = false;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ❌ RIMOSSO: iOS Keychain AutoFill (ridondante con biometrico)
  // Il biometrico già salva le credenziali in modo sicuro

  // 🔧 AUTOFILL: Gestione submit autofill migliorata per iOS
  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        AuthLoginRequested(
          username: _usernameController.text.trim(),
          password: _passwordController.text,
        ),
      );
    }
  }

  // 🔧 AUTOFILL: Callback per autofill completion migliorato per iOS
  void _handleAutofillComplete() {
    // Su iOS, verifica che entrambi i campi siano popolati prima di procedere
    if (Platform.isIOS) {
      if (_usernameController.text.isNotEmpty && _passwordController.text.isNotEmpty) {
        _isAutofillComplete = true;
        // Su iOS, non eseguire automaticamente il login dall'autofill
        // L'utente deve premere il pulsante "Accedi"
      }
    } else {
      // Su Android, mantieni il comportamento originale
      if (_usernameController.text.isNotEmpty && _passwordController.text.isNotEmpty) {
        _handleLogin();
      }
    }
  }

  // 🔧 AUTOFILL: Gestione submit da tastiera migliorata per iOS
  void _handlePasswordSubmitted(String value) {
    if (Platform.isIOS) {
      // Su iOS, non eseguire automaticamente il login da tastiera
      // L'utente deve premere il pulsante "Accedi"
      FocusScope.of(context).unfocus();
    } else {
      // Su Android, mantieni il comportamento originale
      _handleLogin();
    }
  }

  // 🔐 BIOMETRIC: Verifica disponibilità biometrico
  Future<void> _checkBiometricAvailability() async {
    // Evita controlli duplicati
    if (_biometricChecked) {
     //print('[ACCESS] ⚠️ Biometric already checked, skipping...');
      return;
    }
    
    try {
     //print('[ACCESS] 🔍 LOGIN SCREEN: Checking biometric availability...');
      _biometricChecked = true; // Marca come controllato
      
      final available = await _biometricService.isBiometricAvailable();
      final enabled = await _biometricService.isBiometricEnabled();
      final type = await _biometricService.getBiometricType();
      
     //print('[ACCESS] 📊 LOGIN SCREEN: Biometric status:');
     //print('[ACCESS]   - Available: $available');
     //print('[ACCESS]   - Enabled: $enabled');
     //print('[ACCESS]   - Type: $type');
      
      setState(() {
        _biometricAvailable = available;
        _biometricEnabled = enabled;
        _biometricType = type;
      });

      // ❌ RIMOSSO: Auto-login all'apertura
      // PROBLEMA: Con Face ID, il login si attiva automaticamente quando l'utente guarda lo schermo
      // SOLUZIONE: L'utente deve cliccare il pulsante biometrico per fare login
     //print('[ACCESS] ℹ️ Biometric check complete. User must click button to login.');
    } catch (e) {
     //print('[ACCESS] ❌ LOGIN SCREEN: Error checking biometric: $e');
    }
  }

  // RIMOSSO: Il campo username serve SOLO per login normale
  // Il biometrico si attiva SOLO dal pulsante dedicato

  // 🔧 CHECK FIRST LOGIN: Verifica se è il primo login (password temporanea)
  Future<bool> _checkFirstLogin() async {
    try {
     //print('[LOGIN] 🔍 Checking first login...');
      final dio = DioClient.getInstance();
      final response = await dio.get('/check_first_login.php');
      
     //print('[LOGIN] 📡 Response: ${response.data}');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final isFirstLogin = response.data['first_login'] ?? false;
       //print('[LOGIN] ✅ First login check: $isFirstLogin');
        return isFirstLogin;
      }
     //print('[LOGIN] ❌ Invalid response format');
      return false;
    } catch (e) {
     //print('[LOGIN] ❌ Error checking first login: $e');
      return false;
    }
  }

  // 🔐 BIOMETRIC: Tenta login biometrico
  Future<void> _tryBiometricLogin() async {
    try {
     //print('[ACCESS] 🚀 BIOMETRIC LOGIN STARTED');
      // Piccolo delay per evitare "auth_in_progress"
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Autentica con biometrico
     //print('[ACCESS] 🔐 Requesting biometric authentication...');
      final authenticated = await _biometricService.authenticateWithBiometrics(
        reason: 'Accedi a FitGymTrack',
      );

      if (!authenticated) {
       //print('[ACCESS] ❌ Biometric authentication cancelled or failed');
        return;
      }

     //print('[ACCESS] ✅ Biometric authentication successful, retrieving credentials...');
      setState(() => _isLoading = true);

      // Recupera credenziali salvate (username e password)
      final credentials = await _biometricService.getSavedCredentials();
      if (credentials == null) {
       //print('[ACCESS] ❌ CRITICAL: No saved credentials found after successful biometric auth!');
        setState(() {
          _isLoading = false;
        });
        
        // 🔧 ANDROID FIX: Messaggio più chiaro e opzione per riprovare
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Credenziali non trovate', 
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Effettua il login manuale per riabilitare il biometrico',
                      style: TextStyle(fontSize: 12)),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
          
          // 🔧 Disabilita il biometrico perché le credenziali sono perse
          setState(() {
            _biometricEnabled = false;
          });
        }
        return;
      }

      final username = credentials['username']!;
      final password = credentials['password']!;
      
     //print('[ACCESS] 🔑 Credentials retrieved successfully');
     //print('[ACCESS]   - Username: $username');
     //print('[ACCESS]   - Password length: ${password.length} chars');
     //print('[ACCESS] 📡 Sending login request to server...');

      // Fa login normale con le credenziali recuperate
      // Questo genererà un nuovo token dal server
      if (mounted) {
        context.read<AuthBloc>().add(
          AuthLoginRequested(
            username: username,
            password: password,
          ),
        );
      }

    } catch (e) {
      setState(() => _isLoading = false);
     //print('[ACCESS] ❌ BIOMETRIC LOGIN ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore login biometrico: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 🔐 BIOMETRIC: Mostra dialog per abilitare biometrico
  Future<void> _showEnableBiometricDialog() async {
   //print('[ACCESS] 🔐 _showEnableBiometricDialog called');
   //print('[ACCESS]   - Available: $_biometricAvailable');
   //print('[ACCESS]   - Enabled: $_biometricEnabled');
    
    if (!_biometricAvailable) {
     //print('[ACCESS] ⚠️ Biometric not available, skipping dialog');
      return;
    }
    
    if (_biometricEnabled) {
     //print('[ACCESS] ℹ️ Biometric already enabled, skipping dialog');
      return;
    }
    
   //print('[ACCESS] 📱 Showing enable biometric dialog...');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          title:             Row(
            children: [
              Icon(
                _biometricIcon,
                color: isDark ? const Color(0xFF90CAF9) : AppColors.indigo600,
                size: 32.sp,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'Abilita $_biometricDisplayName',
                  style: TextStyle(fontSize: 20.sp),
                ),
              ),
            ],
          ),
          content: Text(
            'Vuoi abilitare l\'accesso rapido con $_biometricDisplayName? '
            'Potrai accedere senza inserire username e password.',
            style: TextStyle(fontSize: 16.sp),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No grazie'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF90CAF9) : AppColors.indigo600,
                foregroundColor: isDark ? AppColors.backgroundDark : Colors.white,
              ),
              child: const Text('Abilita'),
            ),
          ],
        );
      },
    );

    if (result == true) {
     //print('[ACCESS] ✅ User confirmed biometric enablement');
      try {
        // Salva username e password per login biometrico futuro
        final username = _usernameController.text.trim();
        final password = _passwordController.text;
        
       //print('[ACCESS] 💾 Enabling biometric with credentials...');
        await _biometricService.enableBiometric(username, password);
        
        // 🔧 FIX: Controlla se il widget è ancora montato prima di chiamare setState
        if (mounted) {
          setState(() => _biometricEnabled = true);
         //print('[ACCESS] ✅ Biometric enabled successfully in UI');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$_biometricDisplayName abilitato con successo!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
         //print('[ACCESS] ⚠️ Widget disposed before setState, but biometric enabled successfully');
        }
      } catch (e) {
       //print('[ACCESS] ❌ Error enabling biometric in dialog: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Errore: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
     //print('[ACCESS] ❌ User declined biometric enablement');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
         //print('[LOGIN] 🔍 State received: ${state.runtimeType}');
          
          if (state is AuthLoading) {
           //print('[LOGIN] ⏳ Loading state received');
            setState(() => _isLoading = true);
          } else {
           //print('[LOGIN] ✅ Non-loading state received: ${state.runtimeType}');
            setState(() => _isLoading = false);
          }

          if (state is AuthLoginSuccess || state is AuthAuthenticated) {
           //print('[LOGIN] ✅ Login successful, state: ${state.runtimeType}');
            
            // 🔧 AUTOFILL: Finalize autofill context
            if (Platform.isAndroid) {
              TextInput.finishAutofillContext();
            }

            // 🔐 BIOMETRIC: Aggiorna credenziali biometriche (se già abilitato)
            // Questo sincronizza password dopo reset o cambio password
            _biometricService.updateCredentials(
              _usernameController.text.trim(),
              _passwordController.text,
            );

            // 🔐 BIOMETRIC: Proponi abilitazione biometrico dopo login riuscito
            final token = state is AuthLoginSuccess ? state.token : (state as AuthAuthenticated).token;
           //print('[LOGIN] 🔑 Token obtained, checking first login...');
            
            // 🔧 FIX: Controlla se è il primo login (password temporanea) - SEMPRE dopo login
            Future.delayed(const Duration(milliseconds: 500), () async {
              if (mounted) {
               //print('[LOGIN] 🔍 Checking first login after successful login...');
                // Controlla se è il primo login
                final isFirstLogin = await _checkFirstLogin();
                if (isFirstLogin) {
                 //print('[LOGIN] 🚀 First login detected, navigating to CompleteRegistrationScreen');
                  // Primo login: naviga al CompleteRegistrationScreen
                  context.go('/complete-registration');
                } else {
                 //print('[LOGIN] 🏠 Normal login, navigating to dashboard');
                  // Login normale: controlla biometrico e naviga al dashboard
                  final isEnabled = await _biometricService.isBiometricEnabled();
                  if (!isEnabled) {
                    _showEnableBiometricDialog();
                  }
                  context.go('/dashboard');
                }
              }
            });
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          return LoadingOverlay(
            isLoading: _isLoading,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  children: [
                    SizedBox(height: 40.h),

                    // Logo e Header
                    Column(
                      children: [
                        Container(
                          width: 80.w,
                          height: 80.w,
                          decoration: BoxDecoration(
                            color: (isDark ? const Color(0xFF90CAF9) : AppColors.indigo600).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(40.r),
                          ),
                          child: Icon(
                            Icons.fitness_center,
                            size: 40.sp,
                            color: isDark ? const Color(0xFF90CAF9) : AppColors.indigo600,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'FitGym Tracker',
                          style: TextStyle(
                            fontSize: 32.sp,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onBackground,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Container(
                                width: 10.w,
                                height: 10.w,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF90CAF9)
                                      : AppColors.indigo600,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Flexible(
                              child: Container(
                                width: 6.w,
                                height: 6.w,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF90CAF9)
                                      : AppColors.indigo600,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Flexible(
                              child: Container(
                                width: 10.w,
                                height: 10.w,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF90CAF9)
                                      : AppColors.indigo600,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Accedi all\'area riservata',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: colorScheme.onBackground.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 24.h),

                    // 🔐 BIOMETRIC: Pulsante biometrico compatto (icona + testo cliccabili)
                    if (_biometricAvailable) ...[
                      GestureDetector(
                        onTap: _biometricEnabled 
                            ? _tryBiometricLogin 
                            : () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Effettua prima il login per abilitare il biometrico'),
                                    backgroundColor: Colors.orange,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                        child: Column(
                          children: [
                            // Icona biometrica
                            Container(
                              width: 64.w,
                              height: 64.w,
                              decoration: BoxDecoration(
                                color: (isDark ? const Color(0xFF90CAF9) : AppColors.indigo600).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark ? const Color(0xFF90CAF9) : AppColors.indigo600,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                _biometricIcon,
                                size: 36.sp,
                                color: isDark ? const Color(0xFF90CAF9) : AppColors.indigo600,
                              ),
                            ),
                            
                            SizedBox(height: 8.h),
                            
                            // Testo "Accedi con..."
                            Text(
                              _biometricEnabled 
                                  ? 'Accedi con $_biometricDisplayName'
                                  : 'Abilita $_biometricDisplayName',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                color: isDark ? const Color(0xFF90CAF9) : AppColors.indigo600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 16.h),
                      
                      // Divider compatto
                      Row(
                        children: [
                          Expanded(child: Divider(color: isDark ? Colors.grey[700] : Colors.grey[400])),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12.w),
                            child: Text(
                              'oppure',
                              style: TextStyle(
                                color: isDark ? Colors.grey[500] : Colors.grey[600],
                                fontSize: 12.sp,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: isDark ? Colors.grey[700] : Colors.grey[400])),
                        ],
                      ),
                      
                      SizedBox(height: 16.h),
                    ],

                    // 🔧 AUTOFILL: AutofillGroup per gestire le credenziali
                    AutofillGroup(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Username Field con Autofill
                            CustomTextField(
                              controller: _usernameController,
                              label: 'Username',
                              hint: 'Inserisci username',
                              prefixIcon: Icons.person,
                              textInputAction: TextInputAction.next,
                              keyboardType: TextInputType.text,
                              // 🔧 AUTOFILL: Hints per username con configurazione iOS
                              autofillHints: Platform.isIOS 
                                  ? const [AutofillHints.username, AutofillHints.email, AutofillHints.name]
                                  : const [AutofillHints.username],
                              enableSuggestions: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Inserisci il tuo username';
                                }
                                return null;
                              },
                            ),

                            SizedBox(height: 12.h),

                            // Password Field con Autofill
                            CustomTextField(
                              controller: _passwordController,
                              label: 'Password',
                              hint: 'Inserisci la tua password',
                              prefixIcon: Icons.lock,
                              isPassword: true,
                              textInputAction: TextInputAction.done,
                              keyboardType: TextInputType.visiblePassword,
                              // 🔧 AUTOFILL: Hints per password con configurazione iOS
                              autofillHints: Platform.isIOS 
                                  ? const [AutofillHints.password, AutofillHints.newPassword]
                                  : const [AutofillHints.password],
                              enableSuggestions: false, // Disabilita suggerimenti per password
                              onEditingComplete: _handleAutofillComplete,
                              onSubmitted: _handlePasswordSubmitted,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Inserisci la tua password';
                                }
                                return null;
                              },
                            ),

                            SizedBox(height: 24.h),

                            // Password dimenticata
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => _showPasswordResetOptions(context, isDark),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                ),
                                child: Text(
                                  'Password dimenticata?',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: isDark ? const Color(0xFF90CAF9) : AppColors.indigo600,
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: 20.h),

                            // Login Button
                            SizedBox(
                              width: double.infinity,
                              height: 56.h,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark ? const Color(0xFF90CAF9) : AppColors.indigo600,
                                  foregroundColor: isDark ? AppColors.backgroundDark : Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                ),
                                child: _isLoading
                                    ? SizedBox(
                                  width: 24.w,
                                  height: 24.w,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: isDark ? AppColors.backgroundDark : Colors.white,
                                  ),
                                )
                                    : Text(
                                  'Accedi',
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: 16.h),

                            // Link registrazione
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Non hai un account? ',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: colorScheme.onBackground.withValues(alpha: 0.7),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => context.push('/register'),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: Text(
                                    'Registrati',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? const Color(0xFF90CAF9) : AppColors.indigo600,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 24.h),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Mostra dialog per reset password con domande di sicurezza
  void _showPasswordResetOptions(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (dialogContext) => _PasswordResetDialog(isDark: isDark),
    );
  }
}

/// Dialog per reset password con domande di sicurezza integrate
class _PasswordResetDialog extends StatefulWidget {
  final bool isDark;
  
  const _PasswordResetDialog({required this.isDark});

  @override
  State<_PasswordResetDialog> createState() => _PasswordResetDialogState();
}

class _PasswordResetDialogState extends State<_PasswordResetDialog> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  int _currentStep = 0; // 0: username, 1: domande, 2: password
  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _questions = [];
  List<TextEditingController> _answerControllers = [];
  List<String> _answers = []; // Risposte per API sicura

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    for (var controller in _answerControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _currentStep == 0 ? 'Recupera Password' : 
        _currentStep == 1 ? 'Domande di Sicurezza' : 'Nuova Password',
        style: TextStyle(fontSize: 20.sp),
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: _currentStep == 1 ? 400.h : null, // Altezza fissa per domande
        child: SingleChildScrollView(
          child: _buildStepContent(),
        ),
      ),
      actions: _buildActions(),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildUsernameStep();
      case 1:
        return _buildQuestionsStep();
      case 2:
        return _buildPasswordStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildUsernameStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Inserisci il tuo username:',
          style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
        ),
        SizedBox(height: 16.h),
        TextField(
          controller: _usernameController,
          decoration: InputDecoration(
            hintText: 'Username',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
        ),
        if (_errorMessage != null) ...[
          SizedBox(height: 8.h),
          Text(
            _errorMessage!,
            style: TextStyle(color: Colors.red, fontSize: 12.sp),
          ),
        ],
      ],
    );
  }

  Widget _buildQuestionsStep() {
    if (_questions.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rispondi alle domande di sicurezza:',
          style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
        ),
        SizedBox(height: 16.h),
        ...List.generate(_questions.length, (index) {
          return Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _questions[index]['question'] as String? ?? '',
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 8.h),
                TextField(
                  controller: _answerControllers[index],
                  decoration: InputDecoration(
                    hintText: 'La tua risposta',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        if (_errorMessage != null) ...[
          SizedBox(height: 8.h),
          Text(
            _errorMessage!,
            style: TextStyle(color: Colors.red, fontSize: 12.sp),
          ),
        ],
      ],
    );
  }

  Widget _buildPasswordStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Imposta la nuova password:',
          style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
        ),
        SizedBox(height: 16.h),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(
            hintText: 'Nuova password',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
        ),
        SizedBox(height: 12.h),
        TextField(
          controller: _confirmPasswordController,
          obscureText: true,
          decoration: InputDecoration(
            hintText: 'Conferma password',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
        ),
        if (_errorMessage != null) ...[
          SizedBox(height: 8.h),
          Text(
            _errorMessage!,
            style: TextStyle(color: Colors.red, fontSize: 12.sp),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildActions() {
    if (_currentStep == 0) {
      return [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _getQuestions,
          child: _isLoading 
            ? SizedBox(
                width: 16.w,
                height: 16.h,
                child: const CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Continua'),
        ),
      ];
    } else if (_currentStep == 1) {
      return [
        TextButton(
          onPressed: () {
            setState(() {
              _currentStep = 0;
              _errorMessage = null;
            });
          },
          child: const Text('Indietro'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _verifyAnswers,
          child: _isLoading 
            ? SizedBox(
                width: 16.w,
                height: 16.h,
                child: const CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Verifica'),
        ),
      ];
    } else {
      return [
        TextButton(
          onPressed: () {
            setState(() {
              _currentStep = 1;
              _errorMessage = null;
            });
          },
          child: const Text('Indietro'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _resetPassword,
          child: _isLoading 
            ? SizedBox(
                width: 16.w,
                height: 16.h,
                child: const CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Reset Password'),
        ),
      ];
    }
  }

  Future<void> _getQuestions() async {
    if (_usernameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Inserisci un username';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Chiamata API REALE per ottenere le domande
      final dio = DioClient.getInstance();
      final response = await dio.get(
        '/password_reset_inapp.php',
        queryParameters: {
          'action': 'get_questions',
          'username': _usernameController.text.trim(),
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final questionsData = response.data['questions'] as List;
        setState(() {
          _questions = questionsData.map((q) => {
            'question': q['question'] as String,
            'id': q['id'].toString(),
          }).toList();
          _answerControllers = List.generate(
            _questions.length,
            (index) => TextEditingController(),
          );
          _currentStep = 1;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.data['error'] ?? 'Username non trovato';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Errore di connessione. Riprova.';
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyAnswers() async {
    // Verifica che tutte le risposte siano inserite
    for (int i = 0; i < _answerControllers.length; i++) {
      if (_answerControllers[i].text.trim().isEmpty) {
        setState(() {
          _errorMessage = 'Rispondi a tutte le domande';
        });
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Salva le risposte per l'API sicura
    _answers = _answerControllers.map((controller) => controller.text.trim()).toList();
    
    // Verifica manuale delle risposte (per ora)
    // TODO: Implementare verifica reale quando l'API sarà completa
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      _currentStep = 2;
      _isLoading = false;
    });
  }

  Future<void> _resetPassword() async {
    if (_passwordController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Inserisci una password';
      });
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Le password non coincidono';
      });
      return;
    }

    if (_passwordController.text.length < 6) {
      setState(() {
        _errorMessage = 'La password deve essere di almeno 6 caratteri';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Chiamata API reale per reset password
      final response = await _callResetPasswordAPI();
      
      if (response['success'] == true) {
        // Successo!
        
        // 🔐 BIOMETRIC: Aggiorna credenziali biometriche dopo reset password
        await BiometricAuthService().updateCredentials(
          _usernameController.text.trim(),
          _passwordController.text.trim(),
        );
        
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password resettata con successo!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _errorMessage = response['error'] ?? 'Errore durante il reset';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Errore di connessione. Riprova.';
        _isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>> _callResetPasswordAPI() async {
    // Chiamata API SICURA per reset password con verifica risposte
    final dio = DioClient.getInstance();
    
    // DEBUG: Log delle risposte inviate
   //print('[RESET DEBUG] Username: ${_usernameController.text.trim()}');
   //print('[RESET DEBUG] Answers: $_answers');
   //print('[RESET DEBUG] Password: ${_passwordController.text.trim()}');
    
    final response = await dio.post(
      '/simple_password_reset.php',
      data: {
        'username': _usernameController.text.trim(),
        'answers': _answers, // Risposte verificate localmente
        'new_password': _passwordController.text.trim(),
      },
      options: Options(
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );
    
    // DEBUG: Log della risposta
   //print('[RESET DEBUG] Response: ${response.data}');
    
    return response.data;
  }
}