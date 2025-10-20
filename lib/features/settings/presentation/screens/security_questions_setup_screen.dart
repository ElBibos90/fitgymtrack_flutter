import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../auth/models/security_question_models.dart';
import '../../../auth/repository/security_questions_repository.dart';

/// Screen per configurare/modificare le domande di sicurezza
/// 
/// Feature:
/// - Lista di domande disponibili
/// - Selezione di almeno 3 domande
/// - Input risposte
/// - Salvataggio sicuro
class SecurityQuestionsSetupScreen extends StatefulWidget {
  const SecurityQuestionsSetupScreen({super.key});

  @override
  State<SecurityQuestionsSetupScreen> createState() =>
      _SecurityQuestionsSetupScreenState();
}

class _SecurityQuestionsSetupScreenState
    extends State<SecurityQuestionsSetupScreen> {
  final _repository = SecurityQuestionsRepository();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isSaving = false;
  List<SecurityQuestion> _availableQuestions = [];
  List<QuestionWithAnswer> _selectedQuestions = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final response = await _repository.listAvailableQuestions();

      if (response.success && response.questions != null) {
        setState(() {
          _availableQuestions = response.questions!;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.error ?? 'Errore nel caricare le domande';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Errore di connessione';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          backgroundColor: colorScheme.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Domande di Sicurezza',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: CircularProgressIndicator(
            color: isDark ? const Color(0xFF90CAF9) : AppColors.indigo600,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Domande di Sicurezza',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info Card
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: (isDark
                                  ? const Color(0xFF90CAF9)
                                  : AppColors.indigo600)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: (isDark
                                    ? const Color(0xFF90CAF9)
                                    : AppColors.indigo600)
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: isDark
                                  ? const Color(0xFF90CAF9)
                                  : AppColors.indigo600,
                              size: 24.sp,
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                'Seleziona almeno 3 domande e fornisci le risposte. '
                                'Ti serviranno per recuperare la password se la dimentichi.',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: colorScheme.onBackground.withValues(alpha:0.8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24.h),

                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Domande selezionate: ${_selectedQuestions.length}/12',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onBackground,
                            ),
                          ),
                          if (_selectedQuestions.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedQuestions.clear();
                                });
                              },
                              child: Text(
                                'Rimuovi tutte',
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ),
                        ],
                      ),

                      if (_selectedQuestions.length < 3)
                        Padding(
                          padding: EdgeInsets.only(top: 4.h, bottom: 16.h),
                          child: Text(
                            'Seleziona almeno ${3 - _selectedQuestions.length} domande ancora',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: AppColors.error,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),

                      SizedBox(height: 8.h),

                      // Selected Questions (with answers)
                      if (_selectedQuestions.isNotEmpty)
                        ..._selectedQuestions.asMap().entries.map((entry) {
                          final index = entry.key;
                          final questionWithAnswer = entry.value;

                          return _buildSelectedQuestionCard(
                            index,
                            questionWithAnswer,
                            colorScheme,
                            isDark,
                          );
                        }),

                      SizedBox(height: 16.h),

                      // Add Question Button
                      if (_selectedQuestions.length < 12)
                        OutlinedButton.icon(
                          onPressed: _showAddQuestionDialog,
                          icon: Icon(Icons.add, size: 20.sp),
                          label: Text(
                            'Aggiungi Domanda',
                            style: TextStyle(fontSize: 14.sp),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark
                                ? const Color(0xFF90CAF9)
                                : AppColors.indigo600,
                            side: BorderSide(
                              color: isDark
                                  ? const Color(0xFF90CAF9)
                                  : AppColors.indigo600,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 12.h,
                            ),
                          ),
                        ),

                      SizedBox(height: 32.h),

                      // Error Message
                      if (_errorMessage != null)
                        Container(
                          margin: EdgeInsets.only(bottom: 16.h),
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha:0.1),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: AppColors.error.withValues(alpha:0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline,
                                  color: AppColors.error, size: 20.sp),
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
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Save Button (Fixed at bottom)
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: colorScheme.onSurface.withValues(alpha:0.1),
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: _selectedQuestions.length >= 3 && !_isSaving
                      ? _handleSave
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDark ? const Color(0xFF90CAF9) : AppColors.indigo600,
                    foregroundColor:
                        isDark ? AppColors.backgroundDark : Colors.white,
                    disabledBackgroundColor:
                        colorScheme.onSurface.withValues(alpha:0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
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
                          'Salva Domande (${_selectedQuestions.length})',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedQuestionCard(
    int index,
    QuestionWithAnswer questionWithAnswer,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha:0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with remove button
          Row(
            children: [
              Text(
                'Domanda ${index + 1}',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF90CAF9) : AppColors.indigo600,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.close, size: 20.sp),
                onPressed: () {
                  setState(() {
                    _selectedQuestions.removeAt(index);
                  });
                },
                color: AppColors.error,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),

          SizedBox(height: 8.h),

          // Question text
          Text(
            questionWithAnswer.question.question,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: colorScheme.onBackground,
            ),
          ),

          SizedBox(height: 12.h),

          // Answer field
          TextFormField(
            initialValue: questionWithAnswer.answer,
            decoration: InputDecoration(
              labelText: 'Risposta',
              hintText: 'Inserisci la tua risposta',
              prefixIcon: const Icon(Icons.edit),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            onChanged: (value) {
              questionWithAnswer.answer = value;
            },
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
  }

  void _showAddQuestionDialog() {
    // Filter out already selected questions
    final availableForSelection = _availableQuestions
        .where((q) => !_selectedQuestions.any((s) => s.question.id == q.id))
        .toList();

    if (availableForSelection.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hai già selezionato tutte le domande disponibili'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: colorScheme.surface,
          title: Text(
            'Seleziona una domanda',
            style: TextStyle(fontSize: 18.sp),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: availableForSelection.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final question = availableForSelection[index];
                return ListTile(
                  title: Text(
                    question.question,
                    style: TextStyle(fontSize: 14.sp),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16.sp,
                    color: isDark
                        ? const Color(0xFF90CAF9)
                        : AppColors.indigo600,
                  ),
                  onTap: () {
                    setState(() {
                      _selectedQuestions.add(
                        QuestionWithAnswer(question: question),
                      );
                    });
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annulla'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Compila tutte le risposte prima di salvare'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final answers = _selectedQuestions
          .map((q) => q.toUserAnswer())
          .toList();

      final response = await _repository.setupQuestions(answers);

      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response.message ?? 'Domande salvate con successo!',
              ),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop();
        }
      } else {
        setState(() {
          _errorMessage = response.error ?? 'Errore nel salvare le domande';
          _isSaving = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Errore di connessione. Riprova.';
        _isSaving = false;
      });
    }
  }
}

