import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../core/network/dio_client.dart';

/// Screen per il setup delle domande di sicurezza durante la registrazione
class SecurityQuestionsSetupScreen extends StatefulWidget {
  final String username;
  final String email;
  final String name;

  const SecurityQuestionsSetupScreen({
    super.key,
    required this.username,
    required this.email,
    required this.name,
  });

  @override
  State<SecurityQuestionsSetupScreen> createState() => _SecurityQuestionsSetupScreenState();
}

class _SecurityQuestionsSetupScreenState extends State<SecurityQuestionsSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _answerControllers = [];
  final ScrollController _scrollController = ScrollController();
  
  List<Map<String, dynamic>> _availableQuestions = [];
  List<Map<String, dynamic>> _selectedQuestions = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAvailableQuestions();
  }

  @override
  void dispose() {
    for (var controller in _answerControllers) {
      controller.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableQuestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dio = DioClient.getInstance();
      final response = await dio.get(
        '/password_reset_inapp.php',
        queryParameters: {'action': 'list_questions'},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final questionsData = response.data['questions'] as List;
        setState(() {
          _availableQuestions = questionsData.map((q) => {
            'id': q['id'].toString(),
            'question': q['question'] as String,
          }).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Errore nel caricamento delle domande';
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

  void _toggleQuestion(Map<String, dynamic> question) {
    setState(() {
      if (_selectedQuestions.contains(question)) {
        _selectedQuestions.remove(question);
        // Rimuovi controller se esiste
        final index = _selectedQuestions.length;
        if (index < _answerControllers.length) {
          _answerControllers[index].dispose();
          _answerControllers.removeAt(index);
        }
      } else {
        if (_selectedQuestions.length < 3) {
          _selectedQuestions.add(question);
          _answerControllers.add(TextEditingController());
          
          // Autoscroll alle risposte quando si seleziona la terza domanda
          if (_selectedQuestions.length == 3) {
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted && _scrollController.hasClients) {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent * 0.7, // Scroll al 70% della pagina
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              }
            });
          }
        }
      }
    });
  }

  Future<void> _saveSecurityQuestions() async {
    if (_selectedQuestions.length != 3) {
      setState(() {
        _errorMessage = 'Seleziona esattamente 3 domande';
      });
      return;
    }

    // Verifica che tutte le risposte siano compilate
    for (int i = 0; i < _answerControllers.length; i++) {
      if (_answerControllers[i].text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Compila tutte le risposte';
      });
      return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dio = DioClient.getInstance();
      
      // Prepara le risposte per l'API
      final answers = _selectedQuestions.asMap().entries.map((entry) {
        final index = entry.key;
        final question = entry.value;
        return {
          'question_id': question['id'],
          'answer': _answerControllers[index].text.trim(),
        };
      }).toList();

      final response = await dio.post(
        '/password_reset_inapp.php',
        queryParameters: {'action': 'setup_questions'},
        data: {
          'username': widget.username,
          'answers': answers,
          'role': 'standalone',
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        // Successo! Naviga al login
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.data['message'] ?? 'Domande di sicurezza configurate con successo'),
              backgroundColor: AppColors.success,
            ),
          );
          context.go('/login');
        }
      } else {
        setState(() {
          _errorMessage = response.data['error'] ?? 'Errore nel salvataggio delle domande';
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Domande di Sicurezza',
          style: TextStyle(
            color: isDark ? const Color(0xFF90CAF9) : AppColors.indigo600,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? const Color(0xFF90CAF9) : AppColors.indigo600,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading && _availableQuestions.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.all(16.w),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Configura le Domande di Sicurezza',
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFF90CAF9) : AppColors.indigo600,
                          ),
                          softWrap: true,
                          overflow: TextOverflow.visible,
                          maxLines: 2, // Permette 2 righe per il titolo
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Scegli 3 domande e fornisci le risposte per il reset password',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: colorScheme.onBackground.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 32.h),

                    // Error Message
                    if (_errorMessage != null)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12.w),
                        margin: EdgeInsets.only(bottom: 16.h),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: colorScheme.error),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: colorScheme.onErrorContainer,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),

                    // Available Questions
                    Text(
                      'Domande Disponibili (${_availableQuestions.length})',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onBackground,
                      ),
                    ),

                    SizedBox(height: 16.h),

                    // Questions List
                    ..._availableQuestions.map((question) => _buildQuestionCard(question)),

                    SizedBox(height: 24.h),

                    // Selected Questions
                    if (_selectedQuestions.isNotEmpty) ...[
                      Text(
                        'Domande Selezionate (${_selectedQuestions.length}/3)',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onBackground,
                        ),
                      ),

                      SizedBox(height: 16.h),

                      ..._selectedQuestions.asMap().entries.map((entry) {
                        final index = entry.key;
                        final question = entry.value;
                        return _buildAnswerCard(question, index);
                      }),
                    ],

                    SizedBox(height: 32.h),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 48.h,
                      child: ElevatedButton(
                        onPressed: _selectedQuestions.length == 3 && !_isLoading
                            ? _saveSecurityQuestions
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? const Color(0xFF90CAF9) : AppColors.indigo600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: 20.w,
                                height: 20.w,
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Salva Domande',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),

                    SizedBox(height: 16.h),

                    // Info Text
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: isDark 
                            ? const Color(0xFF1E3A8A).withValues(alpha: 0.1)
                            : AppColors.indigo50,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: isDark 
                              ? const Color(0xFF3B82F6).withValues(alpha: 0.3)
                              : AppColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: isDark ? const Color(0xFF90CAF9) : AppColors.indigo600,
                            size: 20.sp,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              'Le domande di sicurezza sono obbligatorie per il reset password. Scegli domande a cui solo tu sai rispondere.',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: isDark ? const Color(0xFF90CAF9) : AppColors.indigo700,
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
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question) {
    final isSelected = _selectedQuestions.contains(question);
    final canSelect = _selectedQuestions.length < 3 || isSelected;
    
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      child: Card(
        elevation: isSelected ? 4 : 1,
        color: isSelected 
            ? (Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFF1E3A8A).withValues(alpha: 0.2)
                : AppColors.indigo50)
            : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.r),
          side: BorderSide(
            color: isSelected 
                ? (Theme.of(context).brightness == Brightness.dark 
                    ? const Color(0xFF3B82F6)
                    : AppColors.indigo600)
                : Colors.transparent,
            width: isSelected ? 2 : 0,
          ),
        ),
        child: InkWell(
          onTap: canSelect ? () => _toggleQuestion(question) : null,
          borderRadius: BorderRadius.circular(8.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Checkbox(
                  value: isSelected,
                  onChanged: canSelect ? (_) => _toggleQuestion(question) : null,
                  activeColor: Theme.of(context).brightness == Brightness.dark 
                      ? const Color(0xFF3B82F6)
                      : AppColors.indigo600,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    question['question'],
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: canSelect 
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    softWrap: true,
                    overflow: TextOverflow.visible,
                    maxLines: 3, // Limita a 3 righe per evitare problemi di memoria
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerCard(Map<String, dynamic> question, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Domanda ${index + 1}: ${question['question']}',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                softWrap: true,
                overflow: TextOverflow.visible,
                maxLines: 3, // Limita a 3 righe per evitare problemi di memoria
              ),
              SizedBox(height: 12.h),
              CustomTextField(
                controller: _answerControllers[index],
                label: 'Risposta',
                hint: 'Inserisci la tua risposta',
                prefixIcon: Icons.edit,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Inserisci una risposta';
                  }
                  if (value.trim().length < 2) {
                    return 'Risposta troppo corta';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
