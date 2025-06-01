import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../bloc/auth_bloc.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String token;

  const ResetPasswordScreen({
    super.key,
    required this.token,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.go('/login'),
        ),
        title: Text(
          'Reimposta Password',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<PasswordResetBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthPasswordResetSuccess) {
            // Password reset successful
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            // Naviga al login dopo un breve delay
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) {
                context.go('/login');
              }
            });
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
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

                    // Key Icon
                    Container(
                      width: 80.w,
                      height: 80.w,
                      decoration: BoxDecoration(
                        color: AppColors.indigo600.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(40.r),
                      ),
                      child: Icon(
                        Icons.key,
                        size: 40.sp,
                        color: AppColors.indigo600,
                      ),
                    ),

                    SizedBox(height: 16.h),

                    Text(
                      'Imposta una nuova password',
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),

                    SizedBox(height: 8.h),

                    Text(
                      'Inserisci il codice di verifica ricevuto via email e crea una nuova password sicura',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.black.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 32.h),

                    // Reset Code Field
                    CustomTextField(
                      controller: _codeController,
                      label: 'Codice di verifica',
                      hint: 'Inserisci il codice ricevuto via email',
                      prefixIcon: Icons.verified_user,
                      keyboardType: TextInputType.text, // Supporta codici alfanumerici
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Inserisci il codice di verifica';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 16.h),

                    // New Password Field
                    CustomTextField(
                      controller: _passwordController,
                      label: 'Nuova password',
                      hint: 'Inserisci la nuova password',
                      prefixIcon: Icons.lock,
                      isPassword: true,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Inserisci una nuova password';
                        }
                        if (value.length < 6) {
                          return 'Password deve essere almeno 6 caratteri';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 16.h),

                    // Confirm Password Field
                    CustomTextField(
                      controller: _confirmPasswordController,
                      label: 'Conferma password',
                      hint: 'Conferma la nuova password',
                      prefixIcon: Icons.lock,
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Conferma la password';
                        }
                        if (value != _passwordController.text) {
                          return 'Le password non coincidono';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 24.h),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 56.h,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _handleResetPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.indigo600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? SizedBox(
                          width: 24.w,
                          height: 24.w,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : Text(
                          'Reimposta Password',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 16.h),

                    // Back to Login
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: Text(
                        'Torna al login',
                        style: TextStyle(
                          color: AppColors.indigo600,
                          fontWeight: FontWeight.w500,
                          fontSize: 14.sp,
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

  void _handleResetPassword() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<PasswordResetBloc>().confirmPasswordReset(
        widget.token,
        _codeController.text.trim(),
        _passwordController.text.trim(),
      );
    }
  }
}