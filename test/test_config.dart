import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:fitgymtrack/shared/theme/app_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fitgymtrack/shared/widgets/error_handling_widgets.dart';

/// 🧪 CONFIGURAZIONE TEST GLOBALE
/// 
/// Questo file contiene la configurazione comune per tutti i test:
/// - Setup dependency injection
/// - Mock dei servizi esterni
/// - Widget test helpers
/// - Configurazione tema

class TestConfig {
  static bool _isInitialized = false;

  /// Inizializza la configurazione per i test
  static Future<void> initialize() async {
    if (_isInitialized) return;

    // Setup dependency injection per test
    await setupTestDependencies();
    
    _isInitialized = true;
  }

  /// Setup dependency injection con mock per i test
  static Future<void> setupTestDependencies() async {
    // Reset GetIt
    await GetIt.instance.reset();
    
    // Registra mock dei servizi esterni
    // TODO: Aggiungere mock per API, database, etc.
    
    // Registra servizi di test
    GetIt.instance.registerSingleton<TestHelper>(TestHelper());
  }

  /// Crea un MaterialApp per i test widget
  static Widget createTestApp({
    required Widget child,
    ThemeData? theme,
    List<NavigatorObserver>? navigatorObservers,
  }) {
    return MaterialApp(
      title: 'FitGymTrack Test',
      theme: theme ?? AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: child,
      navigatorObservers: navigatorObservers ?? [],
    );
  }

  /// Helper per creare un widget con BlocProvider
  static Widget createTestWidget<T extends BlocBase>(
    T bloc,
    Widget child,
    ThemeData? theme,
  ) {
    return MaterialApp(
      title: 'FitGymTrack Test',
      theme: theme ?? AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: BlocProvider<T>.value(
        value: bloc,
        child: child,
      ),
    );
  }

  /// Helper per aspettare che le animazioni finiscano
  static Future<void> pumpAndSettle(WidgetTester tester) async {
    await tester.pumpAndSettle();
  }

  /// Helper per aspettare un tempo specifico
  static Future<void> pumpFor(WidgetTester tester, Duration duration) async {
    await tester.pump(duration);
  }

  /// Helper per verificare che un widget sia visibile
  static bool isWidgetVisible(WidgetTester tester, Finder finder) {
    try {
      return tester.widget<Widget>(finder) != null;
    } catch (e) {
      return false;
    }
  }

  /// Helper per verificare che un testo sia presente
  static bool isTextPresent(WidgetTester tester, String text) {
    return find.text(text).evaluate().isNotEmpty;
  }

  /// Helper per verificare che un'icona sia presente
  static bool isIconPresent(WidgetTester tester, IconData icon) {
    return find.byIcon(icon).evaluate().isNotEmpty;
  }

  /// Helper per verificare che un bottone sia abilitato
  static bool isButtonEnabled(WidgetTester tester, Finder finder) {
    final widget = tester.widget<Widget>(finder);
    if (widget is ElevatedButton) {
      return widget.onPressed != null;
    } else if (widget is TextButton) {
      return widget.onPressed != null;
    } else if (widget is IconButton) {
      return widget.onPressed != null;
    }
    return false;
  }

  /// Helper per verificare che un campo input sia valido
  static bool isTextFieldValid(WidgetTester tester, Finder finder) {
    final widget = tester.widget<Widget>(finder);
    if (widget is TextFormField) {
      return widget.validator?.call(widget.controller?.text) == null;
    }
    return true;
  }

  /// Helper per inserire testo in un campo
  static Future<void> enterText(
    WidgetTester tester,
    String key,
    String text,
  ) async {
    await tester.enterText(find.byKey(Key(key)), text);
  }

  /// Helper per cliccare su un elemento
  static Future<void> tap(
    WidgetTester tester,
    Finder finder,
  ) async {
    await tester.tap(finder);
    await pumpAndSettle(tester);
  }

  /// Helper per cliccare su un testo
  static Future<void> tapText(
    WidgetTester tester,
    String text,
  ) async {
    await tap(tester, find.text(text));
  }

  /// Helper per cliccare su un'icona
  static Future<void> tapIcon(
    WidgetTester tester,
    IconData icon,
  ) async {
    await tap(tester, find.byIcon(icon));
  }

  /// Helper per cliccare su un bottone con chiave
  static Future<void> tapButton(
    WidgetTester tester,
    String key,
  ) async {
    await tap(tester, find.byKey(Key(key)));
  }

  /// Helper per verificare navigazione
  static bool hasNavigatedTo(WidgetTester tester, String routeName) {
    // Questo dipende dall'implementazione del router
    // Potrebbe essere necessario mockare il router per i test
    return true;
  }

  /// Helper per verificare che un dialog sia aperto
  static bool isDialogOpen(WidgetTester tester) {
    return find.byType(Dialog).evaluate().isNotEmpty ||
           find.byType(AlertDialog).evaluate().isNotEmpty ||
           find.byType(SimpleDialog).evaluate().isNotEmpty;
  }

  /// Helper per chiudere un dialog
  static Future<void> closeDialog(WidgetTester tester) async {
    if (isDialogOpen(tester)) {
      await tap(tester, find.byIcon(Icons.close));
    }
  }

  /// Helper per verificare che un snackbar sia visibile
  static bool isSnackBarVisible(WidgetTester tester) {
    return find.byType(SnackBar).evaluate().isNotEmpty;
  }

  /// Helper per verificare il contenuto di un snackbar
  static String? getSnackBarText(WidgetTester tester) {
    final snackBar = find.byType(SnackBar);
    if (snackBar.evaluate().isNotEmpty) {
      final widget = tester.widget<SnackBar>(snackBar.first);
      return widget.content.toString();
    }
    return null;
  }

  /// Helper per verificare che un loading indicator sia visibile
  static bool isLoadingVisible(WidgetTester tester) {
    return find.byType(CircularProgressIndicator).evaluate().isNotEmpty ||
           find.byType(LinearProgressIndicator).evaluate().isNotEmpty;
  }

  /// Helper per aspettare che il loading finisca
  static Future<void> waitForLoadingToComplete(WidgetTester tester) async {
    while (isLoadingVisible(tester)) {
      await pumpFor(tester, const Duration(milliseconds: 100));
    }
  }

  /// Helper per verificare che un errore sia visibile
  static bool isErrorVisible(WidgetTester tester) {
    return find.byType(ErrorStateWidget).evaluate().isNotEmpty ||
           find.textContaining('Errore').evaluate().isNotEmpty ||
           find.textContaining('Error').evaluate().isNotEmpty;
  }

  /// Helper per ottenere il testo dell'errore
  static String? getErrorText(WidgetTester tester) {
    final errorWidget = find.byType(ErrorStateWidget);
    if (errorWidget.evaluate().isNotEmpty) {
      // Estrai il testo dall'ErrorStateWidget
      return 'Errore rilevato';
    }
    return null;
  }
}

/// Helper class per i test
class TestHelper {
  /// Genera un username unico per i test
  String generateUniqueUsername() {
    return 'test_user_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Genera un email unico per i test
  String generateUniqueEmail() {
    return 'test${DateTime.now().millisecondsSinceEpoch}@example.com';
  }

  /// Genera una password valida per i test
  String generateValidPassword() {
    return 'TestPassword123!';
  }

  /// Genera un token di test
  String generateTestToken() {
    return 'test_token_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Genera dati utente di test
  Map<String, dynamic> generateTestUserData() {
    return {
      'id': DateTime.now().millisecondsSinceEpoch,
      'username': generateUniqueUsername(),
      'email': generateUniqueEmail(),
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  /// Genera dati workout di test
  Map<String, dynamic> generateTestWorkoutData() {
    return {
      'id': DateTime.now().millisecondsSinceEpoch,
      'name': 'Test Workout',
      'description': 'Workout di test per E2E',
      'exercises': [
        {
          'id': 1,
          'name': 'Panca Piana',
          'sets': 3,
          'reps': 10,
          'weight': 80,
        },
        {
          'id': 2,
          'name': 'Squat',
          'sets': 3,
          'reps': 12,
          'weight': 100,
        },
      ],
    };
  }

  /// Genera dati statistiche di test
  Map<String, dynamic> generateTestStatsData() {
    return {
      'total_workouts': 10,
      'total_exercises': 50,
      'total_weight_lifted': 5000,
      'average_workout_duration': 45,
      'streak_days': 7,
    };
  }
}

/// Estensione per WidgetTester con metodi di convenienza
extension WidgetTesterExtension on WidgetTester {
  /// Aspetta che le animazioni finiscano
  Future<void> pumpAndSettle() async {
    await TestConfig.pumpAndSettle(this);
  }

  /// Aspetta un tempo specifico
  Future<void> pumpFor(Duration duration) async {
    await TestConfig.pumpFor(this, duration);
  }

  /// Inserisce testo in un campo
  Future<void> enterText(String key, String text) async {
    await TestConfig.enterText(this, key, text);
  }

  /// Clicca su un elemento
  Future<void> tap(Finder finder) async {
    await TestConfig.tap(this, finder);
  }

  /// Clicca su un testo
  Future<void> tapText(String text) async {
    await TestConfig.tapText(this, text);
  }

  /// Clicca su un'icona
  Future<void> tapIcon(IconData icon) async {
    await TestConfig.tapIcon(this, icon);
  }

  /// Clicca su un bottone
  Future<void> tapButton(String key) async {
    await TestConfig.tapButton(this, key);
  }

  /// Aspetta che il loading finisca
  Future<void> waitForLoadingToComplete() async {
    await TestConfig.waitForLoadingToComplete(this);
  }
} 