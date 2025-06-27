# 🧪 FitGymTrack Test Suite

Questa directory contiene la suite completa di test per l'app **FitGymTrack**, progettata per garantire la qualità e l'affidabilità del codice attraverso test automatizzati.

## 📋 Indice

- [Architettura dei Test](#architettura-dei-test)
- [Tipi di Test](#tipi-di-test)
- [Esecuzione dei Test](#esecuzione-dei-test)
- [Struttura dei File](#struttura-dei-file)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

## 🏗️ Architettura dei Test

```
test/
├── unit/                    # Test unitari
│   ├── bloc/               # Test dei BLoC
│   ├── repository/         # Test dei repository
│   ├── services/           # Test dei servizi
│   └── utils/              # Test delle utility
├── widget/                 # Test dei widget
│   ├── auth/              # Test schermate auth
│   ├── workouts/          # Test schermate workout
│   ├── payments/          # Test pagamenti
│   └── shared/            # Test widget condivisi
├── integration/           # Test di integrazione
│   ├── auth_flow/         # Flusso completo auth
│   ├── workout_flow/      # Flusso completo workout
│   └── payment_flow/      # Flusso completo pagamenti
└── e2e/                   # Test end-to-end
    ├── user_journey/      # Percorsi utente completi
    └── critical_paths/    # Percorsi critici
```

## 🎯 Tipi di Test

### 1. **Test Unitari** (`test/unit/`)

Testano singole unità di codice in isolamento:

- **BLoC Tests**: Verificano la logica di business e state management
- **Repository Tests**: Testano l'accesso ai dati e le trasformazioni
- **Service Tests**: Verificano i servizi esterni (API, database, etc.)
- **Utility Tests**: Testano funzioni helper e utility

**Esempio:**
```dart
blocTest<AuthBloc, AuthState>(
  '✅ Emette [AuthLoading, AuthSuccess] quando il login ha successo',
  build: () {
    when(mockAuthRepository.login(loginRequest))
        .thenAnswer((_) async => loginResponse);
    return authBloc;
  },
  act: (bloc) => bloc.add(LoginRequested(loginRequest)),
  expect: () => [
    AuthLoading(),
    AuthSuccess(loginResponse),
  ],
);
```

### 2. **Test Widget** (`test/widget/`)

Testano l'interfaccia utente e l'interazione utente:

- **UI Elements**: Verificano la presenza di elementi UI
- **User Interactions**: Testano click, input, navigazione
- **State Management**: Verificano reazioni ai cambi di stato
- **Accessibility**: Testano supporto screen reader e navigazione tastiera

**Esempio:**
```dart
testWidgets('✅ Permette inserimento username e password', (tester) async {
  await tester.pumpWidget(createTestWidget());
  
  await tester.enterText(
    find.byKey(const Key('username_field')), 
    'test_user'
  );
  expect(find.text('test_user'), findsOneWidget);
});
```

### 3. **Test di Integrazione** (`integration_test/`)

Testano l'integrazione tra componenti:

- **Auth Flow**: Registrazione → Login → Logout
- **Workout Flow**: Creazione → Esecuzione → Completamento
- **Payment Flow**: Selezione → Pagamento → Conferma

### 4. **Test End-to-End** (`test/e2e/`)

Testano percorsi utente completi:

- **User Journey**: Percorso completo dall'iscrizione all'uso
- **Critical Paths**: Funzionalità critiche per il business
- **Cross-Feature**: Interazione tra diverse funzionalità

## 🚀 Esecuzione dei Test

### Script Automatici

#### Linux/macOS:
```bash
# Tutti i test
./scripts/run_tests.sh

# Test specifici
./scripts/run_tests.sh unit
./scripts/run_tests.sh widget
./scripts/run_tests.sh e2e
./scripts/run_tests.sh analysis
```

#### Windows:
```cmd
# Tutti i test
scripts\run_tests.bat

# Test specifici
scripts\run_tests.bat unit
scripts\run_tests.bat widget
scripts\run_tests.bat e2e
scripts\run_tests.bat analysis
```

### Comandi Manuali

```bash
# Test unitari
flutter test test/unit/

# Test widget
flutter test test/widget/

# Test integrazione
flutter test integration_test/

# Test E2E
flutter test test/e2e/

# Analisi del codice
flutter analyze

# Generazione mock
dart run build_runner build --delete-conflicting-outputs
```

## 📁 Struttura dei File

### File di Configurazione

- **`test_config.dart`**: Configurazione globale per i test
- **`test_helper.dart`**: Helper e utility per i test
- **`mock_factory.dart`**: Factory per la creazione di mock

### File di Test

#### Test Unitari
```
test/unit/
├── bloc/
│   ├── auth_bloc_test.dart
│   ├── workout_bloc_test.dart
│   └── payment_bloc_test.dart
├── repository/
│   ├── auth_repository_test.dart
│   ├── workout_repository_test.dart
│   └── payment_repository_test.dart
└── services/
    ├── stripe_service_test.dart
    └── session_service_test.dart
```

#### Test Widget
```
test/widget/
├── auth/
│   ├── login_screen_test.dart
│   ├── register_screen_test.dart
│   └── forgot_password_screen_test.dart
├── workouts/
│   ├── workout_plans_screen_test.dart
│   ├── active_workout_screen_test.dart
│   └── workout_exercise_editor_test.dart
└── shared/
    ├── custom_app_bar_test.dart
    └── error_handling_widgets_test.dart
```

#### Test E2E
```
test/e2e/
├── user_journey_test.dart
├── auth_flow_test.dart
├── workout_flow_test.dart
└── payment_flow_test.dart
```

## 📋 Best Practices

### 1. **Naming Convention**

```dart
// ✅ Buono
testWidgets('✅ Mostra loading durante login', (tester) async {
  // test implementation
});

// ❌ Evitare
testWidgets('test login loading', (tester) async {
  // test implementation
});
```

### 2. **Organizzazione dei Test**

```dart
group('🧪 AuthBloc Tests', () {
  group('Login', () {
    test('✅ Success case', () { /* ... */ });
    test('❌ Failure case', () { /* ... */ });
  });
  
  group('Register', () {
    test('✅ Success case', () { /* ... */ });
    test('❌ Failure case', () { /* ... */ });
  });
});
```

### 3. **Setup e Teardown**

```dart
setUp(() {
  mockAuthRepository = MockAuthRepository();
  authBloc = AuthBloc(authRepository: mockAuthRepository);
});

tearDown(() {
  authBloc.close();
});
```

### 4. **Mock e Stub**

```dart
// ✅ Usa mock per dipendenze esterne
when(mockAuthRepository.login(any))
    .thenAnswer((_) async => loginResponse);

// ✅ Usa stub per comportamenti semplici
when(mockAuthRepository.isLoggedIn())
    .thenReturn(true);
```

### 5. **Assertions**

```dart
// ✅ Assertions specifiche
expect(find.text('Login'), findsOneWidget);
expect(find.byType(ElevatedButton), findsOneWidget);
expect(find.byKey(const Key('login_button')), findsOneWidget);

// ❌ Assertions generiche
expect(find.byType(Container), findsWidgets);
```

## 🔧 Troubleshooting

### Problemi Comuni

#### 1. **Test che falliscono intermittentemente**

**Causa**: Timing issues con animazioni o operazioni asincrone
**Soluzione**: Usa `pumpAndSettle()` invece di `pump()`

```dart
// ✅ Buono
await tester.pumpAndSettle();

// ❌ Può causare problemi
await tester.pump();
```

#### 2. **Mock non funzionano**

**Causa**: Mock non generati o import mancanti
**Soluzione**: Rigenera i mock

```bash
dart run build_runner build --delete-conflicting-outputs
```

#### 3. **Test E2E che falliscono**

**Causa**: Dispositivo non connesso o emulatore non avviato
**Soluzione**: Verifica dispositivi disponibili

```bash
flutter devices
```

#### 4. **Timeout nei test**

**Causa**: Operazioni che richiedono troppo tempo
**Soluzione**: Aumenta timeout o ottimizza il test

```dart
// Aumenta timeout per test specifici
testWidgets('Slow test', (tester) async {
  // test implementation
}, timeout: Timeout(Duration(minutes: 5)));
```

### Debug dei Test

#### 1. **Debug Visuale**

```dart
// Mostra widget tree per debug
debugDumpApp();

// Screenshot del test
await tester.pumpAndSettle();
await takeScreenshot(tester, 'test_screenshot');
```

#### 2. **Log dei Test**

```dart
// Abilita log dettagliati
flutter test --verbose

// Log specifici nel test
print('Debug: ${find.text('Login')}');
```

#### 3. **Test Singoli**

```bash
# Esegui un singolo test
flutter test test/unit/bloc/auth_bloc_test.dart

# Esegui un test specifico
flutter test --name "Login success"
```

## 📊 Metriche e Coverage

### Coverage Report

```bash
# Genera report coverage
flutter test --coverage

# Visualizza coverage
genhtml coverage/lcov.info -o coverage/html
```

### Metriche Target

- **Coverage**: > 80% per codice critico
- **Test Unitari**: > 90% per BLoC e Repository
- **Test Widget**: > 70% per schermate principali
- **Test E2E**: > 50% per percorsi critici

## 🔄 CI/CD Integration

### GitHub Actions

```yaml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test
      - run: flutter analyze
```

### Pre-commit Hooks

```bash
#!/bin/bash
# .git/hooks/pre-commit
flutter test test/unit/
flutter test test/widget/
flutter analyze
```

## 📚 Risorse Aggiuntive

- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [bloc_test Package](https://pub.dev/packages/bloc_test)
- [mockito Package](https://pub.dev/packages/mockito)
- [integration_test Package](https://pub.dev/packages/integration_test)

---

**Nota**: Questa suite di test è progettata per essere mantenuta e aggiornata insieme al codice. Assicurati di aggiungere nuovi test per ogni nuova funzionalità implementata. 