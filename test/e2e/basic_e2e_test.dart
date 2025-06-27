import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// 🧪 TEST E2E BASE
/// 
/// Test semplice per verificare il funzionamento base dei test E2E
/// senza dipendenze complesse

void main() {
  group('🧪 Basic E2E Tests', () {
    Widget createTestApp() {
      return ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MaterialApp(
            home: Scaffold(
              appBar: AppBar(title: const Text('FitGymTrack')),
              body: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.fitness_center, size: 64),
                    SizedBox(height: 16),
                    Text('Benvenuto in FitGymTrack'),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    testWidgets('Mostra elementi chiave della schermata principale', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('FitGymTrack'), findsOneWidget);
      expect(find.text('Benvenuto in FitGymTrack'), findsOneWidget);
      expect(find.byIcon(Icons.fitness_center), findsOneWidget);
    });

    testWidgets('Test navigazione semplice', (WidgetTester tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) {
            return MaterialApp.router(
              routerConfig: GoRouter(
                routes: [
                  GoRoute(
                    path: '/',
                    builder: (context, state) => Scaffold(
                      appBar: AppBar(title: const Text('Home')),
                      body: Center(
                        child: ElevatedButton(
                          onPressed: () => context.go('/profile'),
                          child: const Text('Vai al Profilo'),
                        ),
                      ),
                    ),
                  ),
                  GoRoute(
                    path: '/profile',
                    builder: (context, state) => Scaffold(
                      appBar: AppBar(title: const Text('Profilo')),
                      body: const Center(child: Text('Pagina Profilo')),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Vai al Profilo'), findsOneWidget);
    });
  });
} 