// lib/features/templates/presentation/widgets/token_debug_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dio/dio.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../core/services/session_service.dart';

class TokenDebugWidget extends StatefulWidget {
  const TokenDebugWidget({super.key});

  @override
  State<TokenDebugWidget> createState() => _TokenDebugWidgetState();
}

class _TokenDebugWidgetState extends State<TokenDebugWidget> {
  bool _isLoading = false;
  String? _token;
  bool? _isAuthenticated;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardBackgroundDark : AppColors.cardBackgroundLight,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.borderColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.key,
                size: 20.sp,
                color: AppColors.warning,
              ),
              SizedBox(width: 8.w),
              Text(
                'Debug Token',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _isLoading ? null : _checkToken,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 16.h,
                        width: 16.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Check',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          ),
          
          SizedBox(height: 16.h),
          
          if (_error != null) ...[
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: AppColors.error.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error,
                    size: 16.sp,
                    color: AppColors.error,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
          ],
          
          if (_token != null || _isAuthenticated != null) ...[
            _buildTokenInfo(),
          ],
        ],
      ),
    );
  }

  Widget _buildTokenInfo() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status autenticazione
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: _isAuthenticated == true 
                ? AppColors.success.withOpacity(0.1)
                : AppColors.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: _isAuthenticated == true 
                  ? AppColors.success.withOpacity(0.3)
                  : AppColors.error.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _isAuthenticated == true ? Icons.check_circle : Icons.error,
                size: 20.sp,
                color: _isAuthenticated == true ? AppColors.success : AppColors.error,
              ),
              SizedBox(width: 8.w),
              Text(
                _isAuthenticated == true ? 'Token Presente' : 'Token Mancante',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: _isAuthenticated == true ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ),
        ),
        
        SizedBox(height: 12.h),
        
        // Dettagli token
        if (_token != null) ...[
          _buildDetailRow(
            'Token (primi 30 caratteri)',
            _token!.length > 30 ? '${_token!.substring(0, 30)}...' : _token!,
            AppColors.info,
            isDarkMode,
          ),
          _buildDetailRow(
            'Lunghezza Token',
            '${_token!.length} caratteri',
            AppColors.info,
            isDarkMode,
          ),
          _buildDetailRow(
            'Formato',
            _token!.startsWith('eyJ') ? 'JWT Valido' : 'Formato Sconosciuto',
            _token!.startsWith('eyJ') ? AppColors.success : AppColors.warning,
            isDarkMode,
          ),
        ],
        
        SizedBox(height: 12.h),
        
        // Test connessione
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _testConnection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Text(
                  'Test Auth',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _testTemplateRating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Text(
                  'Test Rating',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, Color color, bool isDarkMode) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _checkToken() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final sessionService = getIt<SessionService>();
      
      // Test 1: Verifica token locale
      final token = await sessionService.getAuthToken();
      final isAuthenticated = await sessionService.isAuthenticated();
      
      print('🔍 TokenDebugWidget: Token locale: ${token != null ? 'Presente' : 'Mancante'}');
      print('🔍 TokenDebugWidget: IsAuthenticated: $isAuthenticated');
      
      if (token != null) {
        print('🔍 TokenDebugWidget: Token (primi 30 caratteri): ${token.substring(0, 30)}...');
        print('🔍 TokenDebugWidget: Token length: ${token.length}');
      }

      setState(() {
        _token = token;
        _isAuthenticated = isAuthenticated;
      });
    } catch (e) {
      setState(() {
        _error = 'Errore: $e';
      });
      print('❌ TokenDebugWidget: Errore nel check: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Test connessione con Dio
      final dio = getIt<Dio>();
      print('🔍 TokenDebugWidget: Testando connessione con Dio...');
      
      // Test semplice - chiamata a un endpoint che richiede autenticazione
      final response = await dio.get('/simple_auth_test.php');
      
      print('🔍 TokenDebugWidget: Risposta server: ${response.statusCode}');
      print('🔍 TokenDebugWidget: Dati risposta: ${response.data}');
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final isAuth = data['results']?['is_authenticated'] ?? false;
        
        setState(() {
          _isAuthenticated = isAuth;
        });
        
        print('🔍 TokenDebugWidget: Server conferma autenticazione: $isAuth');
      }
    } catch (e) {
      setState(() {
        _error = 'Errore connessione: $e';
      });
      print('❌ TokenDebugWidget: Errore connessione: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testTemplateRating() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Test template rating con Dio
      final dio = getIt<Dio>();
      print('🔍 TokenDebugWidget: Testando template rating...');
      
      // Test template rating finale
      final response = await dio.get('/test_rating_final.php');
      
      print('🔍 TokenDebugWidget: Risposta template rating: ${response.statusCode}');
      print('🔍 TokenDebugWidget: Dati template rating: ${response.data}');
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final isAuth = data['results']?['is_authenticated'] ?? false;
        
        setState(() {
          _isAuthenticated = isAuth;
        });
        
        print('🔍 TokenDebugWidget: Template rating test: ${data['message']}');
      }
    } catch (e) {
      setState(() {
        _error = 'Errore template rating: $e';
      });
      print('❌ TokenDebugWidget: Errore template rating: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
