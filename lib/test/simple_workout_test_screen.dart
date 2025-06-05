// lib/test/simple_workout_test_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../features/workouts/presentation/screens/simple_active_workout_screen.dart';
import '../features/workouts/presentation/screens/bloc_active_workout_screen.dart';
import 'simple_bloc_mock_test_screen.dart'; // ✅ NUOVO import

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
                _buildTestButton(context, 'Test Scheda 137 (HTTP)', 137, testType: TestType.http),
                SizedBox(height: 12.h),
                _buildTestButton(context, 'Test Scheda Mock 1 (HTTP)', 1, testType: TestType.http),
                SizedBox(height: 12.h),
                _buildTestButton(context, 'Test Scheda Mock 2 (HTTP)', 2, testType: TestType.http),
              ],
            ),

            SizedBox(height: 32.h),

            // ✅ NUOVO: STEP 5A: BLoC Test ISOLATO (FUNZIONANTE)
            _buildTestSection(
              'STEP 5A: Test BLoC ISOLATO 🎯',
              'BLoC + Repository MOCK ISOLATO\nZERO DI, ZERO backend, ZERO complicazioni!',
              Colors.green,
              Colors.green[50]!,
              [
                _buildTestButton(context, 'Test BLoC Isolato Scheda 137', 137, testType: TestType.isolatedMock),
                SizedBox(height: 12.h),
                _buildTestButton(context, 'Test BLoC Isolato Mock 1', 1, testType: TestType.isolatedMock),
                SizedBox(height: 12.h),
                _buildTestButton(context, 'Test BLoC Isolato Mock 2', 2, testType: TestType.isolatedMock),
              ],
            ),

            SizedBox(height: 32.h),

            // STEP 5B: BLoC Test con DI (problematico)
            _buildTestSection(
              'STEP 5B: Test BLoC + DI Mock',
              'BLoC + Repository MOCK + DI + Modelli reali\n⚠️ Complesso - potrebbe ancora chiamare backend',
              Colors.purple,
              Colors.purple[50]!,
              [
                _buildTestButton(context, 'Test BLoC DI Scheda 137 (REALE)', 137, testType: TestType.complexMock),
                SizedBox(height: 12.h),
                _buildTestButton(context, 'Test BLoC DI Mock 1', 1, testType: TestType.complexMock),
                SizedBox(height: 12.h),
                _buildTestButton(context, 'Test BLoC DI Mock 2', 2, testType: TestType.complexMock),
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
                    '🎯 RACCOMANDAZIONE STEP 5A',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[800],
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '✅ STEP 5A = BLoC + Mock ISOLATO (sempre funzionante)\n'
                        '🔧 STEP 5B = BLoC + DI + Backend REALE (ID 137)\n'
                        '🌐 STEP 4 = setState + HTTP diretto (baseline)\n\n'
                        'ID 137 = scheda reale nel database\n'
                        'ID 1,2 = dati mock per test pattern',
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
        required TestType testType,
      }) {
    Color buttonColor;
    String prefix;

    switch (testType) {
      case TestType.isolatedMock:
        buttonColor = Colors.green;
        prefix = '🎯 ';
        break;
      case TestType.complexMock:
        buttonColor = Colors.purple;
        prefix = '🤖 ';
        break;
      case TestType.http:
        buttonColor = Colors.blue;
        prefix = '🌐 ';
        break;
    }

    return ElevatedButton(
      onPressed: () {
        switch (testType) {
          case TestType.isolatedMock:
            debugPrint('🎯 [DEBUG] Isolated Mock test button pressed - navigating to SimpleBlocMockTestScreen');
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => SimpleBlocMockTestScreen(schedaId: schedaId),
              ),
            );
            break;
          case TestType.complexMock:
            debugPrint('🤖 [DEBUG] Complex Mock test button pressed - navigating to BlocActiveWorkoutScreen');
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => BlocActiveWorkoutScreen(schedaId: schedaId),
              ),
            );
            break;
          case TestType.http:
            debugPrint('🌐 [DEBUG] HTTP test button pressed - navigating to SimpleActiveWorkoutScreen');
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => SimpleActiveWorkoutScreen(schedaId: schedaId),
              ),
            );
            break;
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

enum TestType {
  http,
  isolatedMock,
  complexMock,
}