import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../bloc/auth_bloc.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: BlocConsumer<RegisterBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthRegisterSuccess) {
            // Mostra messaggio di successo e torna al login
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
              ),
            );
            context.go('/login');
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
          final isLoading = state is AuthLoading;

          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    SizedBox(height: 32.h),

                    // Header
                    Column(
                      children: [
                        Text(
                          'Registrazione',
                          style: TextStyle(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFF90CAF9) : AppColors.indigo600,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Crea il tuo account personale',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: colorScheme.onBackground.withValues(alpha:0.7),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 48.h),

                    // Form Fields
                    Column(
                      children: [
                        // Username Field
                        CustomTextField(
                          controller: _usernameController,
                          label: 'Username',
                          hint: 'Scegli un username',
                          prefixIcon: Icons.person,
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Inserisci un username';
                            }
                            if (value.length < 3) {
                              return 'Username deve essere almeno 3 caratteri';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: 16.h),

                        // Password Field
                        CustomTextField(
                          controller: _passwordController,
                          label: 'Password',
                          hint: 'Crea una password sicura',
                          prefixIcon: Icons.lock,
                          isPassword: true,
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Inserisci una password';
                            }
                            if (value.length < 6) {
                              return 'Password deve essere almeno 6 caratteri';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: 16.h),

                        // Email Field
                        CustomTextField(
                          controller: _emailController,
                          label: 'Email',
                          hint: 'Inserisci la tua email',
                          prefixIcon: Icons.email,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Inserisci la tua email';
                            }
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                              return 'Inserisci una email valida';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: 16.h),

                        // Name Field
                        CustomTextField(
                          controller: _nameController,
                          label: 'Nome completo',
                          hint: 'Inserisci il tuo nome completo',
                          prefixIcon: Icons.account_circle,
                          textInputAction: TextInputAction.done,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Inserisci il tuo nome';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: 32.h),

                        // Register Button
                        SizedBox(
                          width: double.infinity,
                          height: 50.h,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _handleRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? const Color(0xFF90CAF9) : AppColors.indigo600,
                              foregroundColor: isDark ? AppColors.backgroundDark : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              elevation: 0,
                            ),
                            child: isLoading
                                ? SizedBox(
                              width: 24.w,
                              height: 24.w,
                              child: CircularProgressIndicator(
                                color: isDark ? AppColors.backgroundDark : Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                                : Text(
                              'Registrati',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16.sp,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 16.h),

                        // Login Link
                        TextButton(
                          onPressed: () => context.go('/login'),
                          child: Text(
                            'Hai già un account? Accedi',
                            style: TextStyle(
                              color: isDark ? const Color(0xFF90CAF9) : AppColors.indigo600,
                              fontWeight: FontWeight.w500,
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                      ],
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

  void _handleRegister() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<RegisterBloc>().register(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
        _emailController.text.trim(),
        _nameController.text.trim(),
      );
    }
  }
}