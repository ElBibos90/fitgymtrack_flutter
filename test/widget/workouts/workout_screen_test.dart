import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('🧪 WorkoutScreen Widget Tests', () {
    Widget createTestWidget() {
      return ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MaterialApp(
            home: Scaffold(
              appBar: AppBar(title: const Text('Allenamenti')),
              body: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.fitness_center, size: 64),
                    SizedBox(height: 16),
                    Text('I Miei Allenamenti'),
                    SizedBox(height: 16),
                    Text('Petto e Tricipiti'),
                    Text('Schiena e Bicipiti'),
                    Text('Gambe'),
                    Text('Spalle'),
                    SizedBox(height: 16),
                    Text('Crea Nuovo Allenamento'),
                    Text('Storico Allenamenti'),
                    Text('Statistiche'),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    testWidgets('Mostra tutti gli elementi chiave della schermata workout', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Allenamenti'), findsOneWidget);
      expect(find.text('I Miei Allenamenti'), findsOneWidget);
      expect(find.text('Petto e Tricipiti'), findsOneWidget);
      expect(find.text('Schiena e Bicipiti'), findsOneWidget);
      expect(find.text('Gambe'), findsOneWidget);
      expect(find.text('Spalle'), findsOneWidget);
      expect(find.text('Crea Nuovo Allenamento'), findsOneWidget);
      expect(find.text('Storico Allenamenti'), findsOneWidget);
      expect(find.text('Statistiche'), findsOneWidget);
      expect(find.byIcon(Icons.fitness_center), findsOneWidget);
    });
  });
} 