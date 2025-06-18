# Piano di Migrazione - Moduli App

## 📋 Overview

Piano per implementare 4 moduli principali seguendo l'architettura esistente dell'app Flutter:
- 🔴 **FEEDBACK** - Raccolta feedback dagli utenti
- 🟣 **PROFILE** - Profilo utente  
- 🟤 **NOTIFICATION** - Notifiche push e di sistema
- ⚪️ **STATS** - Statistiche e monitoraggio

## 🏗️ Architettura Target

Ogni modulo seguirà la struttura standard dell'app:

```
lib/features/{module_name}/
├── models/
│   ├── {module}_models.dart
│   └── {module}_models.g.dart (auto-generato)
├── repository/
│   └── {module}_repository.dart
├── presentation/
│   ├── bloc/ (se necessario)
│   │   ├── {module}_bloc.dart
│   │   ├── {module}_event.dart
│   │   └── {module}_state.dart
│   ├── screens/
│   │   └── {module}_screen.dart
│   └── components/ (se necessario)
│       └── {module}_card.dart
└── viewmodel/ (alternativo a bloc)
    └── {module}_viewmodel.dart
```

## 🔴 MODULO 1: FEEDBACK

### Priority: HIGH
### Estimated Time: 3-4 ore

#### Struttura File:
```
lib/features/feedback/
├── models/
│   ├── feedback_models.dart
│   └── feedback_models.g.dart
├── repository/
│   └── feedback_repository.dart
├── presentation/
│   ├── screens/
│   │   └── feedback_screen.dart
│   └── components/
│       └── feedback_card.dart
└── bloc/
    ├── feedback_bloc.dart
    ├── feedback_event.dart
    └── feedback_state.dart
```

#### Modelli da Creare:
- `Feedback` - Modello principale feedback
- `FeedbackType` - Enum per tipi di feedback
- `FeedbackRequest` - Request per invio feedback
- `FeedbackResponse` - Response API

#### API Endpoints:
- GET `/feedback.php` - Lista feedback
- POST `/feedback.php` - Invio nuovo feedback
- PUT `/feedback.php` - Aggiornamento feedback
- DELETE `/feedback.php` - Eliminazione feedback

#### UI Components:
- `FeedbackScreen` - Schermata principale feedback
- `FeedbackCard` - Card per visualizzare singolo feedback
- `FeedbackForm` - Form per inserire feedback

#### Task List:
- [ ] Creare modelli con json_annotation
- [ ] Implementare repository con ApiClient
- [ ] Creare BLoC per state management
- [ ] Implementare UI con Material 3 + Dark/Light theme
- [ ] Aggiungere al dependency injection
- [ ] Testare integrazione

---

## 🟣 MODULO 2: PROFILE

### Priority: HIGH  
### Estimated Time: 4-5 ore

#### Struttura File:
```
lib/features/profile/
├── models/
│   ├── profile_models.dart
│   └── profile_models.g.dart
├── repository/
│   └── profile_repository.dart
├── presentation/
│   ├── screens/
│   │   └── profile_screen.dart
│   └── components/
│       ├── profile_header.dart
│       ├── profile_info_card.dart
│       └── profile_settings_card.dart
└── bloc/
    ├── profile_bloc.dart
    ├── profile_event.dart
    └── profile_state.dart
```

#### Modelli da Creare:
- `User` - Modello utente base
- `UserProfile` - Profilo dettagliato utente  
- `ProfileUpdateRequest` - Request per aggiornamenti
- `ProfileSettings` - Impostazioni profilo

#### API Endpoints:
- GET `/utente_profilo.php` - Dettagli profilo
- PUT `/utente_profilo.php` - Aggiornamento profilo
- GET `/users.php` - Info utente base
- PUT `/users.php` - Aggiornamento utente

#### UI Components:
- `ProfileScreen` - Schermata profilo principale
- `ProfileHeader` - Header con foto e info base
- `ProfileInfoCard` - Card informazioni personali
- `ProfileSettingsCard` - Card impostazioni

#### Features:
- Visualizzazione profilo completo
- Modifica informazioni personali
- Upload foto profilo
- Gestione impostazioni privacy
- Integrazione con sistema abbonamenti

#### Task List:
- [ ] Creare modelli User e UserProfile
- [ ] Implementare repository per gestione profilo
- [ ] Creare BLoC per state management
- [ ] Implementare UI responsive
- [ ] Aggiungere gestione immagini
- [ ] Integrare con SessionService esistente
- [ ] Testare flusso completo

---

## 🟤 MODULO 3: NOTIFICATION

### Priority: MEDIUM
### Estimated Time: 5-6 ore

#### Struttura File:
```
lib/features/notification/
├── models/
│   ├── notification_models.dart
│   ├── notification_models.g.dart
│   └── notification_enums.dart
├── repository/
│   └── notification_repository.dart
├── services/
│   ├── notification_cleanup_system.dart
│   └── notification_integration_service.dart
├── presentation/
│   ├── screens/
│   │   └── notification_screen.dart
│   └── components/
│       ├── notification_card.dart
│       └── notification_filter.dart
└── bloc/
    ├── notification_bloc.dart
    ├── notification_event.dart
    └── notification_state.dart
```

#### Modelli da Creare:
- `AppNotification` - Modello notifica principale
- `NotificationType` - Enum tipi notifiche
- `NotificationSettings` - Impostazioni notifiche
- `NotificationRequest` - Request per operazioni

#### API Endpoints:
- GET `/notifications.php` - Lista notifiche
- POST `/notifications.php` - Creazione notifica
- PUT `/notifications.php` - Aggiornamento (es. mark as read)
- DELETE `/notifications.php` - Eliminazione notifica

#### Services:
- `NotificationCleanupSystem` - Pulizia notifiche vecchie
- `NotificationIntegrationService` - Integrazione con sistema push

#### UI Components:
- `NotificationScreen` - Lista notifiche
- `NotificationCard` - Card singola notifica
- `NotificationFilter` - Filtri per tipo/stato

#### Features:
- Lista notifiche con filtri
- Notifiche push (Firebase)
- Notifiche locali
- Badge con contatore
- Cleanup automatico

#### Task List:
- [ ] Creare modelli e enums
- [ ] Implementare repository
- [ ] Creare services per cleanup e integrazione
- [ ] Implementare BLoC
- [ ] Creare UI con badge counter
- [ ] Integrare Firebase Push Notifications
- [ ] Implementare notifiche locali
- [ ] Testare sistema completo

---

## ⚪️ MODULO 4: STATS

### Priority: MEDIUM
### Estimated Time: 6-7 ore

#### Struttura File:
```
lib/features/stats/
├── models/
│   ├── stats_models.dart
│   └── stats_models.g.dart
├── repository/
│   └── stats_repository.dart
├── presentation/
│   ├── screens/
│   │   └── stats_screen.dart
│   ├── components/
│   │   ├── stats_chart.dart
│   │   ├── stats_summary_card.dart
│   │   └── stats_filter.dart
│   └── viewmodel/
│       └── stats_viewmodel.dart
└── bloc/
    ├── stats_bloc.dart
    ├── stats_event.dart
    └── stats_state.dart
```

#### Modelli da Creare:
- `Stats` - Modello statistiche principale
- `UserStats` - Statistiche utente (già esiste in user_stats_models.dart)
- `StatsTimeRange` - Enum per periodi temporali
- `StatsRequest` - Request per filtri/parametri

#### API Endpoints:
- GET `/stats.php` - Statistiche generali
- GET `/user_stats.php` - Statistiche utente specifiche
- POST `/stats.php` - Creazione dati statistici

#### UI Components:
- `StatsScreen` - Dashboard statistiche
- `StatsChart` - Grafici con fl_chart o charts_flutter
- `StatsSummaryCard` - Card riassuntive
- `StatsFilter` - Filtri temporali

#### Features:
- Dashboard con KPI principali
- Grafici interattivi
- Filtri temporali (settimana, mese, anno)
- Export dati
- Integrazione con subscription (stats avanzate)

#### Task List:
- [ ] Creare modelli Stats
- [ ] Implementare repository
- [ ] Scegliere libreria per charts (fl_chart)
- [ ] Implementare BLoC/ViewModel
- [ ] Creare dashboard responsive
- [ ] Implementare grafici
- [ ] Aggiungere filtri temporali
- [ ] Integrare con subscription per stats avanzate
- [ ] Testare performance con grandi dataset

---

## 🔧 Configurazione Generale

### Dependency Injection
Aggiungere al `dependency_injection.dart`:

```dart
// Feedback
GetIt.instance.registerLazySingleton<FeedbackRepository>(
  () => FeedbackRepository(apiClient: GetIt.instance.get()),
);

// Profile  
GetIt.instance.registerLazySingleton<ProfileRepository>(
  () => ProfileRepository(apiClient: GetIt.instance.get()),
);

// Notification
GetIt.instance.registerLazySingleton<NotificationRepository>(
  () => NotificationRepository(apiClient: GetIt.instance.get()),
);

// Stats
GetIt.instance.registerLazySingleton<StatsRepository>(
  () => StatsRepository(apiClient: GetIt.instance.get()),
);
```

### Routing
Aggiungere route alle navigate esistenti:
- `/feedback` - FeedbackScreen
- `/profile` - ProfileScreen  
- `/notifications` - NotificationScreen
- `/stats` - StatsScreen

### API Client
Aggiungere metodi al `api_client.dart` per ogni endpoint.

---

## 📅 Timeline Suggerita

### Settimana 1-2:
1. **Giorno 1-2**: FEEDBACK (più semplice, per testare il flusso)
2. **Giorno 3-4**: PROFILE (integrazione con sistemi esistenti)

### Settimana 3-4:
3. **Giorno 5-7**: NOTIFICATION (più complesso, push notifications)
4. **Giorno 8-10**: STATS (grafici e dashboard)

### Settimana 5:
5. **Testing e refinement** di tutti i moduli
6. **Integrazione finale** e ottimizzazioni

---

## 🎯 Priorità di Implementazione

1. **FEEDBACK** ⭐⭐⭐ (Più semplice, buon punto di partenza)
2. **PROFILE** ⭐⭐⭐ (Core functionality)  
3. **NOTIFICATION** ⭐⭐ (Migliora UX ma non critico)
4. **STATS** ⭐⭐ (Nice to have, ma utile per engagement)

---

## 📝 Note

- Seguire sempre l'architettura esistente (Repository + BLoC)
- Usare `Result<T>` per gestione errori
- Rispettare temi Dark/Light esistenti
- Utilizzare `flutter_screenutil` per responsive design
- Integrare con `SessionService` per autenticazione
- Utilizzare `json_annotation` per serializzazione
- Testare sempre su entrambi i temi e diverse dimensioni schermo

---

*Documento creato il 18 Giugno 2025*
*Ready per implementazione step-by-step* ✅