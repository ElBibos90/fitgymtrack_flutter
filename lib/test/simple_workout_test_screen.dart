// lib/test/simple_workout_test_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../features/workouts/presentation/screens/simple_active_workout_screen.dart';
import '../features/workouts/presentation/screens/bloc_active_workout_screen.dart';

class SimpleWorkoutTestScreen extends StatelessWidget {
  const SimpleWorkoutTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Simple Workout'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Test Progressivo Allenamento',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 20.h),

            Text(
              'Progressione dei test API 34 vs API 35\nPer identificare dove emerge il problema',
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 40.h),

            // STEP 4: HTTP Test (esistente)
            _buildTestSection(
              'STEP 4: Test HTTP + Dio',
              'Chiamate HTTP dirette con Dio e JSONPlaceholder',
              Colors.blue,
              Colors.blue[50]!,
              [
                _buildTestButton(context, 'Test Scheda 1 (HTTP)', 1, isHttp: true),
                SizedBox(height: 12.h),
                _buildTestButton(context, 'Test Scheda 2 (HTTP)', 2, isHttp: true),
                SizedBox(height: 12.h),
                _buildTestButton(context, 'Test Scheda 3 (HTTP)', 3, isHttp: true),
              ],
            ),

            SizedBox(height: 32.h),

            // STEP 5: BLoC Test (nuovo)
            _buildTestSection(
              'STEP 5: Test BLoC Pattern (MOCK)',
              'BLoC + Repository MOCK + DI + Modelli reali\nTesta pattern architetturale senza backend',
              Colors.purple,
              Colors.purple[50]!,
              [
                _buildTestButton(context, 'Test BLoC Mock Scheda 1', 1, isBloC: true),
                SizedBox(height: 12.h),
                _buildTestButton(context, 'Test BLoC Mock Scheda 2', 2, isBloC: true),
                SizedBox(height: 12.h),
                _buildTestButton(context, 'Test BLoC Mock Scheda 3', 3, isBloC: true),
              ],
            ),

            SizedBox(height: 40.h),

            // Status info
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                children: [
                  Text(
                    '🔍 STRATEGIA STEP 5 MOCK',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[800],
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '• STEP 4 = setState + HTTP diretto (JSONPlaceholder)\n'
                        '• STEP 5 = BLoC + Repository MOCK + DI\n'
                        '• Mock isola il test del pattern BLoC dal backend\n'
                        '• Se STEP 5 Mock funziona → pattern BLoC OK, problema backend\n'
                        '• Se STEP 5 Mock fallisce → problema pattern architetturale',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.orange[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestSection(
      String title,
      String description,
      Color primaryColor,
      Color backgroundColor,
      List<Widget> children,
      ) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            description,
            style: TextStyle(
              fontSize: 13.sp,
              color: primaryColor.withOpacity(0.8),
            ),
          ),
          SizedBox(height: 16.h),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTestButton(
      BuildContext context,
      String text,
      int schedaId, {
        bool isHttp = false,
        bool isBloC = false,
      }) {
    Color buttonColor;
    String prefix;

    if (isBloC) {
      buttonColor = Colors.purple;
      prefix = '🤖 ';
    } else if (isHttp) {
      buttonColor = Colors.blue;
      prefix = '🌐 ';
    } else {
      buttonColor = Colors.grey;
      prefix = '';
    }

    return ElevatedButton(
      onPressed: () {
        if (isBloC) {
          debugPrint('🤖 [DEBUG] BLoC Mock test button pressed - navigating to BlocActiveWorkoutScreen');
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => BlocActiveWorkoutScreen(schedaId: schedaId),
            ),
          );
        } else {
          debugPrint('🌐 [DEBUG] HTTP test button pressed - navigating to SimpleActiveWorkoutScreen');
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => SimpleActiveWorkoutScreen(schedaId: schedaId),
            ),
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 14.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
      ),
      child: Text(
        '$prefix$text',
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}