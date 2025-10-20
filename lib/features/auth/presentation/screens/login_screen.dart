// 🔧 AUTOFILL UPDATE: Login Screen con supporto completo autofill
// File: lib/features/auth/presentation/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io' show Platform;
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../bloc/auth_bloc.dart';
import '../../../../core/services/biometric_auth_service.dart';
import '../../../../core/services/session_service.dart';
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
  
  // 🔧 AUTOFILL: Storage per credenziali iOS
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

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
    _loadSavedCredentials();
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

  // 🔧 AUTOFILL: Carica credenziali salvate
  Future<void> _loadSavedCredentials() async {
    if (Platform.isIOS) {
      try {
        final savedUsername = await _secureStorage.read(key: 'saved_username');
        final savedPassword = await _secureStorage.read(key: 'saved_password');
        
        if (savedUsername != null && savedPassword != null) {
          setState(() {
            _usernameController.text = savedUsername;
            _passwordController.text = savedPassword;
          });
        }
      } catch (e) {
        // Gestione silenziosa degli errori
      }
    }
  }

  // 🔧 AUTOFILL: Salva credenziali
  Future<void> _saveCredentials() async {
    if (Platform.isIOS) {
      try {
        await _secureStorage.write(key: 'saved_username', value: _usernameController.text.trim());
        await _secureStorage.write(key: 'saved_password', value: _passwordController.text);
      } catch (e) {
        // Gestione silenziosa degli errori
      }
    }
  }

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
      print('[LOGIN] ⚠️ Biometric already checked, skipping...');
      return;
    }
    
    try {
      print('[LOGIN] 🔍 Checking biometric availability...');
      _biometricChecked = true; // Marca come controllato
      
      final available = await _biometricService.isBiometricAvailable();
      final enabled = await _biometricService.isBiometricEnabled();
      final type = await _biometricService.getBiometricType();
      
      print('[LOGIN] 📊 Biometric status:');
      print('[LOGIN]   - Available: $available');
      print('[LOGIN]   - Enabled: $enabled');
      print('[LOGIN]   - Type: $type');
      
      setState(() {
        _biometricAvailable = available;
        _biometricEnabled = enabled;
        _biometricType = type;
      });

      // ✅ Auto-login all'apertura se biometrico abilitato
      // Se l'utente non vuole, può premere cancel
      if (_biometricEnabled && mounted) {
        print('[LOGIN] ✅ Biometric enabled, trying auto-login...');
        await _tryBiometricLogin();
      } else {
        print('[LOGIN] ℹ️ Biometric not enabled, normal login flow');
      }
    } catch (e) {
      print('[LOGIN] ❌ Error checking biometric: $e');
    }
  }

  // RIMOSSO: Il campo username serve SOLO per login normale
  // Il biometrico si attiva SOLO dal pulsante dedicato

  // 🔐 BIOMETRIC: Tenta login biometrico
  Future<void> _tryBiometricLogin() async {
    try {
      // Piccolo delay per evitare "auth_in_progress"
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Autentica con biometrico
      final authenticated = await _biometricService.authenticateWithBiometrics(
        reason: 'Accedi a FitGymTrack',
      );

      if (!authenticated) {
        return;
      }

      print('[LOGIN] ✅ Biometric authentication successful');
      setState(() => _isLoading = true);

      // Recupera credenziali salvate (username e password)
      final credentials = await _biometricService.getSavedCredentials();
      if (credentials == null) {
        print('[LOGIN] ❌ No saved credentials found');
        setState(() {
          _isLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Credenziali non trovate. Effettua il login.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      final username = credentials['username']!;
      final password = credentials['password']!;
      
      print('[LOGIN] 🔑 Credentials retrieved, logging in with username: $username');

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
      print('[Login] ❌ Biometric login error: $e');
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
    print('[LOGIN] 🔐 _showEnableBiometricDialog called');
    print('[LOGIN]   - Available: $_biometricAvailable');
    print('[LOGIN]   - Enabled: $_biometricEnabled');
    
    if (!_biometricAvailable) {
      print('[LOGIN] ⚠️ Biometric not available, skipping dialog');
      return;
    }
    
    if (_biometricEnabled) {
      print('[LOGIN] ℹ️ Biometric already enabled, skipping dialog');
      return;
    }
    
    print('[LOGIN] 📱 Showing enable biometric dialog...');

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
      try {
        // Salva username e password per login biometrico futuro
        final username = _usernameController.text.trim();
        final password = _passwordController.text;
        
        await _biometricService.enableBiometric(username, password);
        setState(() => _biometricEnabled = true);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$_biometricDisplayName abilitato con successo!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Errore: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthLoading) {
            setState(() => _isLoading = true);
          } else {
            setState(() => _isLoading = false);
          }

          if (state is AuthLoginSuccess || state is AuthAuthenticated) {
            print('[LOGIN] ✅ Login successful, state: ${state.runtimeType}');
            
            // 🔧 AUTOFILL: Salva credenziali per il prossimo login
            // Su iOS, salva le credenziali nel Keychain
            if (Platform.isIOS) {
              _saveCredentials();
              // Su iOS, chiama finishAutofillContext sempre dopo un login riuscito
              TextInput.finishAutofillContext();
            } else if (Platform.isAndroid) {
              TextInput.finishAutofillContext();
            }

            // 🔐 BIOMETRIC: Proponi abilitazione biometrico dopo login riuscito
            final token = state is AuthLoginSuccess ? state.token : (state as AuthAuthenticated).token;
            print('[LOGIN] 🔑 Token obtained, scheduling biometric dialog...');
            
            // Mostra dialog biometrico (solo se non già abilitato)
            Future.delayed(const Duration(milliseconds: 500), () {
              print('[LOGIN] ⏰ Dialog delay completed, showing dialog...');
              if (mounted) {
                _showEnableBiometricDialog();
              } else {
                print('[LOGIN] ⚠️ Widget not mounted, skipping dialog');
              }
            });
            
            context.go('/dashboard');
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
                    SizedBox(height: 60.h),

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

                    SizedBox(height: 48.h),

                    // 🔐 BIOMETRIC: Pulsante biometrico (se disponibile e abilitato)
                    if (_biometricAvailable) ...[
                      // Pulsante grande biometrico sempre visibile
                      GestureDetector(
                        onTap: _biometricEnabled 
                            ? _tryBiometricLogin 
                            : () {
                                // Se non abilitato, mostra messaggio
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Effettua prima il login per abilitare il biometrico'),
                                    backgroundColor: Colors.orange,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                        child: Container(
                          width: 80.w,
                          height: 80.w,
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
                            size: 48.sp,
                            color: isDark ? const Color(0xFF90CAF9) : AppColors.indigo600,
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 12.h),
                      
                      Text(
                        _biometricEnabled 
                            ? 'Accedi con $_biometricDisplayName'
                            : 'Abilita $_biometricDisplayName',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFF90CAF9) : AppColors.indigo600,
                        ),
                      ),
                      
                      SizedBox(height: 24.h),
                      
                      // Divider
                      Row(
                        children: [
                          Expanded(child: Divider(color: isDark ? Colors.grey[700] : Colors.grey[400])),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: Text(
                              'oppure',
                              style: TextStyle(
                                color: isDark ? Colors.grey[500] : Colors.grey[600],
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: isDark ? Colors.grey[700] : Colors.grey[400])),
                        ],
                      ),
                      
                      SizedBox(height: 24.h),
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

                            SizedBox(height: 16.h),

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
                                onPressed: () => context.push('/forgot-password'),
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

                            SizedBox(height: 32.h),

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

                            SizedBox(height: 24.h),

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

                            SizedBox(height: 40.h),
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
}