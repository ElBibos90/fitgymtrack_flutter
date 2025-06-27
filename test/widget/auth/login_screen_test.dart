import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('🧪 LoginScreen Widget Tests', () {
    Widget createTestWidget() {
      return ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MaterialApp(
            home: Scaffold(
              appBar: AppBar(title: const Text('Login')),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('FitGym Tracker', style: TextStyle(fontSize: 32)),
                    const SizedBox(height: 16),
                    const Text('Accedi all\'area riservata'),
                    const SizedBox(height: 16),
                    const Text('Username'),
                    const Text('Password'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Accedi'),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Registrati'),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Password dimenticata?'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    testWidgets('Mostra tutti gli elementi chiave della login', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('FitGym Tracker'), findsOneWidget);
      expect(find.text('Accedi all\'area riservata'), findsOneWidget);
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Accedi'), findsOneWidget);
      expect(find.text('Registrati'), findsOneWidget);
      expect(find.text('Password dimenticata?'), findsOneWidget);
    });
  });
} 