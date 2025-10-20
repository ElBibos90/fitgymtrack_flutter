// lib/features/templates/presentation/widgets/auth_debug_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dio/dio.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../core/services/session_service.dart';

class AuthDebugWidget extends StatefulWidget {
  const AuthDebugWidget({super.key});

  @override
  State<AuthDebugWidget> createState() => _AuthDebugWidgetState();
}

class _AuthDebugWidgetState extends State<AuthDebugWidget> {
  bool _isLoading = false;
  Map<String, dynamic>? _authStatus;
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
                Icons.bug_report,
                size: 20.sp,
                color: AppColors.warning,
              ),
              SizedBox(width: 8.w),
              Text(
                'Debug Autenticazione',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _isLoading ? null : _testAuth,
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
                        'Test',
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
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
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
          
          if (_authStatus != null) ...[
            _buildAuthStatus(),
          ],
        ],
      ),
    );
  }

  Widget _buildAuthStatus() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final results = _authStatus!['results'] as Map<String, dynamic>;
    final isAuthenticated = results['is_authenticated'] as bool;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status principale
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: isAuthenticated 
                ? AppColors.success.withValues(alpha: 0.1)
                : AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: isAuthenticated 
                  ? AppColors.success.withValues(alpha: 0.3)
                  : AppColors.error.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isAuthenticated ? Icons.check_circle : Icons.error,
                size: 20.sp,
                color: isAuthenticated ? AppColors.success : AppColors.error,
              ),
              SizedBox(width: 8.w),
              Text(
                isAuthenticated ? 'Autenticato' : 'Non Autenticato',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: isAuthenticated ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ),
        ),
        
        SizedBox(height: 12.h),
        
        // Dettagli
        _buildDetailRow(
          'Header Authorization',
          results['auth_header_present'] ? 'Presente' : 'Mancante',
          results['auth_header_present'] ? AppColors.success : AppColors.error,
          isDarkMode,
        ),
        
        _buildDetailRow(
          'Formato Token',
          results['auth_header_format'] ?? 'N/A',
          results['auth_header_format'] == 'CORRETTO' ? AppColors.success : AppColors.error,
          isDarkMode,
        ),
        
        if (results['token_verification'] != 'NO_TOKEN') ...[
          _buildDetailRow(
            'Verifica Token',
            (results['token_verification'] as Map<String, dynamic>)['success'] ? 'Valido' : 'Non Valido',
            (results['token_verification'] as Map<String, dynamic>)['success'] ? AppColors.success : AppColors.error,
            isDarkMode,
          ),
          
          if ((results['token_verification'] as Map<String, dynamic>)['user_id'] != null) ...[
            _buildDetailRow(
              'User ID',
              (results['token_verification'] as Map<String, dynamic>)['user_id'].toString(),
              AppColors.info,
              isDarkMode,
            ),
            _buildDetailRow(
              'Username',
              (results['token_verification'] as Map<String, dynamic>)['username'] ?? 'N/A',
              AppColors.info,
              isDarkMode,
            ),
          ],
        ],
        
        if (results['user_in_database'] != 'NOT_FOUND') ...[
          _buildDetailRow(
            'Utente nel DB',
            'Trovato',
            AppColors.success,
            isDarkMode,
          ),
          _buildDetailRow(
            'Email',
            (results['user_in_database'] as Map<String, dynamic>)['email'] ?? 'N/A',
            AppColors.info,
            isDarkMode,
          ),
          _buildDetailRow(
            'Attivo',
            (results['user_in_database'] as Map<String, dynamic>)['is_active'] == 1 ? 'Sì' : 'No',
            (results['user_in_database'] as Map<String, dynamic>)['is_active'] == 1 ? AppColors.success : AppColors.error,
            isDarkMode,
          ),
        ],
        
        if (results['template_permissions'] != null) ...[
          SizedBox(height: 12.h),
          Text(
            'Permessi Template',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          _buildDetailRow(
            'Template Totali',
            (results['template_permissions'] as Map<String, dynamic>)['total_templates'].toString(),
            AppColors.info,
            isDarkMode,
          ),
          _buildDetailRow(
            'Template Premium',
            (results['template_permissions'] as Map<String, dynamic>)['premium_templates'].toString(),
            AppColors.warning,
            isDarkMode,
          ),
          _buildDetailRow(
            'Utente Premium',
            (results['template_permissions'] as Map<String, dynamic>)['user_premium'] ? 'Sì' : 'No',
            (results['template_permissions'] as Map<String, dynamic>)['user_premium'] ? AppColors.success : AppColors.error,
            isDarkMode,
          ),
        ],
        
        SizedBox(height: 12.h),
        
        // Raccomandazioni
        if (_authStatus!['recommendations'] != null) ...[
          Text(
            'Raccomandazioni',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          ...(_authStatus!['recommendations'] as List<dynamic>).map((rec) => 
            Padding(
              padding: EdgeInsets.only(bottom: 4.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 12.sp,
                    color: AppColors.info,
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      rec.toString(),
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
          Text(
            value,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _testAuth() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _authStatus = null;
    });

    try {
      // Test 1: Verifica token locale
      final sessionService = getIt<SessionService>();
      final token = await sessionService.getAuthToken();
      final isAuthenticated = await sessionService.isAuthenticated();
      
      //debugPrint('🔍 AuthDebugWidget: Token locale presente: ${token != null && token.isNotEmpty}');
      //debugPrint('🔍 AuthDebugWidget: IsAuthenticated: $isAuthenticated');
      
      if (token != null) {
        //debugPrint('🔍 AuthDebugWidget: Token (primi 20 caratteri): ${token.substring(0, 20)}...');
      }

      // Test 2: Verifica con server
      final dio = getIt<Dio>();
      final response = await dio.get('/test_auth_status.php');
      
      if (response.statusCode == 200) {
        setState(() {
          _authStatus = response.data;
        });
      } else {
        setState(() {
          _error = 'Errore server: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Errore: $e';
      });
      //debugPrint('❌ AuthDebugWidget: Errore nel test: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
