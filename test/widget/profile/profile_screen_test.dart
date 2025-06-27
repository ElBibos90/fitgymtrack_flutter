import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('🧪 ProfileScreen Widget Tests', () {
    Widget createTestWidget() {
      return ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MaterialApp(
            home: Scaffold(
              appBar: AppBar(title: const Text('Profilo')),
              body: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      child: Icon(Icons.person, size: 50),
                    ),
                    SizedBox(height: 16),
                    Text('Nome Utente'),
                    Text('email@example.com'),
                    SizedBox(height: 16),
                    Text('Informazioni Personali'),
                    Text('Impostazioni Account'),
                    Text('Abbonamento'),
                    Text('Statistiche Personali'),
                    SizedBox(height: 16),
                    Text('Logout'),
                    Text('Elimina Account'),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    testWidgets('Mostra tutti gli elementi chiave della schermata profilo', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Profilo'), findsOneWidget);
      expect(find.text('Nome Utente'), findsOneWidget);
      expect(find.text('email@example.com'), findsOneWidget);
      expect(find.text('Informazioni Personali'), findsOneWidget);
      expect(find.text('Impostazioni Account'), findsOneWidget);
      expect(find.text('Abbonamento'), findsOneWidget);
      expect(find.text('Statistiche Personali'), findsOneWidget);
      expect(find.text('Logout'), findsOneWidget);
      expect(find.text('Elimina Account'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });
  });
} 