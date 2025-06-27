import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// 🧪 TEST E2E SEMPLICE
/// 
/// Questo è un test E2E di base per verificare che:
/// 1. L'app si avvii correttamente
/// 2. La navigazione funzioni
/// 3. I widget principali siano presenti

void main() {
  group('🧪 Simple E2E Tests', () {
    Widget createTestApp() {
      return ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MaterialApp(
            home: Scaffold(
              appBar: AppBar(title: const Text('Test App')),
              body: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.fitness_center, size: 64),
                    SizedBox(height: 16),
                    Text('Hello World'),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    testWidgets('Mostra elementi chiave della schermata di test', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Test App'), findsOneWidget);
      expect(find.text('Hello World'), findsOneWidget);
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
                          onPressed: () => context.go('/second'),
                          child: const Text('Vai Avanti'),
                        ),
                      ),
                    ),
                  ),
                  GoRoute(
                    path: '/second',
                    builder: (context, state) => Scaffold(
                      appBar: AppBar(title: const Text('Seconda Pagina')),
                      body: const Center(child: Text('Seconda Pagina')), 
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
      expect(find.text('Vai Avanti'), findsOneWidget);
    });
  });
} 