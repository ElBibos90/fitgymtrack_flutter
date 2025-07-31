// 🔧 AUTOFILL UPDATE: Login Screen con supporto completo autofill
// File: lib/features/auth/presentation/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'dart:io' show Platform;
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../bloc/auth_bloc.dart';

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

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
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
            // 🔧 AUTOFILL: Salva credenziali per il prossimo login
            // Su iOS, chiama finishAutofillContext sempre dopo un login riuscito
            if (Platform.isIOS) {
              // Su iOS, salva sempre le credenziali nel Keychain dopo un login riuscito
              TextInput.finishAutofillContext();
            } else if (Platform.isAndroid) {
              TextInput.finishAutofillContext();
            }
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
                                  ? const [AutofillHints.username, AutofillHints.email]
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