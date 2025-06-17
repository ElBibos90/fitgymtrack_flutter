import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../bloc/auth_bloc.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: colorScheme.onSurface,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Password dimenticata',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<PasswordResetBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthPasswordResetEmailSent) {
            // Se c'è un token, naviga alla schermata di reset
            if (state.token != null) {
              context.push('/reset-password/${state.token}');
            } else {
              // Altrimenti mostra solo messaggio di successo
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.success,
                ),
              );
            }
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
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    SizedBox(height: 32.h),

                    // Icon
                    Container(
                      width: 80.w,
                      height: 80.w,
                      decoration: BoxDecoration(
                        color: (isDark ? const Color(0xFF90CAF9) : AppColors.indigo600).withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(40.r),
                      ),
                      child: Icon(
                        Icons.lock_reset,
                        size: 40.sp,
                        color: isDark ? const Color(0xFF90CAF9) : AppColors.indigo600,
                      ),
                    ),

                    SizedBox(height: 24.h),

                    Text(
                      'Recupera la tua password',
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onBackground,
                      ),
                    ),

                    SizedBox(height: 8.h),

                    Text(
                      'Inserisci la tua email per ricevere le istruzioni di reset',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: colorScheme.onBackground.withValues(alpha:0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 32.h),

                    // Email Field
                    CustomTextField(
                      controller: _emailController,
                      label: 'Email',
                      hint: 'Inserisci la tua email',
                      prefixIcon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
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

                    SizedBox(height: 32.h),

                    // Send Button
                    SizedBox(
                      width: double.infinity,
                      height: 50.h,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _handleSendReset,
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
                          'Invia istruzioni',
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
                          color: isDark ? const Color(0xFF90CAF9) : AppColors.indigo600,
                          fontWeight: FontWeight.w500,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),

                    const Spacer(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleSendReset() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<PasswordResetBloc>().requestPasswordReset(
        _emailController.text.trim(),
      );
    }
  }
}