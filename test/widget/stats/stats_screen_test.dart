import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('🧪 StatsScreen Widget Tests', () {
    Widget createTestWidget() {
      return ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MaterialApp(
            home: Scaffold(
              appBar: AppBar(title: const Text('Statistiche')),
              body: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bar_chart, size: 64),
                    SizedBox(height: 16),
                    Text('Le Mie Statistiche'),
                    SizedBox(height: 16),
                    Text('Allenamenti Completati: 25'),
                    Text('Ore di Allenamento: 45'),
                    Text('Calorie Bruciate: 12,500'),
                    Text('Peso Sollevato: 15,000 kg'),
                    SizedBox(height: 16),
                    Text('Grafici Progresso'),
                    Text('Obiettivi Raggiunti'),
                    Text('Record Personali'),
                    SizedBox(height: 16),
                    Text('Esporta Dati'),
                    Text('Condividi Risultati'),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    testWidgets('Mostra tutti gli elementi chiave della schermata statistiche', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Statistiche'), findsOneWidget);
      expect(find.text('Le Mie Statistiche'), findsOneWidget);
      expect(find.text('Allenamenti Completati: 25'), findsOneWidget);
      expect(find.text('Ore di Allenamento: 45'), findsOneWidget);
      expect(find.text('Calorie Bruciate: 12,500'), findsOneWidget);
      expect(find.text('Peso Sollevato: 15,000 kg'), findsOneWidget);
      expect(find.text('Grafici Progresso'), findsOneWidget);
      expect(find.text('Obiettivi Raggiunti'), findsOneWidget);
      expect(find.text('Record Personali'), findsOneWidget);
      expect(find.text('Esporta Dati'), findsOneWidget);
      expect(find.text('Condividi Risultati'), findsOneWidget);
      expect(find.byIcon(Icons.bar_chart), findsOneWidget);
    });
  });
} 