import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../core/services/session_service.dart';
import '../../bloc/auth_bloc.dart';

/// Screen per completare la registrazione per utenti con password temporanea
class CompleteRegistrationScreen extends StatefulWidget {
  const CompleteRegistrationScreen({super.key});

  @override
  State<CompleteRegistrationScreen> createState() => _CompleteRegistrationScreenState();
}

class _CompleteRegistrationScreenState extends State<CompleteRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final List<TextEditingController> _answerControllers = [];
  
  List<Map<String, dynamic>> _availableQuestions = [];
  List<Map<String, dynamic>> _selectedQuestions = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  bool _changePassword = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadAvailableQuestions();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted && _scrollController.hasClients) {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent * 0.8, // Scroll all'80% della pagina
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeInOut,
                );
              }
            });
          }
        }
      }
    });
  }

  Future<void> _completeRegistration() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedQuestions.length != 3) {
        setState(() {
          _errorMessage = 'Seleziona esattamente 3 domande di sicurezza';
        });
        return;
      }

      // Verifica che tutte le risposte siano compilate
      for (int i = 0; i < _answerControllers.length; i++) {
        if (_answerControllers[i].text.trim().isEmpty) {
          setState(() {
            _errorMessage = 'Compila tutte le risposte alle domande di sicurezza';
          });
          return;
        }
      }

      setState(() {
        _isSaving = true;
        _errorMessage = null;
      });

      try {
        final dio = DioClient.getInstance();
        
        // 1. Cambia password se richiesto
        if (_changePassword && _passwordController.text.isNotEmpty) {
          await _updatePassword();
        }
        
        // 2. Salva domande di sicurezza
        await _saveSecurityQuestions();
        
        // 3. Successo! Naviga alla home
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Registrazione completata con successo!'),
              backgroundColor: AppColors.success,
            ),
          );
          context.go('/dashboard');
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Errore durante il completamento: ${e.toString()}';
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _updatePassword() async {
    final dio = DioClient.getInstance();
    
    print('[COMPLETE_REG] 🔐 Attempting password change...');
    
    // Debug: controlla se l'utente è autenticato
    final authBloc = context.read<AuthBloc>();
    final currentState = authBloc.state;
    print('[COMPLETE_REG] 🔍 Current auth state: ${currentState.runtimeType}');
    
    if (currentState is AuthLoginSuccess) {
      print('[COMPLETE_REG] ✅ User is authenticated: ${currentState.user.username}');
      print('[COMPLETE_REG] 🔍 User ID: ${currentState.user.id}');
    } else if (currentState is AuthAuthenticated) {
      print('[COMPLETE_REG] ✅ User is authenticated: ${currentState.user.username}');
      print('[COMPLETE_REG] 🔍 User ID: ${currentState.user.id}');
    } else {
      print('[COMPLETE_REG] ❌ User is not authenticated: ${currentState.runtimeType}');
    }
    
    // Debug: controlla se il token è presente nel SessionService
    try {
      final sessionService = getIt<SessionService>();
      final token = await sessionService.getAuthToken();
      print('[COMPLETE_REG] 🔍 SessionService token: $token');
    } catch (e) {
      print('[COMPLETE_REG] ❌ SessionService error: $e');
    }
    
    try {
      // Debug: controlla gli header che verranno inviati
      print('[COMPLETE_REG] 🔍 Making request to change_password API...');
      
      // Debug: controlla gli header del DioClient
      print('[COMPLETE_REG] 🔍 DioClient headers: ${dio.options.headers}');
      
      // Debug: controlla se ci sono interceptor attivi
      print('[COMPLETE_REG] 🔍 DioClient interceptors: ${dio.interceptors.length}');
      
      final response = await dio.post(
        '/password_reset_inapp.php',
        queryParameters: {'action': 'change_password'},
        data: {
          'new_password': _passwordController.text.trim(),
        },
      );

      print('[COMPLETE_REG] 📡 Password change response: ${response.data}');
      print('[COMPLETE_REG] 📡 Status code: ${response.statusCode}');

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw Exception(response.data['error'] ?? 'Errore nel cambio password');
      }
    } catch (e) {
      print('[COMPLETE_REG] ❌ Password change error: $e');
      
      // Debug dettagliato per DioException
      if (e is DioException) {
        print('[COMPLETE_REG] 🔍 DioException type: ${e.type}');
        print('[COMPLETE_REG] 🔍 DioException message: ${e.message}');
        print('[COMPLETE_REG] 🔍 DioException response: ${e.response?.data}');
        print('[COMPLETE_REG] 🔍 DioException status code: ${e.response?.statusCode}');
        
        // Se c'è una risposta, proviamo a vedere il contenuto raw
        if (e.response != null) {
          print('[COMPLETE_REG] 🔍 Raw response data: ${e.response!.data}');
          print('[COMPLETE_REG] 🔍 Response headers: ${e.response!.headers}');
        }
      }
      
      // Se è un errore di parsing JSON, proviamo a vedere la risposta raw
      if (e.toString().contains('FormatException')) {
        print('[COMPLETE_REG] 🔍 This is a JSON parsing error - API might be returning HTML/error instead of JSON');
        print('[COMPLETE_REG] 🔍 This usually means the API has a PHP syntax error or is not updated on the server');
      }
      rethrow;
    }
  }

  Future<void> _saveSecurityQuestions() async {
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

    // Ottieni l'username dall'AuthBloc
    final authBloc = context.read<AuthBloc>();
    final currentState = authBloc.state;
    String? username;
    
    if (currentState is AuthLoginSuccess) {
      username = currentState.user.username;
    } else if (currentState is AuthAuthenticated) {
      username = currentState.user.username;
    }
    
    print('[COMPLETE_REG] 🔍 Username from AuthBloc: $username');

    final response = await dio.post(
      '/password_reset_inapp.php',
      queryParameters: {'action': 'setup_questions'},
      data: {
        'username': username, // Username dell'utente autenticato
        'answers': answers,
        'role': 'user', // Ruolo per utenti legati alla palestra
      },
    );

    if (response.statusCode != 200 || response.data['success'] != true) {
      throw Exception(response.data['error'] ?? 'Errore nel salvataggio delle domande');
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
          'Completa Registrazione',
          style: TextStyle(
            color: isDark ? const Color(0xFF90CAF9) : AppColors.indigo600,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        automaticallyImplyLeading: false, // Rimuove il pulsante back
        actions: [
          // Pulsante "Completa" in alto a destra
          if (_selectedQuestions.length == 3 && !_isSaving)
            TextButton(
              onPressed: _completeRegistration,
              child: Text(
                'Completa',
                style: TextStyle(
                  color: isDark ? const Color(0xFF90CAF9) : AppColors.indigo600,
                  fontWeight: FontWeight.w600,
                  fontSize: 16.sp,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
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
                          'Completa la tua Registrazione',
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFF90CAF9) : AppColors.indigo600,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Configura la tua password e le domande di sicurezza',
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

                    // Password Section
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.lock_outline,
                                  color: isDark ? const Color(0xFF90CAF9) : AppColors.indigo600,
                                  size: 20.sp,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  'Cambio Password (Opzionale)',
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16.h),
                            SwitchListTile(
                              title: Text(
                                'Cambia password',
                                style: TextStyle(fontSize: 16.sp),
                              ),
                              subtitle: Text(
                                'Mantieni la password temporanea o scegline una nuova',
                                style: TextStyle(fontSize: 14.sp),
                              ),
                              value: _changePassword,
                              onChanged: (value) {
                                setState(() {
                                  _changePassword = value;
                                  if (!value) {
                                    _passwordController.clear();
                                    _confirmPasswordController.clear();
                                  }
                                });
                              },
                              activeColor: isDark ? const Color(0xFF3B82F6) : AppColors.indigo600,
                            ),
                            if (_changePassword) ...[
                              SizedBox(height: 16.h),
                              CustomTextField(
                                controller: _passwordController,
                                label: 'Nuova Password',
                                hint: 'Inserisci la nuova password',
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
                              CustomTextField(
                                controller: _confirmPasswordController,
                                label: 'Conferma Password',
                                hint: 'Conferma la nuova password',
                                prefixIcon: Icons.lock_outline,
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
                            ],
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 24.h),

                    // Security Questions Section
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.security,
                                    color: isDark ? const Color(0xFF90CAF9) : AppColors.indigo600,
                                    size: 20.sp,
                                  ),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: Text(
                                      'Domande di Sicurezza (Obbligatorio)',
                                      style: TextStyle(
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onSurface,
                                      ),
                                      softWrap: true,
                                      overflow: TextOverflow.visible,
                                      maxLines: 2, // Permette 2 righe per il titolo
                                    ),
                                  ),
                                ],
                              ),
                            SizedBox(height: 8.h),
                            Text(
                              'Scegli 3 domande e fornisci le risposte per il reset password',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                            SizedBox(height: 16.h),

                            // Available Questions
                            Text(
                              'Domande Disponibili',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            SizedBox(height: 12.h),

                            ..._availableQuestions.map((question) => _buildQuestionCard(question)),

                            SizedBox(height: 16.h),

                            // Selected Questions
                            if (_selectedQuestions.isNotEmpty) ...[
                              Text(
                                'Domande Selezionate (${_selectedQuestions.length}/3)',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              SizedBox(height: 12.h),

                              ..._selectedQuestions.asMap().entries.map((entry) {
                                final index = entry.key;
                                final question = entry.value;
                                return _buildAnswerCard(question, index);
                              }),
                            ],
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 32.h),

                    // Complete Button
                    SizedBox(
                      width: double.infinity,
                      height: 48.h,
                      child: ElevatedButton(
                        onPressed: _selectedQuestions.length == 3 && !_isSaving
                            ? _completeRegistration
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? const Color(0xFF90CAF9) : AppColors.indigo600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        child: _isSaving
                            ? SizedBox(
                                width: 20.w,
                                height: 20.w,
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Completa Registrazione',
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
                              'Le domande di sicurezza sono obbligatorie per il reset password. Puoi cambiare la password temporanea o mantenerla.',
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
