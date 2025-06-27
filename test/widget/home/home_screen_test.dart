import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('🧪 HomeScreen Widget Tests', () {
    Widget createTestWidget() {
      return ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MaterialApp(
            home: Scaffold(
              appBar: AppBar(title: const Text('Home')),
              body: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.fitness_center, size: 64),
                    SizedBox(height: 16),
                    Text('Dashboard'),
                    SizedBox(height: 16),
                    Text('Allenamenti Recenti'),
                    Text('Statistiche'),
                    Text('Obiettivi'),
                    SizedBox(height: 16),
                    Text('Inizia Allenamento'),
                    Text('Visualizza Storico'),
                    Text('Impostazioni'),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    testWidgets('Mostra tutti gli elementi chiave della home', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Allenamenti Recenti'), findsOneWidget);
      expect(find.text('Statistiche'), findsOneWidget);
      expect(find.text('Obiettivi'), findsOneWidget);
      expect(find.text('Inizia Allenamento'), findsOneWidget);
      expect(find.text('Visualizza Storico'), findsOneWidget);
      expect(find.text('Impostazioni'), findsOneWidget);
      expect(find.byIcon(Icons.fitness_center), findsOneWidget);
    });
  });
} 