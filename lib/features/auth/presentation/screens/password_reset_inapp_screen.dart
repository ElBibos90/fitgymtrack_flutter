import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../core/services/biometric_auth_service.dart';
import '../../models/security_question_models.dart';
import '../../repository/security_questions_repository.dart';

/// Screen per reset password in-app con domande di sicurezza
/// 
/// Flow a 3 step:
/// 1. Inserisci username
/// 2. Rispondi alle domande di sicurezza
/// 3. Imposta nuova password
class PasswordResetInAppScreen extends StatefulWidget {
  const PasswordResetInAppScreen({super.key});

  @override
  State<PasswordResetInAppScreen> createState() =>
      _PasswordResetInAppScreenState();
}

class _PasswordResetInAppScreenState extends State<PasswordResetInAppScreen> {
  final _repository = SecurityQuestionsRepository();
  final _pageController = PageController();
  
  @override
  void initState() {
    super.initState();
   //print('[RESET] PasswordResetInAppScreen initState');
  }
  
  // Form keys
  final _usernameFormKey = GlobalKey<FormState>();
  final _questionsFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  
  // Controllers
  final _usernameController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final List<TextEditingController> _answerControllers = [];
  
  // State
  int _currentStep = 0;
  bool _isLoading = false;
  List<SecurityQuestion> _questions = [];
  String? _errorMessage;
  AccountStatus? _accountStatus;

  @override
  void dispose() {
    _pageController.dispose();
    _usernameController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    for (var controller in _answerControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
   //print('[RESET] PasswordResetInAppScreen build called');
    
    // Versione ultra-semplificata per debug
    return const Scaffold(
      body: Center(
        child: Text(
          'RESET PASSWORD FUNZIONA!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
    
    // Codice originale commentato per debug
    /*
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: _currentStep == 0
              ? () => context.pop()
              : () {
                  setState(() {
                    _currentStep--;
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  });
                },
        ),
        title: Text(
          'Recupera Password',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Progress Indicator
          _buildProgressIndicator(isDark, colorScheme),
          
          SizedBox(height: 16.h),
          
          // Error Message (if any)
          if (_errorMessage != null) _buildErrorBanner(),
          
          // Pages
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildUsernameStep(colorScheme, isDark),
                _buildQuestionsStep(colorScheme, isDark),
                _buildPasswordStep(colorScheme, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // PROGRESS INDICATOR
  // ===========================================================================

  Widget _buildProgressIndicator(bool isDark, ColorScheme colorScheme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w),
      child: Row(
        children: List.generate(3, (index) {
          final isActive = index <= _currentStep;
          final isCompleted = index < _currentStep;
          
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: isActive
                          ? (isDark ? const Color(0xFF90CAF9) : AppColors.indigo600)
                          : colorScheme.onSurface.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                if (index < 2) SizedBox(width: 8.w),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.error.withValues(alpha:0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 20.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: AppColors.error,
                fontSize: 14.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // STEP 1: USERNAME
  // ===========================================================================

  Widget _buildUsernameStep(ColorScheme colorScheme, bool isDark) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Form(
          key: _usernameFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 32.h),

              // Icon
              Center(
                child: Container(
                  width: 80.w,
                  height: 80.w,
                  decoration: BoxDecoration(
                    color: (isDark ? const Color(0xFF90CAF9) : AppColors.indigo600)
                        .withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(40.r),
                  ),
                  child: Icon(
                    Icons.person_outline,
                    size: 40.sp,
                    color: isDark ? const Color(0xFF90CAF9) : AppColors.indigo600,
                  ),
                ),
              ),

              SizedBox(height: 24.h),

              // Title
              Text(
                'Inserisci il tuo username',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onBackground,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 8.h),

              // Subtitle
              Text(
                'Recupereremo la tua password tramite le domande di sicurezza che hai configurato',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: colorScheme.onBackground.withValues(alpha:0.7),
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 32.h),

              // Username Field
              CustomTextField(
                controller: _usernameController,
                label: 'Username',
                hint: 'Inserisci il tuo username',
                prefixIcon: Icons.account_circle,
                textInputAction: TextInputAction.done,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Inserisci il tuo username';
                  }
                  return null;
                },
              ),

              SizedBox(height: 32.h),

              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleUsernameSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDark ? const Color(0xFF90CAF9) : AppColors.indigo600,
                    foregroundColor:
                        isDark ? AppColors.backgroundDark : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 24.w,
                          height: 24.w,
                          child: CircularProgressIndicator(
                            color: isDark
                                ? AppColors.backgroundDark
                                : Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Continua',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                          ),
                        ),
                ),
              ),

              SizedBox(height: 16.h),

              // Back to Login
              Center(
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text(
                    'Torna al login',
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFF90CAF9)
                          : AppColors.indigo600,
                      fontWeight: FontWeight.w500,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleUsernameSubmit() async {
    if (!(_usernameFormKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final username = _usernameController.text.trim();

      // Check account status first
      final statusResponse = await _repository.checkStatus(username);
      
      if (statusResponse.success && statusResponse.status != null) {
        _accountStatus = statusResponse.status;
        
        if (_accountStatus!.isLocked) {
          final message = _repository.formatLockedUntilMessage(
            _accountStatus!.lockedUntil,
          );
          setState(() {
            _errorMessage = message ?? _accountStatus!.reason;
            _isLoading = false;
          });
          return;
        }
      }

      // Get questions
      final response = await _repository.getQuestions(username);

      if (response.success && response.questions != null) {
        setState(() {
          _questions = response.questions!;
          _answerControllers.clear();
          for (var _ in _questions) {
            _answerControllers.add(TextEditingController());
          }
          _currentStep = 1;
          _isLoading = false;
        });
        
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        setState(() {
          _errorMessage = response.error ??
              'Errore nel recuperare le domande di sicurezza';
          _isLoading = false;
        });
        
        if (response.setupRequired == true) {
          _showSetupRequiredDialog();
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Errore di connessione. Riprova.';
        _isLoading = false;
      });
    }
  }

  void _showSetupRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Domande non configurate'),
        content: const Text(
          'Non hai ancora configurato le domande di sicurezza. '
          'Effettua il login e vai nelle Impostazioni per configurarle.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/login');
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // STEP 2: QUESTIONS
  // ===========================================================================

  Widget _buildQuestionsStep(ColorScheme colorScheme, bool isDark) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Form(
          key: _questionsFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16.h),

              // Icon
              Center(
                child: Container(
                  width: 80.w,
                  height: 80.w,
                  decoration: BoxDecoration(
                    color: (isDark ? const Color(0xFF90CAF9) : AppColors.indigo600)
                        .withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(40.r),
                  ),
                  child: Icon(
                    Icons.help_outline,
                    size: 40.sp,
                    color: isDark ? const Color(0xFF90CAF9) : AppColors.indigo600,
                  ),
                ),
              ),

              SizedBox(height: 24.h),

              // Title
              Text(
                'Rispondi alle domande',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onBackground,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 8.h),

              // Subtitle
              Text(
                'Per sicurezza, rispondi alle domande che hai configurato',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: colorScheme.onBackground.withValues(alpha:0.7),
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 32.h),

              // Questions List
              ...List.generate(_questions.length, (index) {
                final question = _questions[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: 16.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Domanda ${index + 1}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onBackground.withValues(alpha:0.6),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        question.question,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onBackground,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      CustomTextField(
                        controller: _answerControllers[index],
                        label: 'Risposta',
                        hint: 'Inserisci la tua risposta',
                        prefixIcon: Icons.edit,
                        textInputAction: index == _questions.length - 1
                            ? TextInputAction.done
                            : TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Risposta richiesta';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                );
              }),

              SizedBox(height: 24.h),

              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleQuestionsSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDark ? const Color(0xFF90CAF9) : AppColors.indigo600,
                    foregroundColor:
                        isDark ? AppColors.backgroundDark : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 24.w,
                          height: 24.w,
                          child: CircularProgressIndicator(
                            color: isDark
                                ? AppColors.backgroundDark
                                : Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Verifica Risposte',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleQuestionsSubmit() async {
    if (!(_questionsFormKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentStep = 2;
    });
    
    // Go to next step (password)
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    
    setState(() {
      _isLoading = false;
    });
  }

  // ===========================================================================
  // STEP 3: NEW PASSWORD
  // ===========================================================================

  Widget _buildPasswordStep(ColorScheme colorScheme, bool isDark) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Form(
          key: _passwordFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16.h),

              // Icon
              Center(
                child: Container(
                  width: 80.w,
                  height: 80.w,
                  decoration: BoxDecoration(
                    color: (isDark ? const Color(0xFF90CAF9) : AppColors.indigo600)
                        .withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(40.r),
                  ),
                  child: Icon(
                    Icons.lock_reset,
                    size: 40.sp,
                    color: isDark ? const Color(0xFF90CAF9) : AppColors.indigo600,
                  ),
                ),
              ),

              SizedBox(height: 24.h),

              // Title
              Text(
                'Nuova password',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onBackground,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 8.h),

              // Subtitle
              Text(
                'Inserisci una nuova password sicura per il tuo account',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: colorScheme.onBackground.withValues(alpha:0.7),
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 32.h),

              // New Password Field
              CustomTextField(
                controller: _newPasswordController,
                label: 'Nuova password',
                hint: 'Almeno 6 caratteri',
                prefixIcon: Icons.lock,
                isPassword: true,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Inserisci una nuova password';
                  }
                  if (value.length < 6) {
                    return 'Password deve essere di almeno 6 caratteri';
                  }
                  return null;
                },
              ),

              SizedBox(height: 16.h),

              // Confirm Password Field
              CustomTextField(
                controller: _confirmPasswordController,
                label: 'Conferma password',
                hint: 'Ripeti la password',
                prefixIcon: Icons.lock,
                isPassword: true,
                textInputAction: TextInputAction.done,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Conferma la password';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Le password non coincidono';
                  }
                  return null;
                },
              ),

              SizedBox(height: 32.h),

              // Reset Button
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handlePasswordSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDark ? const Color(0xFF90CAF9) : AppColors.indigo600,
                    foregroundColor:
                        isDark ? AppColors.backgroundDark : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 24.w,
                          height: 24.w,
                          child: CircularProgressIndicator(
                            color: isDark
                                ? AppColors.backgroundDark
                                : Colors.white,
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
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handlePasswordSubmit() async {
    if (!(_passwordFormKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Build answers list
      final answers = List.generate(
        _questions.length,
        (index) => UserSecurityAnswer(
          questionId: _questions[index].id,
          answer: _answerControllers[index].text.trim(),
        ),
      );

      // Verify and reset
      final response = await _repository.verifyAndResetPassword(
        username: _usernameController.text.trim(),
        answers: answers,
        newPassword: _newPasswordController.text.trim(),
      );

      if (response.success) {
        // Success!
        
        // 🔐 BIOMETRIC: Aggiorna credenziali biometriche dopo reset password
        await BiometricAuthService().updateCredentials(
          _usernameController.text.trim(),
          _newPasswordController.text.trim(),
        );
        
        if (mounted) {
          _showSuccessDialog(response.message ?? 'Password aggiornata con successo!');
        }
      } else {
        setState(() {
          _errorMessage = response.error ?? 'Errore nel reset della password';
          _isLoading = false;
        });
        
        // If rate limited, show message
        if (response.rateLimited == true) {
          final message = _repository.formatLockedUntilMessage(response.lockedUntil);
          setState(() {
            _errorMessage = message ?? response.error;
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Errore di connessione. Riprova.';
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 28.sp),
            SizedBox(width: 8.w),
            const Text('Successo!'),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/login');
            },
            child: const Text('Vai al Login'),
          ),
        ],
      ),
    );
    */
  }
}

